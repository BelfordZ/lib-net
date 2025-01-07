# Build and Release Process Notes

## Release Workflow Structure
- The release process is managed through GitHub Actions (`.github/workflows/release.yml`)
- Consists of multiple jobs:
  1. create-release: Handles version bumping and release creation
  2. build-typescript: Builds and packages TypeScript artifacts
  3. build-native: Builds native binaries for multiple platforms

## Known Issues
1. Native Binary Packaging Issue (2024-03-xx)
   - Error: `Cannot package because /native/linux-x64/shardus-net.node missing`
   - Root cause: The build process is not properly generating the native node module before packaging
   - Fix: Added explicit `node-pre-gyp rebuild` step before packaging in the release workflow
   - Proper build sequence: build-rust-release → node-pre-gyp rebuild → package

## Build Process Requirements
1. Native Build Prerequisites:
   - Rust toolchain
   - Node.js build tools
   - Platform-specific dependencies (e.g., build-essential on Ubuntu)

## Build Steps (Correct Order)
1. Install dependencies: `npm ci`
2. Build Rust: `npm run build-rust-release`
3. Rebuild native module: `node-pre-gyp rebuild`
4. Package binary: `npm run package-binary` 