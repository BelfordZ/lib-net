# Native Module Build Process

## Current Setup (Updated)
1. Using `neon` for Rust bindings
2. Using `node-pre-gyp` for binary distribution
3. Standard build process with correct directory structure

## Changes Made
1. Fixed `binding.gyp` configuration:
   - Removed incorrect neon dependency
   - Added proper source file reference
   - Simplified configuration
2. Updated `package.json`:
   - Build rust from correct directory (shardus_net)
   - Copy built module to correct location
   - Maintain proper directory structure
   - Removed scripts directory from package files
3. Build Process Flow:
   ```bash
   cd shardus_net          # Go to Rust project directory
   neon build --release    # Build the native module
   cd ..                   # Return to root
   mkdir -p native        # Ensure native directory exists
   cp shardus_net/index.node native/  # Copy to expected location
   ```

## Directory Structure
```
lib-net/
├── shardus_net/         # Rust project directory
│   ├── Cargo.toml
│   ├── src/
│   └── index.node       # Built by neon
├── native/             # node-pre-gyp expects modules here
│   └── index.node      # Copied from shardus_net
├── binding.gyp
└── package.json
```

## Package Contents
The following are included in the published package:
1. Source files:
   - src/**/*
   - Cargo.*
   - shardus_net/**/*
   - crypto/**/*
   - shardeum_utils/**/*
2. Build artifacts:
   - build/**/*
   - native/**/*
3. Configuration:
   - package.json
   - binding.gyp

## Build Process Flow
1. Development Build:
   ```bash
   npm install        # Installs dependencies and builds
   npm run build     # Builds both Rust and TypeScript
   ```

2. Production Build (via GitHub Actions):
   - Checkout code
   - Install dependencies
   - Build native module in shardus_net directory
   - Copy to correct location
   - Package with node-pre-gyp
   - Upload to GitHub releases

## Debugging
If build issues occur:
1. Check `shardus_net/index.node` exists after build
2. Verify copy to `native/` directory
3. Use `npm run clean` to clean all build artifacts
4. Run `npm run build-rust` to build only native code
5. Check neon build output for errors

## References
- [Neon Build Process](https://neon-bindings.com/docs/building)
- [node-pre-gyp Documentation](https://github.com/mapbox/node-pre-gyp) 