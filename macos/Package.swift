// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Cued",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "Cued", targets: ["CuedMac"])],
    targets: [
        .target(name: "CuedCore", resources: [.process("Resources")]),
        .executableTarget(name: "CuedMac", dependencies: ["CuedCore"]),
        .testTarget(name: "CuedCoreTests", dependencies: ["CuedCore"])
    ]
)
