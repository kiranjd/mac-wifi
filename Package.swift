// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MacWiFi",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MacWiFi", targets: ["MacWiFi"])
    ],
    targets: [
        .executableTarget(
            name: "MacWiFi",
            linkerSettings: [
                .linkedFramework("CoreWLAN"),
                .linkedFramework("CoreLocation")
            ]
        )
    ]
)
