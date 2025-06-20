// swift-tools-version: 6.0

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
        .plugin(
            name: "PrepareLicenseList",
            targets: ["PrepareLicenseList"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "spp",
            path: "Sources/SourcePackagesParser",
            swiftSettings: swiftSettings
        ),
        .plugin(
            name: "PrepareLicenseList",
            capability: .buildTool(),
            dependencies: [.target(name: "spp")]
        ),
        .testTarget(
            name: "SourcePackagesParserTests",
            dependencies: [
                .target(name: "spp", condition: .when(platforms: [.macOS]))
            ],
            resources: [
                .copy("Resources/Broken"),
                .copy("Resources/Empty"),
                .copy("Resources/SourcePackages"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "LicenseList",
            swiftSettings: swiftSettings,
            plugins: ["PrepareLicenseList"]
        )
    ]
)
