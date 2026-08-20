// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Monk",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MonkCore", targets: ["MonkCore"]),
        .executable(name: "MonkCoreVerification", targets: ["MonkCoreVerification"]),
    ],
    targets: [
        .target(name: "MonkCore", path: "Sources/MonkCore"),
        .executableTarget(name: "MonkCoreVerification", dependencies: ["MonkCore"], path: "Verification"),
    ]
)
