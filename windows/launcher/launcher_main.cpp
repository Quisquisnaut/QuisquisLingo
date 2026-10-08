#include "launcher_logic.h"

#include <commctrl.h>
#include <shellapi.h>
#include <windows.h>

#include <algorithm>
#include <cstdio>
#include <cstdint>
#include <iterator>
#include <string>
#include <utility>
#include <vector>

namespace {

constexpr wchar_t kDialogTitle[] = L"QuisquisLingo startup check";
constexpr wchar_t kLauncherVersion[] = L"1.0.0";
constexpr wchar_t kWrappedQqlVersion[] = L"2.0.29+2293";
constexpr std::uint64_t kMaximumLogBytes = 128ULL * 1024ULL;

using qql::launcher::ExecutionResult;
using qql::launcher::LaunchOutcome;
using qql::launcher::LauncherHost;
using qql::launcher::PackageState;
using qql::launcher::RuntimeInfo;
using qql::launcher::WarningChoice;

struct DiagnosticState {
  RuntimeInfo runtime;
  std::vector<std::wstring> missing_components;
  bool child_executable_present = false;
  bool media_foundation_available = false;
  ExecutionResult execution;
};

std::wstring WithExtendedPathPrefix(const std::wstring& path) {
  if (path.rfind(L"\\\\?\\", 0) == 0) {
    return path;
  }
  if (path.rfind(L"\\\\", 0) == 0) {
    return L"\\\\?\\UNC\\" + path.substr(2);
  }
  if (path.size() >= 3 && path[1] == L':' &&
      (path[2] == L'\\' || path[2] == L'/')) {
    return L"\\\\?\\" + path;
  }
  return path;
}

std::wstring ExecutablePath() {
  std::vector<wchar_t> buffer(512);
  for (;;) {
    SetLastError(ERROR_SUCCESS);
    const DWORD length = GetModuleFileNameW(
        nullptr, buffer.data(), static_cast<DWORD>(buffer.size()));
    if (length == 0) {
      return {};
    }
    if (length < buffer.size()) {
      return std::wstring(buffer.data(), length);
    }
    if (buffer.size() >= 32768) {
      return {};
    }
    buffer.resize(std::min<std::size_t>(buffer.size() * 2, 32768));
  }
}

std::wstring ParentDirectory(const std::wstring& path) {
  const std::size_t separator = path.find_last_of(L"\\/");
  if (separator == std::wstring::npos) {
    return {};
  }
  return path.substr(0, separator);
}

bool PathExists(const std::wstring& path, bool require_directory) {
  const DWORD attributes =
      GetFileAttributesW(WithExtendedPathPrefix(path).c_str());
  if (attributes == INVALID_FILE_ATTRIBUTES) {
    return false;
  }
  const bool is_directory = (attributes & FILE_ATTRIBUTE_DIRECTORY) != 0;
  return require_directory ? is_directory : !is_directory;
}

std::wstring Utf8ToWide(const char* text) {
  if (text == nullptr || *text == '\0') {
    return {};
  }
  int length = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, text, -1,
                                   nullptr, 0);
  UINT code_page = CP_UTF8;
  DWORD flags = MB_ERR_INVALID_CHARS;
  if (length == 0) {
    code_page = CP_ACP;
    flags = 0;
    length = MultiByteToWideChar(code_page, flags, text, -1, nullptr, 0);
  }
  if (length <= 1) {
    return {};
  }
  std::wstring converted(static_cast<std::size_t>(length), L'\0');
  MultiByteToWideChar(code_page, flags, text, -1, converted.data(), length);
  converted.resize(static_cast<std::size_t>(length - 1));
  return converted;
}

