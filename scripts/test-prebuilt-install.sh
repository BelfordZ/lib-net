#!/bin/bash
set -e

# Usage info
show_help() {
  echo "Usage: $0 [-v version_tag] [-p platform] [-t test_dir]"
  echo
  echo "Test installation of prebuilt binaries for @shardus/net"
  echo
  echo "Options:"
  echo "  -v  Version tag to test (e.g., v1.4.33)"
  echo "  -p  Platform to test for (linux, win32, darwin)"
  echo "  -t  Test directory (default: ./test-install)"
  echo "  -h  Show this help message"
  exit 1
}

# Default values
VERSION_TAG=""
PLATFORM=$(case "$(uname -s)" in
    Linux*)     echo "linux";;
    Darwin*)    echo "darwin";;
    MINGW*|MSYS*) echo "win32";;
    *)          echo "unknown";;
esac)
TEST_DIR="./test-install"

# Parse arguments
while getopts "v:p:t:h" opt; do
  case $opt in
    v) VERSION_TAG="$OPTARG";;
    p) PLATFORM="$OPTARG";;
    t) TEST_DIR="$OPTARG";;
    h) show_help;;
    *) show_help;;
  esac
done

# Validate inputs
if [ -z "$VERSION_TAG" ]; then
  echo "Error: Version tag is required"
  show_help
fi

if [ "$PLATFORM" = "unknown" ]; then
  echo "Error: Could not determine platform"
  exit 1
fi

# Create test directory
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "=== Creating Test Project ==="
# Create package.json
cat > package.json << EOF
{
  "name": "test-project",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "@shardus/net": "$VERSION_TAG"
  }
}
EOF

# Create test file
cat > test.js << EOF
const shardusNet = require("@shardus/net");
console.log("Successfully imported @shardus/net");
console.log("Module exports:", Object.keys(shardusNet));
EOF

echo "=== Environment Setup ==="
echo "Node version: $(node --version)"
echo "NPM version: $(npm --version)"
echo "Working directory: $(pwd)"
echo "Platform: $PLATFORM"
echo "Testing version: $VERSION_TAG"

echo "Package.json contents:"
cat package.json
echo "=== .npmrc contents ==="
cat .npmrc

echo -e "\n=== Starting Installation ==="
# Start timing
INSTALL_START=$(date +%s)

# First try just showing what npm would do
echo -e "\n=== NPM Install Plan ==="
npm install --dry-run || true

echo -e "\n=== Actual Installation ==="
# Capture npm install output
NPM_OUTPUT=$(NPM_CONFIG_LOGLEVEL=verbose npm install 2>&1)
NPM_EXIT_CODE=$?

# End timing
INSTALL_END=$(date +%s)
INSTALL_DURATION=$((INSTALL_END-INSTALL_START))

echo -e "\n=== Full NPM Output ==="
echo "$NPM_OUTPUT"

echo -e "\n=== Installation Analysis ==="
echo "Installation took $INSTALL_DURATION seconds"
echo "Exit code: $NPM_EXIT_CODE"

echo -e "\n=== Looking for compilation indicators ==="
if echo "$NPM_OUTPUT" | grep -iE "cargo|rustc|building|compiling"; then
  echo "❌ Found compilation-related messages (see above)"
  exit 1
else
  echo "✅ No compilation indicators found"
fi

echo -e "\n=== Looking for download indicators ==="
if echo "$NPM_OUTPUT" | grep -iE "downloaded|tarball|prebuilt"; then
  echo "✅ Found download indicators"
  echo "Matching lines:"
  echo "$NPM_OUTPUT" | grep -iE "downloaded|tarball|prebuilt"
else
  echo "❌ No download indicators found"
  exit 1
fi

echo -e "\n=== Checking installation time ==="
if [ $INSTALL_DURATION -gt 30 ]; then
  echo "❌ Installation took $INSTALL_DURATION seconds (too long)"
  exit 1
else
  echo "✅ Installation completed in reasonable time"
fi

echo -e "\n=== Checking installation result ==="
if [ $NPM_EXIT_CODE -ne 0 ]; then
  echo "❌ Installation failed with exit code $NPM_EXIT_CODE"
  exit 1
else
  echo "✅ Installation succeeded"
fi

echo -e "\n=== Verifying Binary Installation ==="
echo "Checking for prebuilt binary..."
ls -R node_modules/@shardus/net/native

# Verify we have the correct platform binary
if [ ! -f "node_modules/@shardus/net/native/$PLATFORM-x64/shardus-net.node" ]; then
  echo "❌ Error: Platform-specific binary not found!"
  exit 1
fi

echo -e "\n=== Checking for Build Artifacts ==="
# Check for any build artifacts that would indicate compilation
if [ -d "node_modules/@shardus/net/build" ]; then
  echo "❌ Error: Build directory found, suggesting compilation occurred"
  exit 1
fi

if [ -f "node_modules/@shardus/net/build.log" ]; then
  echo "❌ Error: Build log found, suggesting compilation occurred"
  exit 1
fi

# Check for any cargo/rust artifacts
if find . -type f -name "Cargo.lock" -o -name "target" -o -name ".cargo" | grep .; then
  echo "❌ Error: Found Rust/Cargo artifacts suggesting compilation"
  exit 1
fi

echo -e "\n=== Testing Import ==="
node test.js

echo -e "\n=== Installation Summary ==="
echo "✅ Successfully tested @shardus/net $VERSION_TAG on $PLATFORM"
echo "   ✓ Package installed WITHOUT any compilation"
echo "   ✓ No build artifacts found (pure prebuilt binary usage)"
echo "   ✓ Correct platform-specific binary present"
echo "   ✓ Module successfully imported and tested" 