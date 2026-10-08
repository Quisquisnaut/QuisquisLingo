#ifndef RUNNER_STARTUP_DIAGNOSTICS_H_
#define RUNNER_STARTUP_DIAGNOSTICS_H_

#include <windows.h>

#include <cstdio>
#include <string>

#ifndef FLUTTER_VERSION
#define FLUTTER_VERSION "unknown"
#endif

#ifndef FLUTTER_VERSION_BUILD
#define FLUTTER_VERSION_BUILD unknown
#endif

#define QUISQUISLINGO_STRINGIFY_INNER(value) #value
#define QUISQUISLINGO_STRINGIFY(value) QUISQUISLINGO_STRINGIFY_INNER(value)

namespace startup_diagnostics {

enum class Level { kNormal, kVerbose };

namespace detail {

constexpr ULONGLONG kMaximumLogBytes = 1024ULL * 1024ULL;
constexpr int kRotatedLogCount = 2;

struct Destination {
  std::wstring path;
};

struct SessionState {
  Destination destination;
  Level level = Level::kNormal;
  std::string session_id;
};

inline std::wstring EnvironmentValue(const wchar_t* name) {
  const DWORD length = GetEnvironmentVariableW(name, nullptr, 0);
  if (length == 0) {
    return L"";
  }
  std::wstring value(length, L'\0');
  const DWORD written = GetEnvironmentVariableW(name, value.data(), length);
  if (written == 0 || written >= length) {
    return L"";
  }
  value.resize(written);
  return value;
}

inline bool EnsureDirectory(const std::wstring& path) {
  if (CreateDirectoryW(path.c_str(), nullptr)) {
    return true;
  }
  if (GetLastError() != ERROR_ALREADY_EXISTS) {
    return false;
  }
  const DWORD attributes = GetFileAttributesW(path.c_str());
  return attributes != INVALID_FILE_ATTRIBUTES &&
         (attributes & FILE_ATTRIBUTE_DIRECTORY) != 0;
}

inline bool CanAppend(const std::wstring& path) {
  HANDLE file = CreateFileW(
      path.c_str(), FILE_APPEND_DATA,
      FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, nullptr,
      OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (file == INVALID_HANDLE_VALUE) {
    return false;
  }
  CloseHandle(file);
  return true;
}

inline std::wstring FallbackPath() {
  std::wstring root = EnvironmentValue(L"TEMP");
  if (root.empty()) {
    wchar_t buffer[MAX_PATH] = {};
    const DWORD length = GetTempPathW(MAX_PATH, buffer);
    if (length == 0 || length >= MAX_PATH) {
      return L"";
    }
    root.assign(buffer, length);
  }
  while (!root.empty() && (root.back() == L'\\' || root.back() == L'/')) {
    root.pop_back();
  }
  return root + L"\\quisquislingo_startup_trace.log";
}

inline Destination ResolveDestination() {
  Destination destination;
  try {
    const std::wstring local_app_data = EnvironmentValue(L"LOCALAPPDATA");
    if (!local_app_data.empty()) {
      const std::wstring app_directory = local_app_data + L"\\QuisquisLingo";
      const std::wstring log_directory = app_directory + L"\\Logs";
      const std::wstring primary_path =
          log_directory + L"\\quisquislingo_startup_trace.log";
      if (EnsureDirectory(app_directory) && EnsureDirectory(log_directory) &&
          CanAppend(primary_path)) {
        destination.path = primary_path;
        return destination;
      }
    }

    const std::wstring fallback_path = FallbackPath();
    if (!fallback_path.empty() && CanAppend(fallback_path)) {
      destination.path = fallback_path;
    }
  } catch (...) {
    // Startup diagnostics must never affect application startup.
  }
  return destination;
}

inline std::string Timestamp() {
  SYSTEMTIME utc = {};
  GetSystemTime(&utc);
  char buffer[32] = {};
  std::snprintf(buffer, sizeof(buffer),
                "%04u-%02u-%02uT%02u:%02u:%02u.%03uZ",
                static_cast<unsigned>(utc.wYear),
                static_cast<unsigned>(utc.wMonth),
                static_cast<unsigned>(utc.wDay),
                static_cast<unsigned>(utc.wHour),
                static_cast<unsigned>(utc.wMinute),
                static_cast<unsigned>(utc.wSecond),
                static_cast<unsigned>(utc.wMilliseconds));
  return buffer;
}

inline std::string SessionId() {
  GUID guid = {};
  if (SUCCEEDED(CoCreateGuid(&guid))) {
    char buffer[40] = {};
    std::snprintf(
        buffer, sizeof(buffer),
        "%08lx-%04x-%04x-%02x%02x-%02x%02x%02x%02x%02x%02x",
        static_cast<unsigned long>(guid.Data1),
        static_cast<unsigned>(guid.Data2),
        static_cast<unsigned>(guid.Data3),
        static_cast<unsigned>(guid.Data4[0]),
        static_cast<unsigned>(guid.Data4[1]),
        static_cast<unsigned>(guid.Data4[2]),
        static_cast<unsigned>(guid.Data4[3]),
        static_cast<unsigned>(guid.Data4[4]),
        static_cast<unsigned>(guid.Data4[5]),
        static_cast<unsigned>(guid.Data4[6]),
        static_cast<unsigned>(guid.Data4[7]));
    return buffer;
  }
  return Timestamp() + "-" + std::to_string(GetCurrentProcessId()) + "-" +
         std::to_string(GetTickCount64());
}

inline std::string BuildMode() {
#if defined(_DEBUG)
  return "debug";
#else
  return "release";
#endif
}

inline std::string Architecture() {
#if defined(_M_X64)
  return "x64";
#elif defined(_M_ARM64)
  return "arm64";
#elif defined(_M_IX86)
  return "x86";
#else
  return "unknown";
#endif
}

inline std::string AppVersion() {
  return std::string(FLUTTER_VERSION) + "+" +
         QUISQUISLINGO_STRINGIFY(FLUTTER_VERSION_BUILD);
}

inline Level ConfiguredLevel() {
  std::wstring configured =
      EnvironmentValue(L"QUISQUISLINGO_STARTUP_DIAGNOSTICS");
  for (wchar_t& character : configured) {
    if (character >= L'A' && character <= L'Z') {
      character = character - L'A' + L'a';
    }
  }
  return configured == L"verbose" ? Level::kVerbose : Level::kNormal;
}

inline bool Append(const std::wstring& path, const std::string& text) {
  if (path.empty()) {
    return false;
  }
  HANDLE file = CreateFileW(
      path.c_str(), FILE_APPEND_DATA,
      FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, nullptr,
      OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (file == INVALID_HANDLE_VALUE) {
    return false;
  }

  DWORD written = 0;
  const BOOL write_ok =
      WriteFile(file, text.data(), static_cast<DWORD>(text.size()), &written,
                nullptr);
  const BOOL flush_ok = write_ok ? FlushFileBuffers(file) : FALSE;
  CloseHandle(file);
  return write_ok && flush_ok && written == text.size();
}

inline bool AppendWithFallback(Destination* destination,
                               const std::string& text) {
  if (Append(destination->path, text)) {
    return true;
  }
  const std::wstring fallback = FallbackPath();
  if (fallback.empty() || fallback == destination->path ||
      !Append(fallback, text)) {
    return false;
  }
  destination->path = fallback;
  return true;
}

inline void RotateIfNeeded(const std::wstring& path) {
  if (path.empty()) {
    return;
  }
  HANDLE file = CreateFileW(path.c_str(), GENERIC_READ,
                            FILE_SHARE_READ | FILE_SHARE_WRITE |
                                FILE_SHARE_DELETE,
                            nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL,
                            nullptr);
  if (file == INVALID_HANDLE_VALUE) {
    return;
  }
  LARGE_INTEGER size = {};
  const bool should_rotate =
      GetFileSizeEx(file, &size) &&
      static_cast<ULONGLONG>(size.QuadPart) >= kMaximumLogBytes;
  CloseHandle(file);
  if (!should_rotate) {
    return;
  }

  const std::wstring oldest =
      path + L"." + std::to_wstring(kRotatedLogCount);
  DeleteFileW(oldest.c_str());
  for (int index = kRotatedLogCount - 1; index >= 1; --index) {
    const std::wstring source = path + L"." + std::to_wstring(index);
    const std::wstring target = path + L"." + std::to_wstring(index + 1);
    MoveFileExW(source.c_str(), target.c_str(),
                MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH);
  }
  MoveFileExW(path.c_str(), (path + L".1").c_str(),
              MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH);
}

inline std::string SanitizeContext(const std::string& value) {
  if (value.find(":\\") != std::string::npos ||
      value.find(":/") != std::string::npos ||
      value.rfind("\\\\", 0) == 0) {
    return "details_redacted";
  }
  std::string result;
  result.reserve(value.size() < 512 ? value.size() : 512);
  for (const unsigned char character : value) {
    if (result.size() >= 512) {
      break;
    }
    if (character < 0x20 || character == 0x7f) {
      result.push_back(' ');
    } else if (character == '\\' || character == '"') {
      result.push_back('\\');
      result.push_back(static_cast<char>(character));
    } else {
      result.push_back(static_cast<char>(character));
    }
  }
  return result;
}

inline SessionState CreateSessionState() {
  SessionState state;
  try {
    state.destination = ResolveDestination();
    state.level = ConfiguredLevel();
    state.session_id = SessionId();
    RotateIfNeeded(state.destination.path);

    const std::string version = AppVersion();
    const std::string build_mode = BuildMode();
    SetEnvironmentVariableA("QUISQUISLINGO_STARTUP_SESSION_ID",
                            state.session_id.c_str());
    SetEnvironmentVariableA("QUISQUISLINGO_STARTUP_APP_VERSION",
                            version.c_str());
    SetEnvironmentVariableA("QUISQUISLINGO_STARTUP_ALPHA", "true");
    SetEnvironmentVariableA("QUISQUISLINGO_STARTUP_BUILD_MODE",
                            build_mode.c_str());

    const std::string header =
        "=== QUISQUISLINGO_STARTUP_SESSION schema=1 session=" +
        state.session_id + " start_utc=" + Timestamp() + " version=" +
        version + " alpha=true build_mode=" + build_mode +
        " platform=windows arch=" + Architecture() + " level=" +
        (state.level == Level::kVerbose ? "verbose" : "normal") +
        " ===\r\n";
    const bool header_written = AppendWithFallback(&state.destination, header);
    SetEnvironmentVariableA("QUISQUISLINGO_STARTUP_HEADER_WRITTEN",
                            header_written ? "1" : "0");
  } catch (...) {
    // Startup diagnostics must never affect application startup.
  }
  return state;
}

inline SessionState& GetSessionState() {
  static SessionState state = CreateSessionState();
  return state;
}

inline void WriteCheckpoint(const char* checkpoint,
                            const std::string& context, Level required_level) {
  SessionState& state = GetSessionState();
  if (required_level == Level::kVerbose && state.level != Level::kVerbose) {
    return;
  }
  std::string line = Timestamp() + " checkpoint=" + checkpoint +
                     " session=" + state.session_id +
                     " pid=" + std::to_string(GetCurrentProcessId()) +
                     " tid=" + std::to_string(GetCurrentThreadId());
  if (!context.empty()) {
    line += " context=\"" + SanitizeContext(context) + "\"";
  }
  line += "\r\n";
  AppendWithFallback(&state.destination, line);
}

}  // namespace detail

inline bool PathExists(const wchar_t* path) noexcept {
  return GetFileAttributesW(path) != INVALID_FILE_ATTRIBUTES;
}

inline void Checkpoint(const char* checkpoint) noexcept {
  try {
    detail::WriteCheckpoint(checkpoint, "", Level::kNormal);
  } catch (...) {
    // Startup diagnostics must never affect application startup.
  }
}

inline void Checkpoint(const char* checkpoint,
                       const std::string& context) noexcept {
  try {
    detail::WriteCheckpoint(checkpoint, context, Level::kNormal);
  } catch (...) {
    // Startup diagnostics must never affect application startup.
  }
}

inline void VerboseCheckpoint(const char* checkpoint) noexcept {
  try {
    detail::WriteCheckpoint(checkpoint, "", Level::kVerbose);
  } catch (...) {
    // Startup diagnostics must never affect application startup.
  }
}

inline void VerboseCheckpoint(const char* checkpoint,
                              const std::string& context) noexcept {
  try {
    detail::WriteCheckpoint(checkpoint, context, Level::kVerbose);
  } catch (...) {
    // Startup diagnostics must never affect application startup.
  }
}

}  // namespace startup_diagnostics

#endif  // RUNNER_STARTUP_DIAGNOSTICS_H_
