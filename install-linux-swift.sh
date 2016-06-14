#!/bin/bash
set -ev
SWIFT_SNAPSHOT="swift-3.0-preview-1"
XCTEST_SNAPSHOT="swift-3.0-PREVIEW-1"

echo "Installing ${SWIFT_SNAPSHOT}..."
if [ ! -f "${SWIFT_SNAPSHOT}-ubuntu14.04.tar.gz" ]; then
  curl -s -L -O "https://swift.org/builds/${SWIFT_SNAPSHOT}/ubuntu1404/${SWIFT_SNAPSHOT}/${SWIFT_SNAPSHOT}-ubuntu14.04.tar.gz"
fi

tar -zxvf "${SWIFT_SNAPSHOT}-ubuntu14.04.tar.gz"
sudo rm -rf /swift
sudo mv "${SWIFT_SNAPSHOT}-ubuntu14.04" /swift

echo "Installing XCTest..."
if [ ! -f "${XCTEST_SNAPSHOT}.tar.gz" ]; then
  curl -s -L -O "https://github.com/apple/swift-corelibs-xctest/archive/${XCTEST_SNAPSHOT}.tar.gz"
fi
tar -zxvf "${XCTEST_SNAPSHOT}.tar.gz"
cd "swift-corelibs-xctest-${XCTEST_SNAPSHOT}"
sudo ./build_script.py --swiftc="/swift/usr/bin/swiftc" --build-dir="/tmp/XCTest_build" --foundation-build-dir="/swift/usr/lib/swift/linux" --library-install-path="/swift/usr/lib/swift/linux" --module-install-path="/swift/usr/lib/swift/linux/x86_64"
cd ..
rm -rf "swift-corelibs-xctest-${XCTEST_SNAPSHOT}"
