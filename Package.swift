// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Poco",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "Poco",
            path: "Sources/Poco",
            resources: [
                .copy("Resources")
            ],
            swiftSettings: [
                .unsafeFlags(["-framework", "Carbon"])
            ],
            linkerSettings: [
                .linkedFramework("Carbon"),
                .linkedFramework("AppKit"),
                .linkedFramework("CoreData")
            ]
        )
    ]
)
