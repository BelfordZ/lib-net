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