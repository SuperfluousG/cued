// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CuedMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Cued", targets: ["CuedMac"])
    ],
    targets: [
        .executableTarget(
            name: "CuedMac",
            resources: [
                .copy("Resources")
            ]
        ),
        .testTarget(
            name: "CuedMacTests",
            dependencies: ["CuedMac"]
        )
    ]
)
