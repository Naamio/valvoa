// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Valvoa",
    products: [
        .library(
            name: "Valvoa",
            targets: ["Valvoa"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Valvoa",
            dependencies: []),
        .testTarget(
            name: "ValvoaTests",
            dependencies: ["Valvoa"]),
    ]
)
