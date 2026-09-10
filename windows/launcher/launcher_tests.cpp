#include "launcher_logic.h"

#include <shellapi.h>
#include <windows.h>

#include <functional>
#include <iostream>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

namespace {

using qql::launcher::LaunchOutcome;
using qql::launcher::LauncherHost;
using qql::launcher::PackageState;
using qql::launcher::PreflightResult;
using qql::launcher::RuntimeInfo;
using qql::launcher::WarningChoice;

void Require(bool condition, const char* message) {
  if (!condition) {
    throw std::runtime_error(message);
  }
}

bool Contains(const std::wstring& text, const std::wstring& expected) {
  return text.find(expected) != std::wstring::npos;
}

RuntimeInfo NativeWindows(std::uint32_t major) {
  RuntimeInfo runtime;
  runtime.windows_version.available = true;
  runtime.windows_version.major = major;
  runtime.windows_version.minor = major >= 10 ? 0 : 1;
  runtime.windows_version.build = major >= 10 ? 22631 : 9600;
  return runtime;
}

RuntimeInfo WineRuntime() {
  RuntimeInfo runtime = NativeWindows(6);
  runtime.is_wine = true;
  runtime.wine_version = L"10.0";
  return runtime;
}

PackageState HealthyPackage() {
  PackageState package;
  package.child_executable_present = true;
  package.media_foundation_available = true;
  return package;
}

class FakeHost final : public LauncherHost {
 public:
  WarningChoice warning_choice = WarningChoice::kContinueAnyway;
  LaunchOutcome launch_outcome = {true, ERROR_SUCCESS};
  int warning_count = 0;
  int fatal_count = 0;
  int launch_count = 0;
  int launch_failure_count = 0;
  std::wstring warning_text;
  std::wstring fatal_text;
  std::wstring command_line;
  DWORD shown_error = ERROR_SUCCESS;

  WarningChoice ShowRecoverableWarning(
      const std::wstring& text) override {
    ++warning_count;
    warning_text = text;
    return warning_choice;
  }

  void ShowFatalError(const std::wstring& text) override {
    ++fatal_count;
    fatal_text = text;
  }

  LaunchOutcome LaunchChild(const std::wstring& command) override {
    ++launch_count;
    command_line = command;
    return launch_outcome;
  }

