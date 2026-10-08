#include "launcher_logic.h"

#include <windows.h>

#include <chrono>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <iterator>
#include <stdexcept>
#include <string>
#include <thread>
#include <utility>
#include <vector>

namespace {

namespace fs = std::filesystem;

void Require(bool condition, const char* message) {
  if (!condition) {
    throw std::runtime_error(message);
  }
}

bool Contains(const std::wstring& text, const std::wstring& expected) {
  return text.find(expected) != std::wstring::npos;
}

struct ScopedDirectory {
  explicit ScopedDirectory(fs::path directory) : path(std::move(directory)) {}
  ~ScopedDirectory() {
    std::error_code error;
    fs::remove_all(path, error);
  }
  fs::path path;
};

struct ScopedEnvironmentValue {
  ScopedEnvironmentValue(const wchar_t* variable_name,
                         const std::wstring& value)
      : name(variable_name) {
    const DWORD required = GetEnvironmentVariableW(name.c_str(), nullptr, 0);
    if (required > 0) {
      had_previous_value = true;
      std::vector<wchar_t> buffer(required);
      const DWORD copied =
          GetEnvironmentVariableW(name.c_str(), buffer.data(), required);
      if (copied < required) {
        previous_value.assign(buffer.data(), copied);
      }
    }
    Require(SetEnvironmentVariableW(name.c_str(), value.c_str()) != FALSE,
            "failed to set test environment value");
  }

  ~ScopedEnvironmentValue() {
    SetEnvironmentVariableW(name.c_str(),
                            had_previous_value ? previous_value.c_str()
                                               : nullptr);
  }

  std::wstring name;
  std::wstring previous_value;
  bool had_previous_value = false;
};

struct ProcessHandle {
  HANDLE process = nullptr;
  DWORD process_id = 0;

