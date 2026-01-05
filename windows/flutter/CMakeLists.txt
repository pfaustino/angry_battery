# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This file is not used by the engine, but is left here for applications that
# may be linking against the C++ wrapper directly.

# To use this, add the following to the application's top-level CMakeLists.txt:
#   add_subdirectory(flutter)
# Then link the application against the flutter_wrapper_app target.

cmake_minimum_required(VERSION 3.10)

# Only the C++ wrapper is built. To build the plugins, the top-level
# CMakeLists.txt should instead use the flutter_tool_command to call into
# the tool, which will create a complete project with all the necessary build
# rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ephemeral")
set(PROJECT_BUILD_DIR "${CMAKE_BINARY_DIR}")

# The C++ wrapper's source files.
set(WRAPPER_SOURCES
  "${FLUTTER_MANAGED_DIR}/cpp_client_wrapper/core_implementations.cc"
  "${FLUTTER_MANAGED_DIR}/cpp_client_wrapper/standard_codec.cc"
  "${FLUTTER_MANAGED_DIR}/cpp_client_wrapper/flutter_engine.cc"
  "${FLUTTER_MANAGED_DIR}/cpp_client_wrapper/flutter_view_controller.cc"
)

# The C++ wrapper's public-facing headers.
set(WRAPPER_HEADERS
  "${FLUTTER_MANAGED_DIR}/cpp_client_wrapper/include/flutter/binary_messenger.h"
  "${FLUTTER_MANAGED_DIR}/cpp_client_wrapper/include/flutter/engine_method_result.h"
  "${FLUTTER_MANAGED_DIR}/cpp_client_wrapper/include/flutter/flutter_engine.h"
  "${FLUTTER_MANAGED_DIR}/cpp_client_wrapper/include/flutter/flutter_view.h"
  "${FLUTTER_MANAGED_DIR}/cpp_client_wrapper/include/flutter/flutter_view_controller.h"
  "${FLUTTER_MANAGED_DIR}/cpp_client_wrapper/include/flutter/method_call.h"
  "${FLUTTER_MANAGED_DIR}/cpp_client_wrapper/include/flutter/method_channel.h"
  "${FLUTTER_MANAGED_DIR}/cpp_client_wrapper/include/flutter/method_codec.h"
  "${FLUTTER_MANAGED_DIR}/cpp_client_wrapper/include/flutter/method_result.h"
  "${FLUTTER_MANAGED_DIR}/cpp_client_wrapper/include/flutter/basic_message_channel.h"
  "${FLUTTER_MANAGED_DIR}/cpp_client_wrapper/include/flutter/event_channel.h"
  "${FLUTTER_MANAGED_DIR}/cpp_client_wrapper/include/flutter/event_sink.h"
  "${FLUTTER_MANAGED_DIR}/cpp_client_wrapper/include/flutter/event_stream_handler.h"
  "${FLUTTER_MANAGED_DIR}/cpp_client_wrapper/include/flutter/plugin_registrar.h"
  "${FLUTTER_MANAGED_DIR}/cpp_client_wrapper/include/flutter/plugin_registrar_windows.h"
  "${FLUTTER_MANAGED_DIR}/cpp_client_wrapper/include/flutter/standard_message_codec.h"
  "${FLUTTER_MANAGED_DIR}/cpp_client_wrapper/include/flutter/standard_method_codec.h"
  "${FLUTTER_MANAGED_DIR}/cpp_client_wrapper/include/flutter/texture_registrar.h"
)

# Add a library for the C++ wrapper.
add_library(flutter_wrapper_app STATIC ${WRAPPER_SOURCES} ${WRAPPER_HEADERS})

# Set the header search path for the wrapper.
target_include_directories(flutter_wrapper_app PUBLIC
  "${FLUTTER_MANAGED_DIR}/cpp_client_wrapper/include"
  "${FLUTTER_MANAGED_DIR}"
)

# Set up the installation rules for the wrapper headers.
set_target_properties(flutter_wrapper_app PROPERTIES
  PUBLIC_HEADER "${WRAPPER_HEADERS}"
)