RuntimeInfo DetectRuntime() {
  RuntimeInfo runtime;
  HMODULE ntdll = GetModuleHandleW(L"ntdll.dll");
  if (ntdll == nullptr) {
    return runtime;
  }

  // Wine must be classified before any native-Windows version policy is used.
  using WineGetVersion = const char* (__cdecl*)();
  const auto wine_get_version = reinterpret_cast<WineGetVersion>(
      GetProcAddress(ntdll, "wine_get_version"));
  if (wine_get_version != nullptr) {
    runtime.is_wine = true;
    runtime.wine_version = Utf8ToWide(wine_get_version());
    return runtime;
  }

  using RtlGetVersion = LONG (WINAPI*)(PRTL_OSVERSIONINFOW);
  const auto rtl_get_version = reinterpret_cast<RtlGetVersion>(
      GetProcAddress(ntdll, "RtlGetVersion"));
  if (rtl_get_version == nullptr) {
    return runtime;
  }
  RTL_OSVERSIONINFOW version = {};
  version.dwOSVersionInfoSize = sizeof(version);
  if (rtl_get_version(&version) == 0) {
    runtime.windows_version.available = true;
    runtime.windows_version.major = version.dwMajorVersion;
    runtime.windows_version.minor = version.dwMinorVersion;
    runtime.windows_version.build = version.dwBuildNumber;
  }
  return runtime;
}

std::wstring SystemDirectory() {
  std::vector<wchar_t> buffer(512);
  for (;;) {
    const UINT length =
        GetSystemDirectoryW(buffer.data(), static_cast<UINT>(buffer.size()));
    if (length == 0) {
      return {};
    }
    if (length < buffer.size()) {
      return std::wstring(buffer.data(), length);
    }
    buffer.resize(static_cast<std::size_t>(length) + 1);
  }
}

bool HasMediaFoundation() {
  const std::wstring system_directory = SystemDirectory();
  if (system_directory.empty()) {
    return false;
  }
  const std::wstring mfplat_path =
      qql::launcher::JoinPath(system_directory, L"MFPlat.dll");
  HMODULE module = LoadLibraryExW(
      WithExtendedPathPrefix(mfplat_path).c_str(), nullptr,
      LOAD_WITH_ALTERED_SEARCH_PATH);
  if (module == nullptr) {
    return false;
  }
  FreeLibrary(module);
  return true;
}

std::vector<std::wstring> LauncherArguments() {
  int argument_count = 0;
  LPWSTR* argument_values =
      CommandLineToArgvW(GetCommandLineW(), &argument_count);
  if (argument_values == nullptr) {
    return {};
  }
  std::vector<std::wstring> arguments;
  for (int index = 1; index < argument_count; ++index) {
    arguments.emplace_back(argument_values[index]);
  }
  LocalFree(argument_values);
  return arguments;
}

std::wstring FormatSystemError(DWORD error_code) {
  LPWSTR allocated_message = nullptr;
  const DWORD length = FormatMessageW(
      FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM |
          FORMAT_MESSAGE_IGNORE_INSERTS,
      nullptr, error_code, 0,
      reinterpret_cast<LPWSTR>(&allocated_message), 0, nullptr);
  std::wstring message;
  if (length != 0 && allocated_message != nullptr) {
    message.assign(allocated_message, length);
    LocalFree(allocated_message);
    while (!message.empty() &&
           (message.back() == L'\r' || message.back() == L'\n' ||
            message.back() == L' ' || message.back() == L'\t')) {
      message.pop_back();
    }
  } else {
    message = L"No system description is available.";
  }
  return message;
}

class Win32LauncherHost final : public LauncherHost {
 public:
  explicit Win32LauncherHost(std::wstring child_path)
      : child_path_(std::move(child_path)) {}

