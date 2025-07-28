// swift-tools-version: 6.1

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
]

let package = Package(
    name: "LicenseList",
    platforms: [
        .iOS(.v16),
        .tvOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "LicenseList",
            targets: ["LicenseList"]
        ),
    ],
    targets: [
        .target(
            name: "LicenseList",
            resources: [
                .process("licenses.json")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "LibraryTests",
            dependencies: ["LicenseList"],
            path: "Tests/SourcePackagesParserTests",
            swiftSettings: swiftSettings
        )
    ]
)