  ProcessHandle() = default;
  ProcessHandle(const ProcessHandle&) = delete;
  ProcessHandle& operator=(const ProcessHandle&) = delete;
  ProcessHandle(ProcessHandle&& other) noexcept
      : process(other.process), process_id(other.process_id) {
    other.process = nullptr;
    other.process_id = 0;
  }
  ProcessHandle& operator=(ProcessHandle&& other) noexcept {
    if (this != &other) {
      if (process != nullptr) {
        CloseHandle(process);
      }
      process = other.process;
      process_id = other.process_id;
      other.process = nullptr;
      other.process_id = 0;
    }
    return *this;
  }
  ~ProcessHandle() {
    if (process != nullptr) {
      if (WaitForSingleObject(process, 0) == WAIT_TIMEOUT) {
        TerminateProcess(process, 98);
        WaitForSingleObject(process, 2000);
      }
      CloseHandle(process);
    }
  }
};

void CreateEmptyFile(const fs::path& path) {
  fs::create_directories(path.parent_path());
  std::ofstream file(path, std::ios::binary | std::ios::trunc);
  Require(file.good(), "failed to create package placeholder");
}

bool IsMissing(const std::vector<std::wstring>& missing,
               const wchar_t* relative_path) {
  for (const std::wstring& entry : missing) {
    if (entry == relative_path) {
      return true;
    }
  }
  return false;
}

void PreparePackage(const fs::path& directory,
                    const fs::path& launcher_source,
                    const fs::path* child_source,
                    const std::vector<std::wstring>& missing = {}) {
  fs::create_directories(directory);
  fs::copy_file(launcher_source, directory / L"QuisquisLingo.exe",
                fs::copy_options::overwrite_existing);
  if (child_source != nullptr) {
    fs::copy_file(*child_source,
                  directory / qql::launcher::kChildExecutableName,
                  fs::copy_options::overwrite_existing);
  }
  for (const auto& component :
       qql::launcher::RequiredPackageComponents()) {
    if (IsMissing(missing, component.relative_path)) {
      continue;
    }
    const fs::path component_path = directory / component.relative_path;
    if (component.is_directory) {
      fs::create_directories(component_path);
    } else {
      CreateEmptyFile(component_path);
    }
  }
}

ProcessHandle StartLauncher(const fs::path& launcher_path,
                            const std::vector<std::wstring>& arguments,
                            const fs::path& working_directory) {
  std::wstring command_line = qql::launcher::BuildChildCommandLine(
      launcher_path.wstring(), arguments);
  std::vector<wchar_t> mutable_command(command_line.begin(), command_line.end());
  mutable_command.push_back(L'\0');
  STARTUPINFOW startup = {};
  startup.cb = sizeof(startup);
  PROCESS_INFORMATION process = {};
  const BOOL created = CreateProcessW(
      launcher_path.c_str(), mutable_command.data(), nullptr, nullptr, FALSE, 0,
      nullptr, working_directory.c_str(), &startup, &process);
  Require(created != FALSE, "failed to start packaged launcher under test");
  CloseHandle(process.hThread);
  ProcessHandle handle;
  handle.process = process.hProcess;
  handle.process_id = process.dwProcessId;
  return handle;
}

struct WindowSearch {
  DWORD process_id = 0;
  std::vector<HWND> windows;
};

BOOL CALLBACK CollectProcessWindows(HWND window, LPARAM parameter) {
  auto* search = reinterpret_cast<WindowSearch*>(parameter);
  DWORD process_id = 0;
  GetWindowThreadProcessId(window, &process_id);
  if (process_id == search->process_id && IsWindowVisible(window)) {
    search->windows.push_back(window);
  }
  return TRUE;
}

std::vector<HWND> VisibleProcessWindows(DWORD process_id) {
  WindowSearch search;
  search.process_id = process_id;
  EnumWindows(CollectProcessWindows, reinterpret_cast<LPARAM>(&search));
  return search.windows;
}

HWND WaitForOneDialog(const ProcessHandle& process) {
  const auto deadline =
      std::chrono::steady_clock::now() + std::chrono::seconds(8);
  while (std::chrono::steady_clock::now() < deadline) {
    const std::vector<HWND> windows =
        VisibleProcessWindows(process.process_id);
    if (!windows.empty()) {
      Require(windows.size() == 1,
              "launcher displayed more than one top-level warning window");
      return windows.front();
    }
    if (WaitForSingleObject(process.process, 0) == WAIT_OBJECT_0) {
      throw std::runtime_error("launcher exited before showing expected dialog");
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(50));
  }
  throw std::runtime_error("timed out waiting for launcher dialog");
}

std::wstring WindowText(HWND window) {
  const int length = GetWindowTextLengthW(window);
  if (length <= 0) {
    return {};
  }
  std::wstring text(static_cast<std::size_t>(length + 1), L'\0');
  const int copied =
      GetWindowTextW(window, text.data(), static_cast<int>(text.size()));
  text.resize(copied > 0 ? static_cast<std::size_t>(copied) : 0);
  return text;
}

struct ChildWindows {
  std::vector<HWND> values;
};

BOOL CALLBACK CollectChildWindows(HWND window, LPARAM parameter) {
  auto* children = reinterpret_cast<ChildWindows*>(parameter);
  children->values.push_back(window);
  return TRUE;
}

std::vector<HWND> Descendants(HWND window) {
  ChildWindows children;
  EnumChildWindows(window, CollectChildWindows,
                   reinterpret_cast<LPARAM>(&children));
  return children.values;
}

std::vector<std::wstring> ButtonLabels(HWND dialog) {
  std::vector<std::wstring> labels;
  for (HWND child : Descendants(dialog)) {
    wchar_t class_name[64] = {};
    if (GetClassNameW(child, class_name, static_cast<int>(std::size(class_name))) >
            0 &&
        std::wstring(class_name) == L"Button") {
      labels.push_back(WindowText(child));
    }
  }
  return labels;
}

bool HasButton(const std::vector<std::wstring>& buttons,
               const wchar_t* label) {
  for (const std::wstring& button : buttons) {
    if (button == label) {
      return true;
    }
  }
  return false;
}

void ClickButton(HWND dialog, const wchar_t* label) {
  for (HWND child : Descendants(dialog)) {
    wchar_t class_name[64] = {};
    if (GetClassNameW(child, class_name, static_cast<int>(std::size(class_name))) >
            0 &&
        std::wstring(class_name) == L"Button" &&
        WindowText(child) == label) {
      SendMessageW(child, BM_CLICK, 0, 0);
      return;
    }
  }
  throw std::runtime_error("expected dialog button was not found");
}

DWORD WaitForExit(const ProcessHandle& process) {
  const DWORD wait = WaitForSingleObject(process.process, 8000);
  if (wait != WAIT_OBJECT_0) {
    TerminateProcess(process.process, 99);
    WaitForSingleObject(process.process, 2000);
    throw std::runtime_error("launcher did not exit after dialog action");
  }
  DWORD exit_code = 0;
  Require(GetExitCodeProcess(process.process, &exit_code) != FALSE,
          "failed to read launcher exit code");
  return exit_code;
}

std::wstring ReadWideFile(const fs::path& path) {
  std::ifstream file(path, std::ios::binary);
  Require(file.good(), "probe output file was not created");
  const std::vector<char> bytes((std::istreambuf_iterator<char>(file)),
                                std::istreambuf_iterator<char>());
  Require(bytes.size() % sizeof(wchar_t) == 0,
          "probe output had invalid UTF-16 size");
  return std::wstring(
      reinterpret_cast<const wchar_t*>(bytes.data()),
      bytes.size() / sizeof(wchar_t));
}

void WaitForFile(const fs::path& path) {
  const auto deadline =
      std::chrono::steady_clock::now() + std::chrono::seconds(8);
  while (std::chrono::steady_clock::now() < deadline) {
    if (fs::is_regular_file(path)) {
      return;
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(50));
  }
  throw std::runtime_error("timed out waiting for child probe output");
}

void TestMissingVcStillStartsAndCancel(
    const fs::path& root,
    const fs::path& launcher,
    const fs::path& probe) {
  const fs::path package = root / L"missing VC";
  PreparePackage(package, launcher, &probe, {L"msvcp140.dll"});
  const fs::path output = package / L"cancel-output.txt";
  ScopedEnvironmentValue output_environment(
      L"QQL_BOOTSTRAP_PROBE_OUTPUT", output.wstring());
  ProcessHandle process = StartLauncher(
      package / L"QuisquisLingo.exe", {}, root);
  const HWND dialog = WaitForOneDialog(process);
  const auto buttons = ButtonLabels(dialog);
  Require(WindowText(dialog) == L"QuisquisLingo startup check",
          "recoverable dialog title changed");
  Require(HasButton(buttons, qql::launcher::kContinueButtonLabel),
          "recoverable dialog lacked Continue anyway");
  Require(HasButton(buttons, qql::launcher::kCancelButtonLabel),
          "recoverable dialog lacked Cancel");
  Require(!HasButton(buttons, qql::launcher::kCloseButtonLabel),
          "recoverable dialog unexpectedly exposed Close");
  ClickButton(dialog, qql::launcher::kCancelButtonLabel);
  Require(WaitForExit(process) == 0, "Cancel did not exit normally");
  Require(!fs::exists(output), "Cancel started the child process");
}

void TestContinueForwardsArgumentsAndEnvironment(
    const fs::path& root,
    const fs::path& launcher,
    const fs::path& probe) {
  const fs::path package = root / L"Unicode \u65e5\u672c\u8a9e package";
  const fs::path caller_directory = root / L"different caller cwd";
  fs::create_directories(caller_directory);
  PreparePackage(package, launcher, &probe, {L"vcruntime140_1.dll"});
  const fs::path output = root / L"probe output.txt";
  ScopedEnvironmentValue output_environment(
      L"QQL_BOOTSTRAP_PROBE_OUTPUT", output.wstring());
  ScopedEnvironmentValue sentinel_environment(
      L"QQL_BOOTSTRAP_PROBE_SENTINEL", L"preserved-\u03a9");
  const std::vector<std::wstring> arguments = {
      L"plain", L"two words", L"caf\u00e9", L"quoted \"value\"",
      L"C:\\Path With Spaces\\\u65e5\u672c\u8a9e.txt"};

  ProcessHandle process = StartLauncher(
      package / L"QuisquisLingo.exe", arguments, caller_directory);
  const HWND dialog = WaitForOneDialog(process);
  Require(HasButton(ButtonLabels(dialog),
                    qql::launcher::kContinueButtonLabel),
          "Continue test did not produce a recoverable warning");
  ClickButton(dialog, qql::launcher::kContinueButtonLabel);
  Require(WaitForExit(process) == 0,
          "launcher did not exit after successful child creation");
  WaitForFile(output);
  const std::wstring probe_output = ReadWideFile(output);
  Require(Contains(probe_output,
                   L"cwd=" + caller_directory.wstring() + L"\n"),
          "child working directory was not inherited");
  Require(Contains(probe_output, L"sentinel=preserved-\u03a9\n"),
          "child environment was not inherited");
  Require(Contains(probe_output, L"argc=5\n"),
          "child argument count changed");
  for (const std::wstring& argument : arguments) {
    Require(Contains(probe_output, L"arg=" + argument + L"\n"),
            "child argument semantics changed");
  }
}

void TestMissingChildIsCloseOnly(const fs::path& root,
                                 const fs::path& launcher) {
  const fs::path package = root / L"missing child";
  PreparePackage(package, launcher, nullptr);
  ProcessHandle process = StartLauncher(
      package / L"QuisquisLingo.exe", {}, root);
  const HWND dialog = WaitForOneDialog(process);
  const auto buttons = ButtonLabels(dialog);
  Require(WindowText(dialog) == L"QuisquisLingo startup check",
          "fatal dialog title changed");
  Require(HasButton(buttons, qql::launcher::kCloseButtonLabel),
          "fatal dialog lacked Close");
  Require(!HasButton(buttons, qql::launcher::kContinueButtonLabel),
          "fatal dialog exposed Continue anyway");
  Require(!HasButton(buttons, qql::launcher::kCancelButtonLabel),
          "fatal dialog exposed Cancel");
  ClickButton(dialog, qql::launcher::kCloseButtonLabel);
  Require(WaitForExit(process) == 2,
          "fatal missing-child exit code was unexpected");
}

void TestChildLaunchFailureIsCloseOnly(const fs::path& root,
                                       const fs::path& launcher) {
  const fs::path package = root / L"invalid child";
  PreparePackage(package, launcher, nullptr);
  CreateEmptyFile(package / qql::launcher::kChildExecutableName);
  ProcessHandle process = StartLauncher(
      package / L"QuisquisLingo.exe", {}, root);
  HWND dialog = WaitForOneDialog(process);
  auto buttons = ButtonLabels(dialog);
  if (HasButton(buttons, qql::launcher::kContinueButtonLabel)) {
    ClickButton(dialog, qql::launcher::kContinueButtonLabel);
    dialog = WaitForOneDialog(process);
    buttons = ButtonLabels(dialog);
  }
  Require(WindowText(dialog) == L"QuisquisLingo startup check",
          "child launch failure dialog title changed");
  Require(HasButton(buttons, qql::launcher::kCloseButtonLabel),
          "child launch failure lacked Close");
  Require(!HasButton(buttons, qql::launcher::kContinueButtonLabel),
          "child launch failure exposed Continue anyway");
  ClickButton(dialog, qql::launcher::kCloseButtonLabel);
  Require(WaitForExit(process) == 3,
          "child launch failure exit code was unexpected");
}

}  // namespace

