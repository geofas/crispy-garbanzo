// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "NudgyKit",
    platforms: [.iOS(.v17), .watchOS(.v10), .macOS(.v14)],
    products: [
        .library(name: "NudgyKit", targets: ["NudgyKit"])
    ],
    targets: [
        .target(name: "NudgyKit"),
        .testTarget(name: "NudgyKitTests", dependencies: ["NudgyKit"])
    ]
)
