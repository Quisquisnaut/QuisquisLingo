#ifndef QQL_WINDOWS_LAUNCHER_LAUNCHER_LOGIC_H_
#define QQL_WINDOWS_LAUNCHER_LAUNCHER_LOGIC_H_

#include <windows.h>

#include <cstdint>
#include <string>
#include <vector>

namespace qql::launcher {

inline constexpr wchar_t kChildExecutableName[] = L"quisquislingo_app.exe";
inline constexpr wchar_t kContinueButtonLabel[] = L"Continue anyway";
inline constexpr wchar_t kCancelButtonLabel[] = L"Cancel";
inline constexpr wchar_t kCloseButtonLabel[] = L"Close";

struct WindowsVersion {
  bool available = false;
  std::uint32_t major = 0;
  std::uint32_t minor = 0;
  std::uint32_t build = 0;
};

struct RuntimeInfo {
  bool is_wine = false;
  std::wstring wine_version;
  WindowsVersion windows_version;
};

struct PackageComponentRequirement {
  const wchar_t* relative_path;
  bool is_directory;
};

struct PackageState {
  bool child_executable_present = false;
  std::vector<std::wstring> missing_components;
  bool media_foundation_available = false;
};

struct PreflightResult {
  bool fatal = false;
  std::wstring fatal_message;
  std::vector<std::wstring> recoverable_issues;

  [[nodiscard]] bool HasRecoverableIssues() const;
  [[nodiscard]] std::wstring ConsolidatedWarning() const;
};

enum class WarningChoice {
  kNone,
  kContinueAnyway,
  kCancel,
  kClose,
};

struct LaunchOutcome {
  bool success = false;
  DWORD error_code = ERROR_SUCCESS;
};

struct ExecutionResult {
  bool warning_displayed = false;
  WarningChoice choice = WarningChoice::kNone;
  bool child_attempted = false;
  bool child_created = false;
  DWORD launch_error = ERROR_SUCCESS;
};

class LauncherHost {
 public:
  virtual ~LauncherHost() = default;
  virtual WarningChoice ShowRecoverableWarning(
      const std::wstring& warning_text) = 0;
  virtual void ShowFatalError(const std::wstring& fatal_text) = 0;
  virtual LaunchOutcome LaunchChild(const std::wstring& command_line) = 0;
  virtual void ShowLaunchFailure(DWORD error_code) = 0;
};

[[nodiscard]] const std::vector<PackageComponentRequirement>&
RequiredPackageComponents();

[[nodiscard]] PreflightResult EvaluatePreflight(
    const RuntimeInfo& runtime,
    const PackageState& package_state);

[[nodiscard]] ExecutionResult ExecutePlan(
    const PreflightResult& preflight,
    const std::wstring& child_command_line,
    LauncherHost& host);

[[nodiscard]] std::wstring QuoteWindowsCommandLineArgument(
    const std::wstring& argument);

[[nodiscard]] std::wstring BuildChildCommandLine(
    const std::wstring& child_executable_path,
    const std::vector<std::wstring>& arguments);

[[nodiscard]] std::wstring JoinPath(
    const std::wstring& directory,
    const std::wstring& relative_path);

}  // namespace qql::launcher

#endif  // QQL_WINDOWS_LAUNCHER_LAUNCHER_LOGIC_H_
