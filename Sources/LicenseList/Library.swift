import Foundation

/// A structure that contains information about a library that the project depends on.
public struct Library: Identifiable, Hashable, Sendable, Codable {
    /// The unique identifier.
    public var id: UUID = .init()
    /// The library name.
    public let name: String
    /// The repository url string.
    public let url: String
    /// The license body.
    public let licenseBody: String
    
    /// The repository URL as a URL object.
    public var repositoryURL: URL? { URL(string: url) }

    /// - Parameters:
    ///   - name: The library name.
    ///   - url: The repository url.
    ///   - licenseBody: The license body.
    public init(name: String, url: String, licenseBody: String) {
        self.name = name
        self.url = url
        self.licenseBody = licenseBody
    }
    
    private enum CodingKeys: String, CodingKey {
        case name, url, licenseBody
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        url = try container.decode(String.self, forKey: .url)
        licenseBody = try container.decode(String.self, forKey: .licenseBody)
        id = UUID()
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(url, forKey: .url)
        try container.encode(licenseBody, forKey: .licenseBody)
    }
}

extension Library {
    /// The libraries loaded from the generated licenses file.
    /// If no licenses file is found, returns an empty array.
    public static let libraries: [Library] = {
        loadLibraries()
    }()
    
    private static func loadLibraries() -> [Library] {
        // Try to find licenses.json in the bundle
        guard let bundleURL = Bundle.module.url(forResource: "licenses", withExtension: "json"),
              let data = try? Data(contentsOf: bundleURL),
              let libraries = try? JSONDecoder().decode([Library].self, from: data) else {
            
            // Fallback: try to find licenses.json in the source directory (for development)
            let currentFileURL = URL(filePath: #file)
            let sourceDirectory = currentFileURL.deletingLastPathComponent()
            let licensesURL = sourceDirectory.appending(path: "licenses.json")
            
            if let data = try? Data(contentsOf: licensesURL),
               let libraries = try? JSONDecoder().decode([Library].self, from: data) {
                return libraries
            }
            
            #if DEBUG
            print("Warning: No licenses.json file found. Run generate-licenses.swift to create one.")
            #endif
            return []
        }
        
        return libraries
    }
}
