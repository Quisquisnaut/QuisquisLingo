#include "flutter_window.h"

#include <optional>
#include <sstream>

#include "flutter/generated_plugin_registrant.h"
#include "startup_diagnostics.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  startup_diagnostics::Checkpoint("NATIVE_FLUTTER_ONCREATE_BEGIN");
  if (!Win32Window::OnCreate()) {
    startup_diagnostics::Checkpoint("NATIVE_FLUTTER_ONCREATE_BASE_FAILED");
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  try {
    std::ostringstream context;
    context << "data="
            << (startup_diagnostics::PathExists(L"data") ? "present"
                                                           : "absent")
            << "; data\\icudtl.dat="
            << (startup_diagnostics::PathExists(L"data\\icudtl.dat")
                    ? "present"
                    : "absent")
            << "; data\\flutter_assets="
            << (startup_diagnostics::PathExists(L"data\\flutter_assets")
                    ? "present"
                    : "absent")
            << "; data\\app.so="
            << (startup_diagnostics::PathExists(L"data\\app.so")
                    ? "present"
                    : "absent");
    startup_diagnostics::Checkpoint("NATIVE_VIEW_CONTROLLER_CREATE_BEGIN",
                                    context.str());
  } catch (...) {
    startup_diagnostics::Checkpoint("NATIVE_VIEW_CONTROLLER_CREATE_BEGIN");
  }
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  startup_diagnostics::Checkpoint("NATIVE_VIEW_CONTROLLER_RETURNED");
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    try {
      startup_diagnostics::Checkpoint(
          "NATIVE_ENGINE_VIEW_INVALID",
          std::string("engine=") +
              (flutter_controller_->engine() ? "present" : "absent") +
              "; view=" +
              (flutter_controller_->view() ? "present" : "absent"));
    } catch (...) {
      startup_diagnostics::Checkpoint("NATIVE_ENGINE_VIEW_INVALID");
    }
    return false;
  }
  startup_diagnostics::Checkpoint("NATIVE_ENGINE_VIEW_OK");
  startup_diagnostics::Checkpoint("NATIVE_PLUGIN_REGISTRATION_BEGIN");
  RegisterPlugins(flutter_controller_->engine());
  startup_diagnostics::Checkpoint("NATIVE_PLUGIN_REGISTRATION_OK");
  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  startup_diagnostics::Checkpoint("NATIVE_CHILD_VIEW_ATTACHED");

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    startup_diagnostics::Checkpoint("NATIVE_FIRST_FRAME_CALLBACK");
    const bool was_visible = this->Show();
    startup_diagnostics::Checkpoint("NATIVE_WINDOW_SHOW_CALLED");
    try {
      const HWND window = this->GetHandle();
      RECT bounds = {};
      const bool bounds_available = GetWindowRect(window, &bounds) != FALSE;
      const DWORD bounds_error = bounds_available ? ERROR_SUCCESS : GetLastError();
      std::ostringstream context;
      context << "previously_visible=" << (was_visible ? "true" : "false")
              << "; visible_now="
              << (IsWindowVisible(window) ? "true" : "false")
              << "; minimized=" << (IsIconic(window) ? "true" : "false");
      if (bounds_available) {
        context << "; bounds=" << bounds.left << ',' << bounds.top << ','
                << bounds.right << ',' << bounds.bottom;
      } else {
        context << "; get_window_rect_error=" << bounds_error;
      }
      startup_diagnostics::VerboseCheckpoint("NATIVE_WINDOW_STATE",
                                             context.str());
    } catch (...) {
      startup_diagnostics::VerboseCheckpoint("NATIVE_WINDOW_STATE");
    }
  });
  startup_diagnostics::VerboseCheckpoint(
      "NATIVE_FIRST_FRAME_CALLBACK_INSTALLED");

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();
  startup_diagnostics::VerboseCheckpoint("NATIVE_FORCE_REDRAW_CALLED");

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
