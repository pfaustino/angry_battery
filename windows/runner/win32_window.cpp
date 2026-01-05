#include "win32_window.h"

#include <dwmapi.h>

namespace {

constexpr const wchar_t kWindowClassName[] = L"FLUTTER_RUNNER_WIN32_WINDOW";

// Min/max dimensions in logical pixels.
constexpr int kMinWidth = 300;
constexpr int kMinHeight = 300;
constexpr int kDefaultWidth = 1280;
constexpr int kDefaultHeight = 720;

// The number of window pixels for each logical pixel.
float GetDpiForWindow(HWND hwnd) {
  UINT dpi = GetDpiForWindow(hwnd);
  return static_cast<float>(dpi) / 96.0f;
}

}  // namespace

Win32Window::Win32Window() {}

Win32Window::~Win32Window() {
  if (hwnd_) {
    Destroy();
  }
}

bool Win32Window::Create(const std::wstring& title, const Point& origin,
                       const Size& size) {
  Destroy();

  WNDCLASS window_class = {};
  window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
  window_class.lpszClassName = kWindowClassName;
  window_class.style = CS_HREDRAW | CS_VREDRAW;
  window_class.cbClsExtra = 0;
  window_class.cbWndExtra = sizeof(Win32Window*);
  window_class.hInstance = GetModuleHandle(nullptr);
  window_class.hIcon = LoadIcon(window_class.hInstance, MAKEINTRESOURCE(101));
  window_class.hbrBackground = 0;
  window_class.lpszMenuName = nullptr;
  window_class.lpfnWndProc = Win32Window::WndProc;
  RegisterClass(&window_class);

  hwnd_ = CreateWindow(
      kWindowClassName, title.c_str(), WS_OVERLAPPEDWINDOW | WS_VISIBLE,
      origin.x, origin.y, size.width, size.height, nullptr, nullptr,
      window_class.hInstance, this);
  if (!hwnd_) {
    return false;
  }

  return OnCreate();
}

void Win32Window::Show() {
  if (!hwnd_) {
    return;
  }
  ShowWindow(hwnd_, SW_SHOW);
  SetForegroundWindow(hwnd_);
}

// static
LRESULT CALLBACK Win32Window::WndProc(HWND const window,
                                      UINT const message,
                                      WPARAM const wparam,
                                      LPARAM const lparam) noexcept {
  if (message == WM_NCCREATE) {
    auto window_struct = reinterpret_cast<CREATESTRUCT*>(lparam);
    SetWindowLongPtr(window, GWLP_USERDATA,
                   reinterpret_cast<LONG_PTR>(window_struct->lpCreateParams));

    auto that = reinterpret_cast<Win32Window*>(window_struct->lpCreateParams);
    that->hwnd_ = window;
    return DefWindowProc(window, message, wparam, lparam);
  } else if (Win32Window* that = GetThisFromHandle(window)) {
    return that->MessageHandler(window, message, wparam, lparam);
  }

  return DefWindowProc(window, message, wparam, lparam);
}

LRESULT
Win32Window::MessageHandler(HWND hwnd, UINT const message,
                             WPARAM const wparam, LPARAM const lparam) noexcept {
  switch (message) {
    case WM_DESTROY:
      hwnd_ = nullptr;
      Destroy();
      if (quit_on_close_) {
        PostQuitMessage(0);
      }
      return 0;

    case WM_DPICHANGED: {
      float dpi = GetDpiForWindow(hwnd);

      RECT* suggested_rect = reinterpret_cast<RECT*>(lparam);
      SetWindowPos(hwnd, nullptr, suggested_rect->left, suggested_rect->top,
                   suggested_rect->right - suggested_rect->left,
                   suggested_rect->bottom - suggested_rect->top, SWP_NOZORDER);
      return 0;
    }

    case WM_GETMINMAXINFO: {
      float dpi = GetDpiForWindow(hwnd);

      MINMAXINFO* min_max_info = reinterpret_cast<MINMAXINFO*>(lparam);
      min_max_info->ptMinTrackSize.x =
          static_cast<LONG>(kMinWidth * dpi);
      min_max_info->ptMinTrackSize.y =
          static_cast<LONG>(kMinHeight * dpi);
      return 0;
    }

    case WM_SIZE: {
      UINT width = LOWORD(lparam);
      UINT height = HIWORD(lparam);

      if (child_content_ != nullptr) {
        // The client area is the area within the window's frame.
        MoveWindow(child_content_, 0, 0, width, height, TRUE);
      }
      return 0;
    }
  }

  return DefWindowProc(hwnd_, message, wparam, lparam);
}

void Win32Window::Destroy() {
  if (hwnd_) {
    DestroyWindow(hwnd_);
    hwnd_ = nullptr;
  }

  UnregisterClass(kWindowClassName, nullptr);
}

Win32Window* Win32Window::GetThisFromHandle(HWND const window) noexcept {
  return reinterpret_cast<Win32Window*>(
      GetWindowLongPtr(window, GWLP_USERDATA));
}

void Win32Window::SetChildContent(HWND content) {
  child_content_ = content;
  SetParent(content, hwnd_);
  RECT frame;
  GetClientRect(hwnd_, &frame);
  MoveWindow(content, 0, 0, frame.right - frame.left, frame.bottom - frame.top,
             true);
  SetFocus(content);
}

RECT Win32Window::GetClientArea() {
  RECT frame;
  GetClientRect(hwnd_, &frame);
  return frame;
}
