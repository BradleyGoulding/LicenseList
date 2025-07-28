# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LicenseList is a Swift Package Manager library that automatically generates license lists for iOS/tvOS/macOS applications by parsing Swift Package dependencies. It provides both SwiftUI and UIKit interfaces for displaying license information to users.

**This is a Fork:** This repository is forked from the original cybozu/LicenseList to enable the `PrepareLicenseList` plugin to work in Xcode projects and Xcode Cloud. The original plugin only supported Swift Package Manager projects.

## Build System & Commands

**Swift Package Manager Commands:**
- Build: `swift build`
- Test: `swift test` (macOS only - tests require access to built products)
- Build Examples: Open `Examples/Examples.xcodeproj` in Xcode
- Run single test: `swift test --filter <test_name>`

**Package Structure:**
- Main library target: `LicenseList`
- Parser executable: `spp` (SourcePackagesParser)
- Build plugin: `PrepareLicenseList`
- Platform support: iOS 16.0+, tvOS 17.0+, macOS 14.0+
- Swift version: 6.1 with `ExistentialAny` feature enabled

## Architecture Overview

**Core Components:**

1. **LicenseList Module** (`Sources/LicenseList/`):
   - `Library.swift` - Public API model wrapping internal SPPLibrary
   - `LicenseListView.swift` - SwiftUI list view
   - `LicenseListViewController.swift` - UIKit wrapper using UIHostingController
   - `LicenseView.swift` - Individual license display view
   - Style system with `LicenseListViewStyle` and `LicenseViewStyle` protocols

2. **SourcePackagesParser Module** (`Sources/SourcePackagesParser/`):
   - `SourcePackagesParser.swift` - Core parser that reads workspace-state.json
   - `Library.swift` - Internal library model
   - `WorkspaceState.swift` - JSON model for Swift Package Manager metadata
   - `main.swift` - CLI entry point for the `spp` executable

3. **Build Plugin** (`Plugins/PrepareLicenseList/`):
   - Automatically runs during build to generate `LicenseList.swift`
   - Searches project hierarchy for `SourcePackages` directory
   - Generates enum cases for each dependency with license text

**Data Flow:**
1. Build plugin locates `SourcePackages/workspace-state.json`
2. Parser extracts dependency info and license files
3. Generated `SPPLibrary` enum contains all license data at compile time
4. Public `Library` struct provides clean API over generated cases
5. Views consume `Library.libraries` static array

## Development Patterns

**Style System:**
- Uses SwiftUI environment values for styling (`@Environment(\.licenseListViewStyle)`)
- Supports `.automatic`, `.withRepositoryAnchorLink` styles
- Both view styles follow protocol-based configuration pattern

**Plugin Integration:**
- The `PrepareLicenseList` plugin runs automatically during builds
- Searches parent directories for `SourcePackages` folder
- Outputs generated Swift code to plugin work directory

**Testing:**
- Tests only run on macOS due to executable access requirements
- Uses Swift Testing framework (not XCTest)
- Tests validate parser behavior with fixture data in `Tests/SourcePackagesParserTests/Resources/`

**File Organization:**
- Separate internal models (`SourcePackagesParser/Library`) from public API (`LicenseList/Library`)
- Extensions organized by functionality (String, URL, Array, etc.)
- Documentation via Swift-DocC in `Sources/LicenseList/Documentation.docc/`

## Fork-Specific Changes

**Xcode Project Plugin Support:**
- Modified `Plugins/PrepareLicenseList/main.swift` to support both SwiftPM and Xcode projects
- Added conditional `XcodeProjectPlugin` conformance with `#if canImport(XcodeProjectPlugin)`
- Plugin now works in Xcode Cloud and can be invoked from Xcode project build phases
- Maintains backward compatibility with Swift Package Manager projects

**Plugin Usage in Xcode:**
- The plugin appears in Xcode's "Add Build Tool Plug-in" dialog
- Can be added to target build phases to automatically generate license lists during builds
- No longer limited to Swift Package Manager-only environments