int wmain(int argument_count, wchar_t** argument_values) {
  if (argument_count != 3) {
    std::wcerr << L"Usage: qql_bootstrap_package_tests.exe "
                  L"<QuisquisLingo.exe> <child-probe.exe>\n";
    return 2;
  }

  try {
    const fs::path launcher = fs::absolute(argument_values[1]);
    const fs::path probe = fs::absolute(argument_values[2]);
    Require(fs::is_regular_file(launcher), "launcher under test is missing");
    Require(fs::is_regular_file(probe), "child probe is missing");

    wchar_t temporary_path[MAX_PATH] = {};
    const DWORD temporary_length =
        GetTempPathW(static_cast<DWORD>(std::size(temporary_path)),
                     temporary_path);
    Require(temporary_length > 0 && temporary_length < std::size(temporary_path),
            "temporary directory is unavailable");
    const fs::path root = fs::path(temporary_path) /
        (L"QQL launcher integration " + std::to_wstring(GetCurrentProcessId()));
    ScopedDirectory cleanup(root);
    fs::create_directories(root);

    TestMissingVcStillStartsAndCancel(root, launcher, probe);
    std::wcout << L"PASS: missing VC DLL still starts; Cancel is no-launch\n";
    TestContinueForwardsArgumentsAndEnvironment(root, launcher, probe);
    std::wcout << L"PASS: Continue launches with Unicode args, cwd, and environment\n";
    TestMissingChildIsCloseOnly(root, launcher);
    std::wcout << L"PASS: missing internal app is fatal and Close-only\n";
    TestChildLaunchFailureIsCloseOnly(root, launcher);
    std::wcout << L"PASS: child process failure is handled and Close-only\n";
    std::wcout << L"All 4 packaged-launcher integration tests passed.\n";
    return 0;
  } catch (const std::exception& error) {
    std::cerr << "FAIL: " << error.what() << '\n';
    return 1;
  }
}
