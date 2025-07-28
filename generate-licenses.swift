#!/usr/bin/env swift

import Foundation

// MARK: - Models

struct Library: Codable {
    let name: String
    let url: String
    let licenseBody: String
}

struct WorkspaceState: Codable {
    let object: WorkspaceStateObject
}

struct WorkspaceStateObject: Codable {
    let dependencies: [Dependency]
}

struct Dependency: Codable {
    let packageRef: PackageRef
}

struct PackageRef: Codable {
    let location: String
    let name: String
}

enum GenerationError: Error, CustomStringConvertible {
    case couldNotReadFile(String)
    case couldNotWriteFile(String)
    case sourcePackagesNotFound
    case invalidArguments
    
    var description: String {
        switch self {
        case .couldNotReadFile(let fileName):
            return "Error: Could not read \(fileName)"
        case .couldNotWriteFile(let fileName):
            return "Error: Could not write \(fileName)"
        case .sourcePackagesNotFound:
            return "Error: SourcePackages directory not found"
        case .invalidArguments:
            return "USAGE: swift generate-licenses.swift [output-file] [source-packages-path]"
        }
    }
}

// MARK: - License Generator

final class LicenseGenerator {
    let outputURL: URL
    let sourcePackagesURL: URL
    
    init(outputPath: String, sourcePackagesPath: String) {
        outputURL = URL(filePath: outputPath)
        sourcePackagesURL = URL(filePath: sourcePackagesPath)
    }
    
    func run() throws {
        print("🔍 Searching for licenses in: \(sourcePackagesURL.path())")
        
        // Load workspace-state.json
        let workspaceStateURL = sourcePackagesURL.appending(path: "workspace-state.json")
        guard let data = try? Data(contentsOf: workspaceStateURL),
              let workspaceState = try? JSONDecoder().decode(WorkspaceState.self, from: data) else {
            throw GenerationError.couldNotReadFile(workspaceStateURL.lastPathComponent)
        }
        
        // Extract Libraries
        let checkoutsURL = sourcePackagesURL.appending(path: "checkouts")
        let libraries: [Library] = workspaceState.object.dependencies.compactMap { dependency in
            let repositoryName = dependency.packageRef.location
                .components(separatedBy: "/").last!
                .replacingOccurrences(of: ".git", with: "")
            let directoryURL = checkoutsURL.appending(path: repositoryName)
            guard let licenseBody = extractLicenseBody(directoryURL) else {
                print("⚠️  No license found for: \(dependency.packageRef.name)")
                return nil
            }
            print("✅ Found license for: \(dependency.packageRef.name)")
            return Library(
                name: dependency.packageRef.name,
                url: dependency.packageRef.location,
                licenseBody: licenseBody
            )
        }
        .sorted { $0.name.lowercased() < $1.name.lowercased() }
        
        // Export licenses as JSON
        try exportLicenses(libraries)
        
        print("📝 Generated \(libraries.count) licenses to: \(outputURL.path())")
    }
    
    private func extractLicenseBody(_ directoryURL: URL) -> String? {
        let fm = FileManager.default
        let contents = (try? fm.contentsOfDirectory(atPath: directoryURL.path())) ?? []
        let licenseURL = contents
            .map { directoryURL.appending(path: $0) }
            .filter { contentURL in
                let fileName = contentURL.deletingPathExtension().lastPathComponent.lowercased()
                guard ["license", "licence"].contains(fileName) else {
                    return false
                }
                var isDirectory: ObjCBool = false
                fm.fileExists(atPath: contentURL.path(), isDirectory: &isDirectory)
                return isDirectory.boolValue == false
            }
            .first
        guard let licenseURL, let text = try? String(contentsOf: licenseURL) else {
            return nil
        }
        return text
    }
    
    private func exportLicenses(_ libraries: [Library]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        guard let data = try? encoder.encode(libraries) else {
            throw GenerationError.couldNotWriteFile(outputURL.lastPathComponent)
        }
        
        // Ensure output directory exists
        let outputDirectory = outputURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        
        // Remove existing file if it exists
        if FileManager.default.fileExists(atPath: outputURL.path()) {
            try FileManager.default.removeItem(at: outputURL)
        }
        
        // Write the data
        do {
            try data.write(to: outputURL)
        } catch {
            throw GenerationError.couldNotWriteFile(outputURL.lastPathComponent)
        }
    }
}

// MARK: - Main

func findSourcePackages(startingFrom url: URL) -> URL? {
    var currentURL = url.absoluteURL
    
    while currentURL.pathComponents.count > 1 {
        let sourcePackagesURL = currentURL.appending(path: "SourcePackages")
        if FileManager.default.fileExists(atPath: sourcePackagesURL.path()) {
            return sourcePackagesURL
        }
        currentURL.deleteLastPathComponent()
    }
    
    return nil
}

func main() {
    let arguments = CommandLine.arguments
    
    // Get SRCROOT from environment (Xcode provides this)
    let srcRoot = ProcessInfo.processInfo.environment["SRCROOT"] ?? FileManager.default.currentDirectoryPath
    let srcRootURL = URL(filePath: srcRoot)
    
    let outputPath: String
    let sourcePackagesPath: String
    
    if arguments.count == 1 {
        // No arguments - use Xcode defaults
        outputPath = srcRootURL.appending(path: "licenses.json").path()
        
        // Look for SourcePackages in SRCROOT
        let sourcePackagesURL = srcRootURL.appending(path: "SourcePackages")
        if FileManager.default.fileExists(atPath: sourcePackagesURL.path()) {
            sourcePackagesPath = sourcePackagesURL.path()
        } else {
            // No SourcePackages - create empty licenses file
            print("No SourcePackages found, creating empty license list")
            do {
                try "[]".write(to: URL(filePath: outputPath), atomically: true, encoding: .utf8)
                print("Created empty license list at \(outputPath)")
            } catch {
                print("Error creating empty license file: \(error)")
                exit(1)
            }
            exit(0)
        }
        
    } else if arguments.count == 2 {
        // One argument - custom output path, auto-discover SourcePackages
        outputPath = arguments[1]
        guard let sourcePackages = findSourcePackages(startingFrom: srcRootURL) else {
            print(GenerationError.sourcePackagesNotFound.description)
            exit(1)
        }
        sourcePackagesPath = sourcePackages.path()
        
    } else if arguments.count == 3 {
        // Two arguments - explicit paths
        outputPath = arguments[1]
        sourcePackagesPath = arguments[2]
        
    } else {
        print(GenerationError.invalidArguments.description)
        print("\nExamples:")
        print("  swift generate-licenses.swift                           # Auto-discover, output to ./licenses.json")
        print("  swift generate-licenses.swift custom/path.json          # Custom output, auto-discover SourcePackages")
        print("  swift generate-licenses.swift output.json ./SourcePackages  # Explicit paths")
        exit(1)
    }
    
    do {
        try LicenseGenerator(outputPath: outputPath, sourcePackagesPath: sourcePackagesPath).run()
    } catch {
        if let generationError = error as? GenerationError {
            print(generationError.description)
        } else {
            print("Unexpected error: \(error)")
        }
        exit(1)
    }
}

main()