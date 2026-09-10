#include "launcher_logic.h"

#include <algorithm>

namespace qql::launcher {
namespace {

bool ContainsVisualCppRuntime(
    const std::vector<std::wstring>& missing_components) {
  return std::any_of(
      missing_components.begin(), missing_components.end(),
      [](const std::wstring& component) {
        return component == L"msvcp140.dll" ||
               component == L"vcruntime140.dll" ||
               component == L"vcruntime140_1.dll";
      });
}

std::wstring MissingPackageIssue(
    const std::vector<std::wstring>& missing_components) {
  std::wstring issue =
      L"Package files are missing:\n"
      L"The complete QQL Windows distribution is intended to contain the "
      L"application executable and all required native libraries. Missing:\n";
  for (const std::wstring& component : missing_components) {
    issue.append(L"  \u2022 ").append(component).append(L"\n");
  }
  issue.append(
      L"Download the complete QQL Windows package again, fully extract the "
      L"entire archive, and do not manually copy only selected EXEs or DLLs.");
  if (ContainsVisualCppRuntime(missing_components)) {
    issue.append(
        L" The Microsoft Visual C++ Redistributable may be a secondary "
        L"option for Microsoft runtime files, but the complete QQL package "
        L"normally ships them beside the application.");
  }
  return issue;
}

}  // namespace

bool PreflightResult::HasRecoverableIssues() const {
  return !recoverable_issues.empty();
}

std::wstring PreflightResult::ConsolidatedWarning() const {
  std::wstring warning;
  for (std::size_t index = 0; index < recoverable_issues.size(); ++index) {
    if (index != 0) {
      warning.append(L"\n\n");
    }
    warning.append(L"\u2022 ").append(recoverable_issues[index]);
  }
  return warning;
}

const std::vector<PackageComponentRequirement>&
RequiredPackageComponents() {
  static const std::vector<PackageComponentRequirement> components = {
      {L"flutter_windows.dll", false},
      {L"msvcp140.dll", false},
      {L"vcruntime140.dll", false},
      {L"vcruntime140_1.dll", false},
      {L"audioplayers_windows_plugin.dll", false},
      {L"screen_retriever_windows_plugin.dll", false},
      {L"url_launcher_windows_plugin.dll", false},
      {L"window_manager_plugin.dll", false},
      {L"native_assets.json", false},
      {L"data\\icudtl.dat", false},
      {L"data\\app.so", false},
      {L"data\\flutter_assets", true},
  };
  return components;
}

PreflightResult EvaluatePreflight(
    const RuntimeInfo& runtime,
    const PackageState& package_state) {
  PreflightResult result;
  if (!package_state.child_executable_present) {
    result.fatal = true;
    result.fatal_message =
        L"The internal QQL application (quisquislingo_app.exe) is missing. "
        L"The QQL package is incomplete or was extracted incorrectly.\n\n"
        L"Download the complete QQL Windows package again and fully extract "
        L"the entire archive. Do not manually copy only selected EXEs or "
        L"DLLs.";
    return result;
  }

  if (!runtime.is_wine) {
    if (!runtime.windows_version.available) {
      result.recoverable_issues.emplace_back(
          L"Windows compatibility:\nThe launcher could not determine the "
          L"actual Windows version. QQL's Windows package is intended for "
          L"Windows 10 or later, so startup or functionality may fail.");
    } else if (runtime.windows_version.major < 10) {
      result.recoverable_issues.emplace_back(
          L"Windows compatibility:\nQQL's Windows package is intended for "
          L"Windows 10 or later. This earlier Windows version is unsupported "
          L"and startup or functionality may fail.");
    }
  }

  if (!package_state.missing_components.empty()) {
    result.recoverable_issues.push_back(
        MissingPackageIssue(package_state.missing_components));
  }

  if (!package_state.media_foundation_available) {
    if (runtime.is_wine) {
      result.recoverable_issues.emplace_back(
          L"Media Foundation under Wine:\nQQL is running under Wine, where "
          L"support is experimental. This Wine environment does not provide "
          L"the Media Foundation functionality expected by QQL. Audio/media "
          L"functionality or startup may therefore fail. The launcher will "
          L"not install winetricks components, codecs, DLL overrides, Wine "
          L"packages, or workarounds.");
    } else {
      result.recoverable_issues.emplace_back(
          L"Windows Media Foundation:\nThis Windows environment does not "
          L"provide Media Foundation functionality needed by QQL's media and "
          L"audio stack. Windows N editions may require Microsoft Media "
          L"Feature Pack, which is normally available under Windows Optional "
          L"Features. On some versions of Windows N, Media Feature Pack may "
          L"not be available under Optional Features. In that case, download "
          L"the appropriate Media Feature Pack for your version of Windows "
          L"from the Microsoft website. Restart Windows after installing it. "
          L"The launcher will not download, install, elevate, or modify "
          L"Windows.");
    }
  }

  return result;
}

ExecutionResult ExecutePlan(
    const PreflightResult& preflight,
    const std::wstring& child_command_line,
    LauncherHost& host) {
  ExecutionResult result;
  if (preflight.fatal) {
    host.ShowFatalError(preflight.fatal_message);
    result.choice = WarningChoice::kClose;
    return result;
  }

  if (preflight.HasRecoverableIssues()) {
    result.warning_displayed = true;
    result.choice =
        host.ShowRecoverableWarning(preflight.ConsolidatedWarning());
    if (result.choice != WarningChoice::kContinueAnyway) {
      result.choice = WarningChoice::kCancel;
      return result;
    }
  }

  result.child_attempted = true;
  const LaunchOutcome outcome = host.LaunchChild(child_command_line);
  result.child_created = outcome.success;
  result.launch_error = outcome.error_code;
  if (!outcome.success) {
    host.ShowLaunchFailure(outcome.error_code);
    result.choice = WarningChoice::kClose;
  }
  return result;
}

std::wstring QuoteWindowsCommandLineArgument(const std::wstring& argument) {
  const bool needs_quotes = argument.empty() ||
      argument.find_first_of(L" \t\n\v\"") != std::wstring::npos;
  if (!needs_quotes) {
    return argument;
  }

  std::wstring quoted = L"\"";
  std::size_t backslash_count = 0;
  for (const wchar_t character : argument) {
    if (character == L'\\') {
      ++backslash_count;
      continue;
    }
    if (character == L'\"') {
      quoted.append(backslash_count * 2 + 1, L'\\');
      quoted.push_back(L'\"');
      backslash_count = 0;
      continue;
    }
    quoted.append(backslash_count, L'\\');
    backslash_count = 0;
    quoted.push_back(character);
  }
  quoted.append(backslash_count * 2, L'\\');
  quoted.push_back(L'\"');
  return quoted;
}

std::wstring BuildChildCommandLine(
    const std::wstring& child_executable_path,
    const std::vector<std::wstring>& arguments) {
  std::wstring command_line =
      QuoteWindowsCommandLineArgument(child_executable_path);
  for (const std::wstring& argument : arguments) {
    command_line.push_back(L' ');
    command_line.append(QuoteWindowsCommandLineArgument(argument));
  }
  return command_line;
}

std::wstring JoinPath(
    const std::wstring& directory,
    const std::wstring& relative_path) {
  if (directory.empty()) {
    return relative_path;
  }
  if (directory.back() == L'\\' || directory.back() == L'/') {
    return directory + relative_path;
  }
  return directory + L"\\" + relative_path;
}

}  // namespace qql::launcher
