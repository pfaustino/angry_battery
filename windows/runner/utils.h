#ifndef RUNNER_UTILS_H_
#define RUNNER_UTILS_H_

#include <string>
#include <vector>

// Creates a console and redirects stdout and stderr to it.
//
// This is useful for debugging, and also for seeing output from printf
// statements.
void CreateAndShowConsole();

// Gets the command line arguments passed to the application as a vector of
// UTF-8 strings.
std::vector<std::string> GetCommandLineArguments();

// Converts a UTF-16 string to a UTF-8 string.
std::string Utf8FromUtf16(const wchar_t* utf16_string);

#endif  // RUNNER_UTILS_H_
