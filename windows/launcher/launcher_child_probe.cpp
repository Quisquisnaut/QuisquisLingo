#include <windows.h>

#include <string>
#include <vector>

namespace {

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

std::wstring CurrentDirectory() {
  DWORD length = GetCurrentDirectoryW(0, nullptr);
  if (length == 0) {
    return {};
  }
  std::vector<wchar_t> buffer(length);
  length = GetCurrentDirectoryW(static_cast<DWORD>(buffer.size()),
                                buffer.data());
  if (length == 0 || length >= buffer.size()) {
    return {};
  }
  return std::wstring(buffer.data(), length);
}

bool WriteWideFile(const std::wstring& path, const std::wstring& content) {
  HANDLE file = CreateFileW(path.c_str(), GENERIC_WRITE, FILE_SHARE_READ,
                            nullptr, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL,
                            nullptr);
  if (file == INVALID_HANDLE_VALUE) {
    return false;
  }
  DWORD written = 0;
  const DWORD bytes =
      static_cast<DWORD>(content.size() * sizeof(wchar_t));
  const bool success = WriteFile(file, content.data(), bytes, &written,
                                 nullptr) != FALSE &&
                       written == bytes;
  CloseHandle(file);
  return success;
}

}  // namespace

int wmain(int argument_count, wchar_t** argument_values) {
  const std::wstring output_path =
      EnvironmentValue(L"QQL_BOOTSTRAP_PROBE_OUTPUT");
  if (output_path.empty()) {
    return 2;
  }

  std::wstring output = L"cwd=" + CurrentDirectory() + L"\n";
  output.append(L"sentinel=")
      .append(EnvironmentValue(L"QQL_BOOTSTRAP_PROBE_SENTINEL"))
      .append(L"\n");
  output.append(L"argc=").append(std::to_wstring(argument_count - 1))
      .append(L"\n");
  for (int index = 1; index < argument_count; ++index) {
    output.append(L"arg=").append(argument_values[index]).append(L"\n");
  }
  return WriteWideFile(output_path, output) ? 0 : 3;
}
