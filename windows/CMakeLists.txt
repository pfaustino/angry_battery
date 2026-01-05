# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

cmake_minimum_required(VERSION 3.10)

# Project is the parent of the runner and the plugins.
project(runner)

# The name of the executable, which is also the name of the Visual Studio project.
set(BINARY_NAME "angry_battery")

# The name of the project, which is used in the generated solution file.
# By default, this is the name of the top-level folder.
get_filename_component(PROJECT_NAME "${CMAKE_CURRENT_SOURCE_DIR}" NAME)
string(REPLACE " " "_" PROJECT_NAME ${PROJECT_NAME})

# A custom command to generate the necessary build files and copy the Flutter
# assets to the right place.
#
# This command is a blocking step that must be run before the runner can be
# built, and is used in a post-build step to re-copy the assets if they have
# changed.
add_custom_command(
  OUTPUT
    "${CMAKE_BINARY_DIR}/flutter/ephemeral/flutter_windows.dll"
    "${CMAKE_BINARY_DIR}/flutter/ephemeral/icudtl.dat"
    "${CMAKE_BINARY_DIR}/flutter_assets"
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${FLUTTER_EPHEMERAL_DIR}/flutter_windows.dll"
    "${CMAKE_BINARY_DIR}/flutter/ephemeral/flutter_windows.dll"
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${FLUTTER_EPHEMERAL_DIR}/icudtl.dat"
    "${CMAKE_BINARY_DIR}/flutter/ephemeral/icudtl.dat"
  COMMAND ${CMAKE_COMMAND} -E copy_directory
    "${PROJECT_BUILD_DIR}/flutter_assets"
    "${CMAKE_BINARY_DIR}/flutter_assets"
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
  DEPENDS
    "${FLUTTER_EPHEMERAL_DIR}/flutter_windows.dll"
    "${FLUTTER_EPHEMERAL_DIR}/icudtl.dat"
    "${PROJECT_BUILD_DIR}/flutter_assets"
  COMMENT
    "Copying Flutter-built assets to build directory."
)

add_custom_target(
  flutter_assemble
  DEPENDS
    "${CMAKE_BINARY_DIR}/flutter/ephemeral/flutter_windows.dll"
    "${CMAKE_BINARY_DIR}/flutter/ephemeral/icudtl.dat"
    "${CMAKE_BINARY_DIR}/flutter_assets"
  SOURCES
    # Dummy source file to ensure that the custom target gets created.
    "${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt"
)

# Add the subdirectory for the Flutter library.
add_subdirectory(flutter)

# Add the subdirectory for the runner. This will create the actual executable.
add_subdirectory(runner)

# Top-level install rules.
#
# Note: This is just an example of a packaging setup. Production applications
# should likely use a more robust installer generation solution.
set(INSTALL_BUNDLE_DIR "${CMAKE_INSTALL_PREFIX}/${BINARY_NAME}")
install(
  TARGETS ${BINARY_NAME}
  RUNTIME DESTINATION "${INSTALL_BUNDLE_DIR}"
)
install(
  FILES
    "${CMAKE_BINARY_DIR}/flutter/ephemeral/flutter_windows.dll"
    "${CMAKE_BINARY_DIR}/flutter/ephemeral/icudtl.dat"
  DESTINATION "${INSTALL_BUNDLE_DIR}"
  COMPONENT Runtime
)
install(
  DIRECTORY "${CMAKE_BINARY_DIR}/flutter_assets"
  DESTINATION "${INSTALL_BUNDLE_DIR}"
  COMPONENT Runtime
)

# Install the plugins.
install(
  DIRECTORY "${CMAKE_BINARY_DIR}/plugins/"
  DESTINATION "${INSTALL_BUNDLE_DIR}/data/flutter_assets/plugins"
  COMPONENT Runtime
  PATTERN "windows-x64" EXCLUDE
)

# Install the C++ wrapper's .lib file, and the headers for the library and
# the plugins, for developers who want to link against the exported APIs.
install(
  TARGETS flutter_wrapper_app
  ARCHIVE DESTINATION "${INSTALL_BUNDLE_DIR}/data/flutter_assets/lib"
  LIBRARY DESTINATION "${INSTALL_BUNDLE_DIR}/data/flutter_assets/lib"
  PUBLIC_HEADER DESTINATION "${INSTALL_BUNDLE_DIR}/data/flutter_assets/include/flutter"
)
install(
  DIRECTORY "${FLUTTER_EPHEMERAL_DIR}/cpp_client_wrapper/include/flutter"
  DESTINATION "${INSTALL_BUNDLE_DIR}/data/flutter_assets/include/flutter"
  FILES_MATCHING PATTERN "*.h"
)
install(
  DIRECTORY "${CMAKE_BINARY_DIR}/flutter/ephemeral/cpp_client_wrapper_glfw/include/flutter"
  DESTINATION "${INSTALL_BUNDLE_DIR}/data/flutter_assets/include/flutter"
  FILES_MATCHING PATTERN "*.h"
)
install(
  FILES ${PLUGIN_HEADER_FILES}
  DESTINATION "${INSTALL_BUNDLE_DIR}/data/flutter_assets/include/${BINARY_NAME}"
)