  WarningChoice ShowRecoverableWarning(
      const std::wstring& warning_text) override {
    const TASKDIALOG_BUTTON buttons[] = {
        {1001, qql::launcher::kContinueButtonLabel},
        {IDCANCEL, qql::launcher::kCancelButtonLabel},
    };
    TASKDIALOGCONFIG config = {};
    config.cbSize = sizeof(config);
    config.hInstance = GetModuleHandleW(nullptr);
    config.dwFlags = TDF_ALLOW_DIALOG_CANCELLATION | TDF_SIZE_TO_CONTENT;
    config.pszWindowTitle = kDialogTitle;
    config.pszMainIcon = TD_WARNING_ICON;
    config.pszMainInstruction =
        L"QuisquisLingo found recoverable startup problems.";
    config.pszContent = warning_text.c_str();
    config.cButtons = static_cast<UINT>(std::size(buttons));
    config.pButtons = buttons;
    config.nDefaultButton = IDCANCEL;
    int selected_button = IDCANCEL;
    const HRESULT result =
        TaskDialogIndirect(&config, &selected_button, nullptr, nullptr);
    if (FAILED(result) || selected_button != 1001) {
      return WarningChoice::kCancel;
    }
    return WarningChoice::kContinueAnyway;
  }

  void ShowFatalError(const std::wstring& fatal_text) override {
    ShowCloseOnlyDialog(L"QuisquisLingo cannot start", fatal_text,
                        TD_ERROR_ICON);
  }

  LaunchOutcome LaunchChild(const std::wstring& command_line) override {
    std::vector<wchar_t> mutable_command_line(command_line.begin(),
                                               command_line.end());
    mutable_command_line.push_back(L'\0');
    STARTUPINFOW startup_info = {};
    startup_info.cb = sizeof(startup_info);
    PROCESS_INFORMATION process_info = {};
    const BOOL created = CreateProcessW(
        WithExtendedPathPrefix(child_path_).c_str(), mutable_command_line.data(),
        nullptr, nullptr, FALSE, 0, nullptr, nullptr, &startup_info,
        &process_info);
    if (!created) {
      return {false, GetLastError()};
    }
    CloseHandle(process_info.hThread);
    CloseHandle(process_info.hProcess);
    return {true, ERROR_SUCCESS};
  }

  void ShowLaunchFailure(DWORD error_code) override {
    std::wstring content =
        L"QuisquisLingo could not be started.\n\nSystem error: ";
    content.append(FormatSystemError(error_code));
    content.append(L"\nError code: ").append(std::to_wstring(error_code));
    ShowCloseOnlyDialog(L"Child process launch failed", content,
                        TD_ERROR_ICON);
  }

 private:
  static void ShowCloseOnlyDialog(
      const wchar_t* main_instruction,
      const std::wstring& content,
      PCWSTR icon) {
    const TASKDIALOG_BUTTON button = {1002, qql::launcher::kCloseButtonLabel};
    TASKDIALOGCONFIG config = {};
    config.cbSize = sizeof(config);
    config.hInstance = GetModuleHandleW(nullptr);
    config.dwFlags = TDF_ALLOW_DIALOG_CANCELLATION | TDF_SIZE_TO_CONTENT;
    config.pszWindowTitle = kDialogTitle;
    config.pszMainIcon = icon;
    config.pszMainInstruction = main_instruction;
    config.pszContent = content.c_str();
    config.cButtons = 1;
    config.pButtons = &button;
    config.nDefaultButton = 1002;
    int selected_button = 0;
    TaskDialogIndirect(&config, &selected_button, nullptr, nullptr);
  }

  std::wstring child_path_;
};

std::wstring EnvironmentValue(const wchar_t* name) {
  DWORD length = GetEnvironmentVariableW(name, nullptr, 0);
  if (length == 0) {
    return {};
  }
  std::vector<wchar_t> buffer(length);
  length = GetEnvironmentVariableW(name, buffer.data(), length);
  if (length == 0 || length >= buffer.size()) {
    return {};
  }
  return std::wstring(buffer.data(), length);
}

bool EnsureDirectory(const std::wstring& path) {
  if (CreateDirectoryW(WithExtendedPathPrefix(path).c_str(), nullptr)) {
    return true;
  }
  return GetLastError() == ERROR_ALREADY_EXISTS && PathExists(path, true);
}

