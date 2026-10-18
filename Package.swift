// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Pluma",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Pluma", targets: ["Pluma"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Pluma",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "PlumaTests",
            dependencies: ["Pluma"],
            path: "Tests/PlumaTests"
        )
    ]
)
