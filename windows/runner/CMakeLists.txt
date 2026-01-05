cmake_minimum_required(VERSION 3.10)

# The name of the executable.
set(BINARY_NAME "angry_battery")

# The sources for the runner.
set(RUNNER_SOURCES
    "flutter_window.cpp"
    "main.cpp"
    "utils.cpp"
    "win32_window.cpp"
    "flutter_window.h"
    "utils.h"
    "win32_window.h"
    "resource.h"
    "runner.rc"
)

# The headers for the runner.
set(RUNNER_HEADERS
    "flutter_window.h"
    "resource.h"
    "utils.h"
    "win32_window.h"
)

# Add a new executable for the runner, and link it against the Flutter library.
add_executable(${BINARY_NAME} WIN32 ${RUNNER_SOURCES})
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)

#flutter_wrapper_plugin

# Add the existing flutter/ephemeral directory to the header search path.
# This is needed to find the versions of the C++ wrapper used by the plugins.
target_include_directories(${BINARY_NAME} PRIVATE "${FLUTTER_EPHEMERAL_DIR}")

# Add the directory containing the C++ wrapper headers.
target_include_directories(${BINARY_NAME} PRIVATE "${FLUTTER_EPHEMERAL_DIR}/cpp_client_wrapper/include")

# Tell the compiler to use C++17.
target_compile_features(${BINARY_NAME} PRIVATE cxx_std_17)

# Set the compile options.
set_target_properties(${BINARY_NAME} PROPERTIES
  # Tell the linker to create a GUI executable (vs a console executable).
  WIN32_EXECUTABLE TRUE
  # Set the C++ version for the runner.
  CXX_STANDARD 17
  CXX_STANDARD_REQUIRED TRUE
)

# Set any platform-specific compile flags.
if (CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
  target_compile_options(${BINARY_NAME} PRIVATE
    /W4 # Enable most warnings.
    /WX # Treat warnings as errors.
    /wd4100 # Allow unused function parameters.
  )
endif()

# Copy the data directory into the build directory.
set(DATA_DIR_PATH "${CMAKE_CURRENT_SOURCE_DIR}/data")
if(EXISTS ${DATA_DIR_PATH})
  add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${DATA_DIR_PATH} $<TARGET_FILE_DIR:${BINARY_NAME}>/data
  )
endif()

# Add the generated plugin registrant to the compilation.
# The plugin registrant is a generated file that includes the generated plugin
# files. It is created by the flutter tool.
add_library(flutter_plugin_registrant STATIC
  "${CMAKE_BINARY_DIR}/flutter/generated_plugin_registrant.cc"
)
target_link_libraries(${BINARY_NAME} PRIVATE flutter_plugin_registrant)

# Add the C++ wrapper from the Flutter engine.
target_link_libraries(${BINARY_NAME} PRIVATE flutter_wrapper_app)

# A list of all plugin headers.
set(PLUGIN_HEADER_FILES "")

# Add a dependency on the runner for each plugin.
set(PLUGIN_DIR "${CMAKE_BINARY_DIR}/plugins")
if(EXISTS ${PLUGIN_DIR})
  # Get all subdirectories of the plugin directory.
  file(GLOB plugin_subdirs LIST_DIRECTORIES true "${PLUGIN_DIR}/*")

  foreach(plugin_dir ${plugin_subdirs})
    if (IS_DIRECTORY ${plugin_dir})
      # Get the plugin name from the directory name.
      get_filename_component(plugin_name ${plugin_dir} NAME)

      # Add the plugin to the runner.
      add_subdirectory(${plugin_dir} ${CMAKE_BINARY_DIR}/plugins/${plugin_name})

      # Add a dependency on the runner for the plugin.
      target_link_libraries(${BINARY_NAME} PRIVATE ${plugin_name})

      # Add the plugin's headers to the list of plugin headers.
      set(PLUGIN_HEADER_FILES ${PLUGIN_HEADER_FILES}
        "${plugin_dir}/${plugin_name}_plugin.h"
      )
    endif()
  endforeach()
endif()

# Make the plugin headers available to the installation.
set(PLUGIN_HEADER_FILES ${PLUGIN_HEADER_FILES} PARENT_SCOPE)