std::wstring DiagnosticLogPath() {
  const std::wstring local_app_data = EnvironmentValue(L"LOCALAPPDATA");
  if (!local_app_data.empty()) {
    const std::wstring app_directory =
        qql::launcher::JoinPath(local_app_data, L"QuisquisLingo");
    const std::wstring log_directory =
        qql::launcher::JoinPath(app_directory, L"Logs");
    if (EnsureDirectory(app_directory) && EnsureDirectory(log_directory)) {
      return qql::launcher::JoinPath(log_directory,
                                     L"quisquislingo_launcher.log");
    }
  }

  std::wstring temporary_directory = EnvironmentValue(L"TEMP");
  if (temporary_directory.empty()) {
    temporary_directory = EnvironmentValue(L"TMP");
  }
  if (temporary_directory.empty()) {
    return {};
  }
  return qql::launcher::JoinPath(temporary_directory,
                                 L"quisquislingo_launcher.log");
}

std::wstring SanitizeLogValue(std::wstring value) {
  for (wchar_t& character : value) {
    if (character < L' ' || character == L'|' || character == L'=') {
      character = L'_';
    }
  }
  if (value.size() > 96) {
    value.resize(96);
  }
  return value;
}

std::wstring ChoiceName(WarningChoice choice) {
  switch (choice) {
    case WarningChoice::kContinueAnyway:
      return L"continue";
    case WarningChoice::kCancel:
      return L"cancel";
    case WarningChoice::kClose:
      return L"close";
    case WarningChoice::kNone:
      return L"none";
  }
  return L"none";
}

std::wstring JoinMissingComponents(
    const std::vector<std::wstring>& components) {
  if (components.empty()) {
    return L"none";
  }
  std::wstring joined;
  for (const std::wstring& component : components) {
    if (!joined.empty()) {
      joined.push_back(L',');
    }
    joined.append(component);
  }
  return joined;
}

std::string WideToUtf8(const std::wstring& text) {
  if (text.empty()) {
    return {};
  }
  const int length = WideCharToMultiByte(CP_UTF8, 0, text.data(),
                                         static_cast<int>(text.size()), nullptr,
                                         0, nullptr, nullptr);
  if (length <= 0) {
    return {};
  }
  std::string encoded(static_cast<std::size_t>(length), '\0');
  WideCharToMultiByte(CP_UTF8, 0, text.data(), static_cast<int>(text.size()),
                      encoded.data(), length, nullptr, nullptr);
  return encoded;
}

