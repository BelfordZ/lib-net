# Build and Release Process Notes

## Release Workflow Structure
- The release process is managed through GitHub Actions (`.github/workflows/release.yml`)
- Consists of multiple jobs:
  1. create-release: Handles version bumping and release creation
  2. build-typescript: Builds and packages TypeScript artifacts
  3. build-native: Builds native binaries for multiple platforms

## Native Module Structure
- The native module must be placed in a specific directory structure for node-pre-gyp
- Structure: `native/{platform}-{arch}/shardus-net.node`
  - Platform: linux, win32, or darwin
  - Arch: x64 (currently only supporting 64-bit)
- Example: `native/linux-x64/shardus-net.node`

## Build Process Investigation
1. Current Understanding:
   - `build-rust` script uses cargo-cp-artifact to copy to `native/shardus-net.node`
   - node-pre-gyp expects files in `native/{platform}-{arch}/`
   - Need to verify actual file locations during build process
2. Questions to Answer:
   - Where does cargo-cp-artifact actually place the built module?
   - Is the module being built with the correct name?
   - Are we correctly handling platform-specific paths?

## Known Issues
1. Native Binary Packaging Issue (2024-03-xx)
   - Error: `Cannot package because /native/linux-x64/shardus-net.node missing`
   - Root cause: Investigating file locations in build process
   - Status: Added debugging steps to verify file locations
   - Current sequence: build-rust-release → debug locations → move to platform directory → package

## Build Process Requirements
1. Native Build Prerequisites:
   - Rust toolchain
   - Node.js build tools
   - Platform-specific dependencies (e.g., build-essential on Ubuntu)
   - node-pre-gyp (installed as local dependency)

## Build Steps (Under Investigation)
1. Install dependencies: `npm ci`
2. Build Rust: `npm run build-rust-release`
3. Debug file locations: Check where files are actually being placed
4. Move to platform directory: `mkdir -p native/{platform}-x64 && mv native/shardus-net.node native/{platform}-x64/`
5. Package binary: `npm run package-binary` 

## Binary Packaging Configuration

The project uses node-pre-gyp for binary packaging with the following configuration:
- module_name: shardus-net
- module_path: native/{platform}-{arch}/
- package_name: {module_name}-v{version}-{node_abi}-{platform}-{arch}.tar.gz

### Release Workflow Issue (2024-03)
The GitHub Actions release workflow was failing because it was looking for the packaged binary in `./build/stage/*.tar.gz`, but node-pre-gyp likely generates it in a different location based on its configuration.

Potential fixes:
1. Update the upload step to use the correct path pattern that matches node-pre-gyp's output
2. Add a debug step to locate the generated .tar.gz file
3. Consider using wildcards to find the file regardless of its exact name 

### Implemented Solution
The workflow has been updated to:
1. Add a debug step to list all .tar.gz files in the workspace
2. Dynamically find the correct tarball path using `find`
3. Use the found path in the upload step instead of a hardcoded location

This makes the release process more robust by:
- Not assuming a specific output location
- Providing better debugging information
- Handling different possible output locations from node-pre-gyp

### File Location Discovery (2024-03)
- Actual file location: `./build/stage/v{version}/shardus-net-v{version}-node-v{node_abi}-{platform}-x64.tar.gz`
- Example: `./build/stage/v1.4.31/shardus-net-v1.4.31-node-v108-linux-x64.tar.gz`
- Fixed workflow step ordering to ensure file path is found before upload attempt

### Windows Build Support (2024-03)
Added Windows-specific configurations:
1. System Dependencies:
   - OpenSSL via Chocolatey
   - LLVM via Chocolatey
2. Build Adjustments:
   - PowerShell for Windows-specific commands
   - Bash shell for cross-platform file operations
   - Modified PATH handling for Rust toolchain
3. Key Considerations:
   - Platform identifier: win32
   - Architecture: x64
   - Native module path: `native/win32-x64/shardus-net.node`

### Release Testing Workflow (2024-03)
Added a new workflow (`test-release.yml`) to verify released packages:
1. Test Scope:
   - Strict prebuilt binary verification
   - Fails if Rust toolchain is present
   - Fails if any compilation occurs
   - Fails if build artifacts are found
   - Verifies module import functionality
2. Platform Coverage:
   - Linux (ubuntu-latest)
   - Windows (windows-latest)
   - macOS (macos-latest)
3. Test Process:
   - Creates a clean test project
   - Enforces node-pre-gyp-only mode
   - Verifies absence of Rust toolchain
   - Checks for absence of build artifacts
   - Validates correct binary installation
   - Tests module importability
4. Usage:
   - Manually triggered via GitHub Actions
   - Requires version/tag parameter (e.g., v1.4.33)
   - Reports detailed success/failure for each platform
5. Success Criteria:
   - No Rust toolchain present
   - No compilation attempted
   - No build artifacts created
   - Correct prebuilt binary present
   - Module imports successfully 