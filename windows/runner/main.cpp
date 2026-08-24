#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "startup_diagnostics.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  startup_diagnostics::Checkpoint("NATIVE_WWINMAIN_ENTER");

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  const HRESULT com_result =
      ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  try {
    startup_diagnostics::VerboseCheckpoint(
        "NATIVE_COM_RESULT",
        "hresult=" + std::to_string(static_cast<long>(com_result)));
  } catch (...) {
    startup_diagnostics::VerboseCheckpoint("NATIVE_COM_RESULT");
  }

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));
  startup_diagnostics::Checkpoint("NATIVE_DART_PROJECT_READY");

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  startup_diagnostics::Checkpoint("NATIVE_WINDOW_CREATE_BEGIN");
  if (!window.Create(L"QuisquisLingo", origin, size)) {
    startup_diagnostics::Checkpoint("NATIVE_PROCESS_EXIT",
                                    "exit_code=1; reason=window_create_failed");
    return EXIT_FAILURE;
  }
  startup_diagnostics::Checkpoint("NATIVE_WINDOW_CREATE_OK");
  window.SetQuitOnClose(true);

  ::MSG msg;
  startup_diagnostics::Checkpoint("NATIVE_RUN_LOOP_ENTER");
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }
  try {
    startup_diagnostics::VerboseCheckpoint(
        "NATIVE_RUN_LOOP_RESULT",
        "wparam=" +
            std::to_string(static_cast<unsigned long long>(msg.wParam)));
  } catch (...) {
    // The normal lifecycle marker below remains available if detail fails.
  }
  startup_diagnostics::Checkpoint("NATIVE_RUN_LOOP_EXIT");

  ::CoUninitialize();
  startup_diagnostics::Checkpoint("NATIVE_PROCESS_EXIT", "exit_code=0");
  return EXIT_SUCCESS;
}