void WriteDiagnostics(const DiagnosticState& diagnostics) {
  const std::wstring log_path = DiagnosticLogPath();
  if (log_path.empty()) {
    return;
  }
  const std::wstring native_log_path = WithExtendedPathPrefix(log_path);
  WIN32_FILE_ATTRIBUTE_DATA file_data = {};
  if (GetFileAttributesExW(native_log_path.c_str(), GetFileExInfoStandard,
                           &file_data)) {
    ULARGE_INTEGER size = {};
    size.HighPart = file_data.nFileSizeHigh;
    size.LowPart = file_data.nFileSizeLow;
    if (size.QuadPart >= kMaximumLogBytes) {
      const std::wstring previous_path = native_log_path + L".previous";
      DeleteFileW(previous_path.c_str());
      MoveFileExW(native_log_path.c_str(), previous_path.c_str(),
                  MOVEFILE_REPLACE_EXISTING);
    }
  }

  SYSTEMTIME timestamp = {};
  GetLocalTime(&timestamp);
  std::wstring version = L"unknown";
  if (diagnostics.runtime.windows_version.available) {
    version = std::to_wstring(diagnostics.runtime.windows_version.major) + L"." +
        std::to_wstring(diagnostics.runtime.windows_version.minor) + L"." +
        std::to_wstring(diagnostics.runtime.windows_version.build);
  }
  wchar_t timestamp_buffer[32] = {};
  swprintf_s(timestamp_buffer, L"%04u-%02u-%02uT%02u:%02u:%02u",
             timestamp.wYear, timestamp.wMonth, timestamp.wDay,
             timestamp.wHour, timestamp.wMinute, timestamp.wSecond);

  std::wstring record(timestamp_buffer);
  record.append(L" | launcher=").append(kLauncherVersion);
  record.append(L" | qql=").append(kWrappedQqlVersion);
  record.append(L" | runtime=")
      .append(diagnostics.runtime.is_wine ? L"wine" : L"windows");
  record.append(L" | windows=").append(version);
  record.append(L" | wine=")
      .append(diagnostics.runtime.wine_version.empty()
                  ? L"unknown"
                  : SanitizeLogValue(diagnostics.runtime.wine_version));
  record.append(L" | arch=x64");
  record.append(L" | child_present=")
      .append(diagnostics.child_executable_present ? L"yes" : L"no");
  record.append(L" | mfplat=")
      .append(diagnostics.media_foundation_available ? L"present" : L"missing");
  record.append(L" | missing=")
      .append(JoinMissingComponents(diagnostics.missing_components));
  record.append(L" | warning=")
      .append(diagnostics.execution.warning_displayed ? L"yes" : L"no");
  record.append(L" | decision=")
      .append(ChoiceName(diagnostics.execution.choice));
  record.append(L" | child_attempted=")
      .append(diagnostics.execution.child_attempted ? L"yes" : L"no");
  record.append(L" | child_created=")
      .append(diagnostics.execution.child_created ? L"yes" : L"no");
  record.append(L" | error=")
      .append(std::to_wstring(diagnostics.execution.launch_error));
  record.append(L"\r\n");

  const std::string encoded = WideToUtf8(record);
  if (encoded.empty()) {
    return;
  }
  HANDLE file = CreateFileW(
      native_log_path.c_str(), FILE_APPEND_DATA,
      FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, nullptr,
      OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (file == INVALID_HANDLE_VALUE) {
    return;
  }
  DWORD written = 0;
  WriteFile(file, encoded.data(), static_cast<DWORD>(encoded.size()), &written,
            nullptr);
  CloseHandle(file);
}

}  // namespace

int WINAPI wWinMain(HINSTANCE, HINSTANCE, PWSTR, int) {
  DiagnosticState diagnostics;

  // This must remain the first compatibility probe.
  diagnostics.runtime = DetectRuntime();

  const std::wstring launcher_path = ExecutablePath();
  const std::wstring package_directory = ParentDirectory(launcher_path);
  const std::wstring child_path = qql::launcher::JoinPath(
      package_directory, qql::launcher::kChildExecutableName);

  PackageState package_state;
  package_state.child_executable_present = PathExists(child_path, false);
  diagnostics.child_executable_present =
      package_state.child_executable_present;
  for (const auto& requirement :
       qql::launcher::RequiredPackageComponents()) {
    const std::wstring component_path = qql::launcher::JoinPath(
        package_directory, requirement.relative_path);
    if (!PathExists(component_path, requirement.is_directory)) {
      package_state.missing_components.emplace_back(
          requirement.relative_path);
    }
  }
  diagnostics.missing_components = package_state.missing_components;

  package_state.media_foundation_available = HasMediaFoundation();
  diagnostics.media_foundation_available =
      package_state.media_foundation_available;

  const qql::launcher::PreflightResult preflight =
      qql::launcher::EvaluatePreflight(diagnostics.runtime, package_state);
  const std::wstring child_command_line =
      qql::launcher::BuildChildCommandLine(child_path, LauncherArguments());
  Win32LauncherHost host(child_path);
  diagnostics.execution =
      qql::launcher::ExecutePlan(preflight, child_command_line, host);
  WriteDiagnostics(diagnostics);

  if (preflight.fatal) {
    return 2;
  }
  if (diagnostics.execution.choice == WarningChoice::kCancel) {
    return 0;
  }
  return diagnostics.execution.child_created ? 0 : 3;
}
