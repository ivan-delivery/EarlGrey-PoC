#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.

PROJECT_NAME="EarlGrey.xcodeproj" # Or YOUR_WORKSPACE.xcworkspace
TESTLIB_SCHEME="TestLib"
APPFRAMEWORK_SCHEME="AppFramework"
BUILD_DIR=$(mktemp -d) # Create a temporary directory for archives
#export BUILD_DIR="./build_dir"

# Clean previous build (optional)
echo "Cleaning previous build..."
rm -rf "${BUILD_DIR}"
rm -fr "./derived_data"

echo "Building frameworks in: $BUILD_DIR"

# --- Build AppFramework ---
echo "Archiving AppFramework for iOS..."
xcodebuild archive \
  -project "${PROJECT_NAME}" \
  -scheme "${APPFRAMEWORK_SCHEME}" \
  -destination "generic/platform=iOS" \
  -derivedDataPath "./derived_data" \
  -archivePath "${BUILD_DIR}/${APPFRAMEWORK_SCHEME}-iOS.xcarchive" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES | xcbeautify


echo "Archiving AppFramework for iOS Simulator..."
xcodebuild archive \
  -project "${PROJECT_NAME}" \
  -scheme "${APPFRAMEWORK_SCHEME}" \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath "./derived_data" \
  -archivePath "${BUILD_DIR}/${APPFRAMEWORK_SCHEME}-iOS-Simulator.xcarchive" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES | xcbeautify

echo "Creating AppFramework.xcframework..."
xcodebuild -create-xcframework \
  -archive "${BUILD_DIR}/${APPFRAMEWORK_SCHEME}-iOS.xcarchive" \
  -framework "${APPFRAMEWORK_SCHEME}.framework" \
  -archive "${BUILD_DIR}/${APPFRAMEWORK_SCHEME}-iOS-Simulator.xcarchive" \
  -framework "${APPFRAMEWORK_SCHEME}.framework" \
  -output "${APPFRAMEWORK_SCHEME}.xcframework" | xcbeautify

echo "Finished AppFramework.xcframework"



# --- Build TestLib ---
echo "Archiving TestLib for iOS..."
xcodebuild archive \
  -project "${PROJECT_NAME}" \
  -scheme "${TESTLIB_SCHEME}" \
  -destination "generic/platform=iOS" \
  -archivePath "${BUILD_DIR}/${TESTLIB_SCHEME}-iOS.xcarchive" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES | xcbeautify

echo "Archiving TestLib for iOS Simulator..."
xcodebuild archive \
  -project "${PROJECT_NAME}" \
  -scheme "${TESTLIB_SCHEME}" \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "${BUILD_DIR}/${TESTLIB_SCHEME}-iOS-Simulator.xcarchive" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES | xcbeautify

echo "Creating TestLib.xcframework..."
xcodebuild -create-xcframework \
  -library "${BUILD_DIR}/${TESTLIB_SCHEME}-iOS.xcarchive/Products/usr/local/lib/lib${TESTLIB_SCHEME}.a" \
  -headers "${BUILD_DIR}/${TESTLIB_SCHEME}-iOS.xcarchive/Products/usr/local/include/" \
  -library "${BUILD_DIR}/${TESTLIB_SCHEME}-iOS-Simulator.xcarchive/Products/usr/local/lib/lib${TESTLIB_SCHEME}.a" \
  -headers "${BUILD_DIR}/${TESTLIB_SCHEME}-iOS-Simulator.xcarchive/Products/usr/local/include/" \
  -output "${TESTLIB_SCHEME}.xcframework" | xcbeautify

echo "Finished TestLib.xcframework"