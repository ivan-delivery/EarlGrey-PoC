#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
# !!! Adjust these variables for your project !!!
# Use the full path to your project or workspace file
PROJECT_OR_WORKSPACE_PATH="EarlGrey.xcodeproj" # Or "/path/to/YOUR_WORKSPACE.xcworkspace"

# Specify whether you are using a project or workspace
PROJECT_FLAG="-project" # Use "-project" for .xcodeproj, "-workspace" for .xcworkspace

# Ensure these scheme names match your Xcode project exactly
TESTLIB_SCHEME="TestLib"
APPFRAMEWORK_SCHEME="AppFramework"

# Define Output names for the XCFrameworks (can be customized)
TESTLIB_XCFRAMEWORK_NAME="${TESTLIB_SCHEME}.xcframework"
APPFRAMEWORK_XCFRAMEWORK_NAME="${APPFRAMEWORK_SCHEME}.xcframework"

# Temporary directory for archives - script will create and delete this
BUILD_DIR=$(mktemp -d)

# --- Function Definitions ---

# Function to archive TestLib and create TestLib.xcframework (static library)
build_testlib_xcframework() {
  # Uses global variables for configuration:
  # PROJECT_FLAG, PROJECT_OR_WORKSPACE_PATH, TESTLIB_SCHEME,
  # TESTLIB_XCFRAMEWORK_NAME, BUILD_DIR

  local scheme_name="${TESTLIB_SCHEME}"
  local output_xcframework_name="${TESTLIB_XCFRAMEWORK_NAME}"
  local archive_base_path="${BUILD_DIR}/${scheme_name}"

  # Define expected header path within archive.
  # *** IMPORTANT: Verify this path by inspecting your .xcarchive if builds fail ***
  # Common paths: "Products/usr/local/include/" or "Products/usr/local/include/${scheme_name}/"
  local headers_path_in_archive="Products/usr/local/include/"

  echo "--- Building ${output_xcframework_name} ---"

  echo "[${scheme_name}] Archiving for iOS..."
  xcodebuild archive \
    "${PROJECT_FLAG}" "${PROJECT_OR_WORKSPACE_PATH}" \
    -scheme "${scheme_name}" \
    -destination "generic/platform=iOS" \
    -archivePath "${archive_base_path}-iOS.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES |  xcbeautify

  echo "[${scheme_name}] Archiving for iOS Simulator..."
  xcodebuild archive \
    "${PROJECT_FLAG}" "${PROJECT_OR_WORKSPACE_PATH}" \
    -scheme "${scheme_name}" \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "${archive_base_path}-iOS-Simulator.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES |  xcbeautify

  echo "[${scheme_name}] Creating ${output_xcframework_name}..."
  # Uses -library and -headers for static library
  xcodebuild -create-xcframework \
    -library "${archive_base_path}-iOS.xcarchive/Products/usr/local/lib/lib${scheme_name}.a" \
    -headers "${archive_base_path}-iOS.xcarchive/${headers_path_in_archive}" \
    -library "${archive_base_path}-iOS-Simulator.xcarchive/Products/usr/local/lib/lib${scheme_name}.a" \
    -headers "${archive_base_path}-iOS-Simulator.xcarchive/${headers_path_in_archive}" \
    -output "${output_xcframework_name}" |  xcbeautify

  echo "[${scheme_name}] Finished ${output_xcframework_name}"
  echo "-------------------------------------"
}

# Function to archive AppFramework and create AppFramework.xcframework (dynamic framework)
build_appframework_xcframework() {
  # Uses global variables for configuration:
  # PROJECT_FLAG, PROJECT_OR_WORKSPACE_PATH, APPFRAMEWORK_SCHEME,
  # APPFRAMEWORK_XCFRAMEWORK_NAME, BUILD_DIR

  local scheme_name="${APPFRAMEWORK_SCHEME}"
  local output_xcframework_name="${APPFRAMEWORK_XCFRAMEWORK_NAME}"
  local archive_base_path="${BUILD_DIR}/${scheme_name}"

  # Assumes framework product name matches scheme name. Adjust if necessary.
  local framework_name_in_archive="${scheme_name}.framework"

  echo "--- Building ${output_xcframework_name} ---"

  echo "[${scheme_name}] Archiving for iOS..."
  xcodebuild archive \
    "${PROJECT_FLAG}" "${PROJECT_OR_WORKSPACE_PATH}" \
    -scheme "${scheme_name}" \
    -destination "generic/platform=iOS" \
    -archivePath "${archive_base_path}-iOS.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES |  xcbeautify

  echo "[${scheme_name}] Archiving for iOS Simulator..."
  xcodebuild archive \
    "${PROJECT_FLAG}" "${PROJECT_OR_WORKSPACE_PATH}" \
    -scheme "${scheme_name}" \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "${archive_base_path}-iOS-Simulator.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES |  xcbeautify

  echo "[${scheme_name}] Creating ${output_xcframework_name}..."
  # Uses -framework for dynamic framework
  # Ensure the path inside -framework points to the correct .framework directory within the archive products
  xcodebuild -create-xcframework \
    -framework "${archive_base_path}-iOS.xcarchive/Products/Library/Frameworks/${framework_name_in_archive}" \
    -framework "${archive_base_path}-iOS-Simulator.xcarchive/Products/Library/Frameworks/${framework_name_in_archive}" \
    -output "${output_xcframework_name}" |  xcbeautify

  echo "[${scheme_name}] Finished ${output_xcframework_name}"
  echo "--------------------------------------"
}

# --- Main Execution ---

echo "Starting XCFramework build process..."
echo "Using temporary build directory: ${BUILD_DIR}"
echo "Building requires correct project configuration (Header visibility, Architectures, etc.)."

# --- Cleanup ---
echo "Cleaning up temporary build directory: ${BUILD_DIR} ..."
rm -rf "${BUILD_DIR}"

# Build TestLib XCFramework
build_testlib_xcframework

# Build AppFramework XCFramework
build_appframework_xcframework

# --- Cleanup ---
#echo "Cleaning up temporary build directory: ${BUILD_DIR} ..."
#rm -rf "${BUILD_DIR}"

echo ""
echo "--------------------------------------"
echo "XCFramework build process complete."
echo "Output files in current directory:"
echo "- ${TESTLIB_XCFRAMEWORK_NAME}"
echo "- ${APPFRAMEWORK_XCFRAMEWORK_NAME}"
echo "--------------------------------------"
echo "Done."