  void ShowLaunchFailure(DWORD error_code) override {
    ++launch_failure_count;
    shown_error = error_code;
  }
};

std::vector<std::wstring> ParseCommandLine(const std::wstring& command_line) {
  int count = 0;
  LPWSTR* values = CommandLineToArgvW(command_line.c_str(), &count);
  Require(values != nullptr, "CommandLineToArgvW failed");
  std::vector<std::wstring> parsed;
  for (int index = 0; index < count; ++index) {
    parsed.emplace_back(values[index]);
  }
  LocalFree(values);
  return parsed;
}

void TestHealthyWindows() {
  for (const std::uint32_t major : {10U, 11U}) {
    const PreflightResult result = qql::launcher::EvaluatePreflight(
        NativeWindows(major), HealthyPackage());
    Require(!result.fatal, "healthy Windows was fatal");
    Require(!result.HasRecoverableIssues(), "healthy Windows warned");
  }
}

void TestOldNativeWindows() {
  const PreflightResult result = qql::launcher::EvaluatePreflight(
      NativeWindows(6), HealthyPackage());
  Require(result.HasRecoverableIssues(), "old Windows did not warn");
  Require(Contains(result.ConsolidatedWarning(), L"Windows 10 or later"),
          "old Windows guidance missing");
}

void TestWineDetected() {
  const RuntimeInfo runtime = WineRuntime();
  Require(runtime.is_wine, "Wine fixture was not classified as Wine");
  Require(runtime.wine_version == L"10.0", "Wine version was not retained");
}

void TestWineBypassesWindowsWarning() {
  const PreflightResult result = qql::launcher::EvaluatePreflight(
      WineRuntime(), HealthyPackage());
  Require(!result.HasRecoverableIssues(),
          "Wine received native old-Windows warning");
}

void TestMissingMediaFoundationOnWindows() {
  PackageState package = HealthyPackage();
  package.media_foundation_available = false;
  const std::wstring warning = qql::launcher::EvaluatePreflight(
      NativeWindows(10), package).ConsolidatedWarning();
  Require(Contains(warning, L"Media Feature Pack"),
          "Windows Media Feature Pack guidance missing");
  Require(Contains(warning, L"Optional Features"),
          "Windows Optional Features guidance missing");
  Require(!Contains(warning, L"winetricks"),
          "Windows warning used Wine wording");
}

void TestMissingMediaFoundationUnderWine() {
  PackageState package = HealthyPackage();
  package.media_foundation_available = false;
  const std::wstring warning = qql::launcher::EvaluatePreflight(
      WineRuntime(), package).ConsolidatedWarning();
  Require(Contains(warning, L"support is experimental"),
          "Wine experimental status missing");
  Require(Contains(warning, L"winetricks"),
          "Wine-specific remediation warning missing");
  Require(!Contains(warning, L"Optional Features"),
          "Wine warning used Windows Optional Features wording");
}

void TestMissingComponent(const wchar_t* component) {
  PackageState package = HealthyPackage();
  package.missing_components.emplace_back(component);
  const std::wstring warning = qql::launcher::EvaluatePreflight(
      NativeWindows(10), package).ConsolidatedWarning();
  Require(Contains(warning, component), "missing component not named");
  Require(Contains(warning, L"fully extract the entire archive"),
          "re-extraction guidance missing");
}

void TestMultipleProblemsUseOneWarning() {
  PackageState package = HealthyPackage();
  package.media_foundation_available = false;
  package.missing_components = {L"msvcp140.dll", L"flutter_windows.dll"};
  const PreflightResult preflight = qql::launcher::EvaluatePreflight(
      NativeWindows(6), package);
  Require(preflight.recoverable_issues.size() == 3,
          "recoverable problem categories were not collected");
  FakeHost host;
  host.warning_choice = WarningChoice::kCancel;
  const auto result =
      qql::launcher::ExecutePlan(preflight, L"child", host);
  Require(host.warning_count == 1, "warning cascade was produced");
  Require(result.warning_displayed, "warning was not recorded");
}

void TestMissingChildIsFatal() {
  PackageState package = HealthyPackage();
  package.child_executable_present = false;
  package.missing_components = {L"msvcp140.dll"};
  const PreflightResult result = qql::launcher::EvaluatePreflight(
      NativeWindows(6), package);
  Require(result.fatal, "missing child was not fatal");
  Require(result.recoverable_issues.empty(),
          "fatal child case retained recoverable warnings");
  Require(Contains(result.fatal_message, L"complete QQL Windows package"),
          "fatal guidance missing");
}

void TestFatalUsesCloseOnly() {
  PackageState package = HealthyPackage();
  package.child_executable_present = false;
  FakeHost host;
  const auto result = qql::launcher::ExecutePlan(
      qql::launcher::EvaluatePreflight(NativeWindows(10), package),
      L"child", host);
  Require(std::wstring(qql::launcher::kCloseButtonLabel) == L"Close",
          "fatal button label changed");
  Require(host.fatal_count == 1, "fatal dialog not shown once");
  Require(host.warning_count == 0, "fatal case showed warning dialog");
  Require(host.launch_count == 0 && !result.child_attempted,
          "fatal case attempted child launch");
}

void TestRecoverableButtonLabels() {
  Require(std::wstring(qql::launcher::kContinueButtonLabel) ==
              L"Continue anyway",
          "continue label changed");
  Require(std::wstring(qql::launcher::kCancelButtonLabel) == L"Cancel",
          "cancel label changed");
}

void TestContinueAttemptsChild() {
  PackageState package = HealthyPackage();
  package.missing_components = {L"msvcp140.dll"};
  FakeHost host;
  host.warning_choice = WarningChoice::kContinueAnyway;
  const auto result = qql::launcher::ExecutePlan(
      qql::launcher::EvaluatePreflight(NativeWindows(10), package),
      L"quoted child command", host);
  Require(result.child_attempted && host.launch_count == 1,
          "Continue anyway did not attempt launch");
  Require(host.command_line == L"quoted child command",
          "child command line changed in execution plan");
}

void TestCancelDoesNotLaunch() {
  PackageState package = HealthyPackage();
  package.missing_components = {L"vcruntime140.dll"};
  FakeHost host;
  host.warning_choice = WarningChoice::kCancel;
  const auto result = qql::launcher::ExecutePlan(
      qql::launcher::EvaluatePreflight(NativeWindows(10), package),
      L"child", host);
  Require(!result.child_attempted && host.launch_count == 0,
          "Cancel attempted child launch");
}

void TestUnicodePackagePath() {
  const std::wstring directory = L"C:\\Utenti\\Jos\u00e9\\\u65e5\u672c\u8a9e package";
  const std::wstring path = qql::launcher::JoinPath(
      directory, qql::launcher::kChildExecutableName);
  Require(path == directory + L"\\quisquislingo_app.exe",
          "Unicode package path was altered");
}

void TestArgumentsContainingSpaces() {
  const std::vector<std::wstring> arguments = {
      L"plain", L"two words", L"C:\\Path With Spaces\\file.txt"};
  const auto parsed = ParseCommandLine(qql::launcher::BuildChildCommandLine(
      L"C:\\QQL Package\\quisquislingo_app.exe", arguments));
  Require(parsed.size() == arguments.size() + 1,
          "space arguments changed count");
  Require(std::vector<std::wstring>(parsed.begin() + 1, parsed.end()) ==
              arguments,
          "space arguments changed semantics");
}

void TestUnicodeArguments() {
  const std::vector<std::wstring> arguments = {
      L"caf\u00e9", L"\u65e5\u672c\u8a9e", L"C:\\\u041f\u0430\u043f\u043a\u0430\\\u0444\u0430\u0439\u043b.txt"};
  const auto parsed = ParseCommandLine(qql::launcher::BuildChildCommandLine(
      L"C:\\QQL\\quisquislingo_app.exe", arguments));
  Require(std::vector<std::wstring>(parsed.begin() + 1, parsed.end()) ==
              arguments,
          "Unicode arguments changed semantics");
}

void TestWindowsArgumentQuoting() {
  const std::vector<std::wstring> arguments = {
      L"", L"quoted \"value\"", L"ends-with-slash\\",
      L"slashes-before-quote\\\\\"tail", L"tabs\tinside"};
  const auto parsed = ParseCommandLine(qql::launcher::BuildChildCommandLine(
      L"C:\\QQL \u00dc\\quisquislingo_app.exe", arguments));
  Require(parsed.front() == L"C:\\QQL \u00dc\\quisquislingo_app.exe",
          "quoted executable path changed");
  Require(std::vector<std::wstring>(parsed.begin() + 1, parsed.end()) ==
              arguments,
          "quote-sensitive arguments changed semantics");
}

void TestChildLaunchFailure() {
  FakeHost host;
  host.launch_outcome = {false, ERROR_BAD_EXE_FORMAT};
  const auto result = qql::launcher::ExecutePlan(
      qql::launcher::EvaluatePreflight(NativeWindows(10), HealthyPackage()),
      L"child", host);
  Require(result.child_attempted && !result.child_created,
          "launch failure result incorrect");
  Require(result.launch_error == ERROR_BAD_EXE_FORMAT,
          "native launch error was not retained");
  Require(host.launch_failure_count == 1 &&
              host.shown_error == ERROR_BAD_EXE_FORMAT,
          "launch failure dialog not requested");
}

void TestChildCreationSuccess() {
  FakeHost host;
  const auto result = qql::launcher::ExecutePlan(
      qql::launcher::EvaluatePreflight(NativeWindows(10), HealthyPackage()),
      L"child", host);
  Require(result.child_attempted && result.child_created,
          "successful process creation not recorded");
  Require(host.launch_failure_count == 0,
          "successful launch displayed failure");
}

}  // namespace

