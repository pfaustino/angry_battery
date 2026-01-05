#ifndef RUNNER_WIN32_WINDOW_H_
#define RUNNER_WIN32_WINDOW_H_

#include <windows.h>

#include <functional>
#include <memory>
#include <string>

// A class that wraps a win32 window.
class Win32Window {
 public:
  struct Point {
    int x;
    int y;
  };
  struct Size {
    int width;
    int height;
  };

  Win32Window();
  virtual ~Win32Window();

  // Creates a window and shows it.
  bool Create(const std::wstring& title, const Point& origin, const Size& size);

  // Shows the window.
  void Show();

  // Releases OS resources associated with the window.
  void Destroy();

  // Sets the quit-on-close flag for the window.
  void SetQuitOnClose(bool quit_on_close) { quit_on_close_ = quit_on_close; }

  // Returns the backing-store scale factor for the window.
  double GetScaleFactor();

  // Returns the client area of the window.
  RECT GetClientArea();

 protected:
  // Processes and routes incoming window messages.
  virtual LRESULT MessageHandler(HWND window, UINT const message, WPARAM wparam,
                               LPARAM lparam) noexcept;

  // Called when the window is created.
  virtual bool OnCreate();

  // Called when the window is destroyed.
  virtual void OnDestroy();

  // Sets the child content of the window.
  void SetChildContent(HWND content);

 private:
  // Win32 window callback.
  static LRESULT CALLBACK WndProc(HWND const window, UINT const message,
                                WPARAM const wparam, LPARAM const lparam) noexcept;

  // Retrieves the Win32Window instance associated with the given window handle.
  static Win32Window* GetThisFromHandle(HWND const window) noexcept;

  // Whether the window has been destroyed.
  bool destroyed_ = false;

  // The handle for the window.
  HWND hwnd_ = nullptr;

  // The handle for the child content.
  HWND child_content_ = nullptr;

  // Whether to exit the application when the window is closed.
  bool quit_on_close_ = false;
};

#endif  // RUNNER_WIN32_WINDOW_H_
