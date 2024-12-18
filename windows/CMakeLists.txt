# Project-level configuration.
cmake_minimum_required(VERSION 3.14)
project(syrius LANGUAGES CXX)

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
set(BINARY_NAME "syrius")
set(APPLICATION_ID "network.zenon.syrius")

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(VERSION 3.14...3.25)

# Define build configuration option.
get_property(IS_MULTICONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(IS_MULTICONFIG)
  set(CMAKE_CONFIGURATION_TYPES "Debug;Profile;Release"
    CACHE STRING "" FORCE)
else()
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE "Debug" CACHE
      STRING "Flutter build mode" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
      "Debug" "Profile" "Release")
  endif()
endif()
# Define settings for the Profile build mode.
set(CMAKE_EXE_LINKER_FLAGS_PROFILE "${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
set(CMAKE_SHARED_LINKER_FLAGS_PROFILE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE}")
set(CMAKE_C_FLAGS_PROFILE "${CMAKE_C_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_RELEASE}")

# Use Unicode for all projects.
add_definitions(-DUNICODE -D_UNICODE)

# Compilation settings that should be applied to most targets.
#
# Be cautious about adding new options here, as plugins use this function by
# default. In most cases, you should add new options to specific targets instead
# of modifying this function.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_17)
  target_compile_options(${TARGET} PRIVATE /W4 /WX /wd"4100")
  target_compile_options(${TARGET} PRIVATE /EHsc)
  target_compile_definitions(${TARGET} PRIVATE "_HAS_EXCEPTIONS=0")
  target_compile_definitions(${TARGET} PRIVATE "$<$<CONFIG:Debug>:_DEBUG>")
endfunction()

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# Application build; see runner/CMakeLists.txt.
add_subdirectory("runner")


# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
include(flutter/generated_plugins.cmake)


# === Installation ===
# Support files are copied into place next to the executable, so that it can
# run in place. This is done instead of making a separate bundle (as on Linux)
# so that building and running from within Visual Studio will work.
set(BUILD_BUNDLE_DIR "$<TARGET_FILE_DIR:${BINARY_NAME}>")
# Make the "install" step default, as it's required to run.
set(CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD 1)
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

if(PLUGIN_BUNDLED_LIBRARIES)
  install(FILES "${PLUGIN_BUNDLED_LIBRARIES}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()

# Copy the native assets provided by the build.dart from all packages.
set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/windows/")
install(DIRECTORY "${NATIVE_ASSETS_DIR}"
   DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
   COMPONENT Runtime)

# Fully re-copy the assets directory on each build to avoid having stale files
# from a previous install.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# Install the AOT library on non-Debug builds only.
install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  CONFIGURATIONS Profile;Release
  COMPONENT Runtime)

# Bundle required ZNN libraries for Syrius
set(SYRIUS_PROJECT_DIRECTORY "${CMAKE_HOME_DIRECTORY}/..")

# Read lines from the file `package_config_subset` that match the regex pattern
# looking for paths containing "znn_sdk_dart" and ending with a "/".
file(STRINGS "${SYRIUS_PROJECT_DIRECTORY}/.dart_tool/package_config_subset"
        ZNN_SDK_DART_PATHS REGEX "(file:).*(znn_sdk_dart).*/$" )

# Initialize an empty variable to store the final znn_sdk_dart path
set(ZNN_SDK_DART_PATH "")

# Loop through each path found by the file command
foreach(PATH ${ZNN_SDK_DART_PATHS})
  # Exclude paths containing "/lib/" using a conditional check
  if(NOT "${PATH}" MATCHES ".*/lib/.*")
    # If the condition is met, set the current path as ZNN_SDK_DART_PATH
    set(ZNN_SDK_DART_PATH ${PATH})
  endif()
endforeach()

# Remove the "file:///" prefix from the selected path, if present
string(REPLACE "file:///" "" ZNN_SDK_DART_PATH "${ZNN_SDK_DART_PATH}")

# Strip any leading or trailing whitespace from the cleaned path
string(STRIP "${ZNN_SDK_DART_PATH}" ZNN_SDK_DART_PATH)

# Repeat the same process for "znn_ledger_dart" paths:

# Read lines from the file `package_config_subset` that match the regex pattern
# looking for paths containing "znn_ledger_dart" and ending with a "/".
file(STRINGS "${SYRIUS_PROJECT_DIRECTORY}/.dart_tool/package_config_subset"
        ZNN_LEDGER_DART_PATHS REGEX "(file:).*(znn_ledger_dart).*/$" )

# Initialize an empty variable to store the final znn_ledger_dart path
set(ZNN_LEDGER_DART_PATH "")

# Loop through each path found by the file command
foreach(PATH ${ZNN_LEDGER_DART_PATHS})
  # Exclude paths containing "/lib/" using a conditional check
  if(NOT "${PATH}" MATCHES ".*/lib/.*")
    # If the condition is met, set the current path as ZNN_LEDGER_DART_PATH
    set(ZNN_LEDGER_DART_PATH ${PATH})
  endif()
endforeach()

# Remove the "file:///" prefix from the selected path, if present
string(REPLACE "file:///" "" ZNN_LEDGER_DART_PATH "${ZNN_LEDGER_DART_PATH}")

# Strip any leading or trailing whitespace from the cleaned path
string(STRIP "${ZNN_LEDGER_DART_PATH}" ZNN_LEDGER_DART_PATH)

# Append the paths to various library files into the `SYRIUS_LIBRARIES` list.
# These paths include:
# 1. A static path to `libznn.dll` located in the `embedded_node/blobs` directory.
# 2. Dynamically constructed paths based on `ZNN_SDK_DART_PATH` and `ZNN_LEDGER_DART_PATH`.
#    These paths point to shared libraries for argon2, proof-of-work, and ledger functionality.
list(APPEND SYRIUS_LIBRARIES
        "${SYRIUS_PROJECT_DIRECTORY}/lib/embedded_node/blobs/libznn.dll" # Path to libznn.dll
        "${ZNN_SDK_DART_PATH}/lib/src/argon2/blobs/argon2_ffi_plugin.dll" # Argon2 plugin
        "${ZNN_SDK_DART_PATH}/lib/src/pow/blobs/libpow_links.dll" # Proof-of-work library
        "${ZNN_LEDGER_DART_PATH}/lib/src/ledger/blobs/libledger_ffi.dll" # Ledger FFI library
        )

# Loop over each library in the `SYRIUS_LIBRARIES` list.
foreach(znn_library ${SYRIUS_LIBRARIES})
  # Install the library to the destination specified by `CMAKE_INSTALL_PREFIX`.
  # `FILES` specifies the file to copy.
  # `DESTINATION` specifies where the file should be installed.
  # `COMPONENT` groups the installation under the "Runtime" component for packaging or deployment tools.
  install(FILES "${znn_library}"
          DESTINATION "${CMAKE_INSTALL_PREFIX}"
          COMPONENT Runtime)

  # Print a status message indicating that the current library is being copied.
  message(STATUS "Copy ZNN library: \"${znn_library}\"")
endforeach(znn_library)

find_program(POWERSHELL_PATH NAMES powershell)
add_custom_target("git_metadata" ALL
        COMMAND ${POWERSHELL_PATH} -ExecutionPolicy Bypass "${CMAKE_HOME_DIRECTORY}/CreateGitMetadata.ps1")