int wmain() {
  const std::vector<std::pair<const char*, std::function<void()>>> tests = {
      {"healthy Windows 10/11", TestHealthyWindows},
      {"native Windows below 10", TestOldNativeWindows},
      {"Wine detected", TestWineDetected},
      {"Wine bypasses native version warning", TestWineBypassesWindowsWarning},
      {"missing MFPlat.dll on Windows", TestMissingMediaFoundationOnWindows},
      {"missing Media Foundation under Wine", TestMissingMediaFoundationUnderWine},
      {"missing msvcp140.dll", [] { TestMissingComponent(L"msvcp140.dll"); }},
      {"missing vcruntime140.dll", [] { TestMissingComponent(L"vcruntime140.dll"); }},
      {"missing vcruntime140_1.dll", [] { TestMissingComponent(L"vcruntime140_1.dll"); }},
      {"missing flutter_windows.dll", [] { TestMissingComponent(L"flutter_windows.dll"); }},
      {"missing mandatory plugin", [] { TestMissingComponent(L"audioplayers_windows_plugin.dll"); }},
      {"consolidated recoverable warning", TestMultipleProblemsUseOneWarning},
      {"missing internal app is fatal", TestMissingChildIsFatal},
      {"fatal case uses Close only", TestFatalUsesCloseOnly},
      {"recoverable button labels", TestRecoverableButtonLabels},
      {"Continue anyway launches", TestContinueAttemptsChild},
      {"Cancel does not launch", TestCancelDoesNotLaunch},
      {"Unicode package path", TestUnicodePackagePath},
      {"arguments containing spaces", TestArgumentsContainingSpaces},
      {"Unicode arguments", TestUnicodeArguments},
      {"Windows argument quoting", TestWindowsArgumentQuoting},
      {"child launch failure", TestChildLaunchFailure},
      {"successful child creation", TestChildCreationSuccess},
  };

  std::size_t passed = 0;
  for (const auto& test : tests) {
    try {
      test.second();
      ++passed;
      std::cout << "PASS: " << test.first << '\n';
    } catch (const std::exception& error) {
      std::cerr << "FAIL: " << test.first << ": " << error.what() << '\n';
      return 1;
    }
  }
  std::cout << "All " << passed << " launcher unit tests passed.\n";
  return 0;
}
