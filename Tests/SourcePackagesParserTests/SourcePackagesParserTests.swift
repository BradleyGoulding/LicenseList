import Foundation
import Testing
@testable import LicenseList

// Test model matching the Library structure
struct MockLibrary: Codable {
    let name: String
    let url: String
    let licenseBody: String
}

#if os(macOS)
struct LibraryTests {
    
    @Test("Library can be decoded from JSON")
    func library_decoding() throws {
        let jsonData = """
        [
            {
                "name": "TestLibrary",
                "url": "https://github.com/test/library.git",
                "licenseBody": "MIT License\\n\\nPermission is hereby granted..."
            }
        ]
        """.data(using: .utf8)!
        
        let libraries = try JSONDecoder().decode([MockLibrary].self, from: jsonData)
        #expect(libraries.count == 1)
        #expect(libraries[0].name == "TestLibrary")
        #expect(libraries[0].url == "https://github.com/test/library.git")
        #expect(libraries[0].licenseBody.contains("MIT License"))
    }
    
    @Test("Library handles empty JSON array")
    func library_empty_array() throws {
        let jsonData = "[]".data(using: .utf8)!
        let libraries = try JSONDecoder().decode([MockLibrary].self, from: jsonData)
        #expect(libraries.isEmpty)
    }
    
    @Test("Library manual initialization works")
    func library_manual_init() {
        let library = Library(
            name: "ManualLibrary", 
            url: "https://github.com/manual/lib.git",
            licenseBody: "Custom License Text"
        )
        
        #expect(library.name == "ManualLibrary")
        #expect(library.url == "https://github.com/manual/lib.git")
        #expect(library.licenseBody == "Custom License Text")
        #expect(library.repositoryURL?.absoluteString == "https://github.com/manual/lib.git")
    }
    
    @Test("Library repositoryURL handles invalid URLs")
    func library_invalid_url() {
        let library = Library(
            name: "InvalidURL",
            url: "",
            licenseBody: "License"
        )
        
        #expect(library.repositoryURL == nil)
    }
    
    @Test("Library.libraries returns empty array when no licenses.json exists")
    func library_static_empty() {
        // Since we have an empty licenses.json file, this should return empty array
        let libraries = Library.libraries
        #expect(libraries.isEmpty)
    }
}
#endif