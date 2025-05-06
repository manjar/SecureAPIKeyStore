// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SecureAPIKeyStore",
    platforms: [
        .iOS(.v16),       // or .v14 if you're targeting newer APIs
        .macOS(.v12),
        .watchOS(.v6),
        .tvOS(.v13)
    ],
    products: [
        .library(name: "SecureAPIKeyStore", targets: ["SecureAPIKeyStore"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "SecureAPIKeyStore", dependencies: [], path: "Sources/SecureAPIKeyStore"),
        .testTarget(name: "SecureAPIKeyStoreTests", dependencies: ["SecureAPIKeyStore"]),
    ]
)
