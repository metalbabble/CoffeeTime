// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CoffeeTime",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "CoffeeTime", targets: ["CoffeeTime"])
    ],
    targets: [
        .executableTarget(
            name: "CoffeeTime",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("IOKit")
            ]
        )
    ]
)
