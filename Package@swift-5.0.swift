// swift-tools-version:5.0

import PackageDescription

var packageDependencies: [Package.Dependency] {
    
    var dependencies: [Package.Dependency] = [
        .package(
            // name: "RegularExpressions",
            url: "https://github.com/Peter-Schorn/RegularExpressions.git",
            from: "2.2.0"
        ),
        .package(
            // name: "swift-log",
            url: "https://github.com/apple/swift-log.git",
            from: "1.4.0"
        ),
        .package(
            // name: "OpenCombine",
            url: "https://github.com/OpenCombine/OpenCombine.git",
            from: "0.12.0"
        )
    ]
    
    return dependencies
    
}

var spotifyAPITestUtilitiesDependencies: [Target.Dependency] {
    
    var dependencies: [Target.Dependency] = [
        "SpotifyWebAPI",
        "SpotifyExampleContent",
        .product(name: "RegularExpressions", package: "RegularExpressions"),
        .product(name: "OpenCombine", package: "OpenCombine"),
        .product(name: "OpenCombineDispatch", package: "OpenCombine"),
        .product(name: "OpenCombineFoundation", package: "OpenCombine")
    ]
    
    return dependencies
    
}

var spotifyWebAPIDependencies: [Target.Dependency] {
    
    var dependencies: [Target.Dependency] = [
        .product(name: "RegularExpressions", package: "RegularExpressions"),
        .product(name: "Logging", package: "swift-log"),
        .product(name: "OpenCombine", package: "OpenCombine"),
        .product(name: "OpenCombineDispatch", package: "OpenCombine"),
        .product(name: "OpenCombineFoundation", package: "OpenCombine")
    ]

    return dependencies

}

var supportedPlatforms: [SupportedPlatform] {
    #if canImport(Combine)
    return [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .watchOS(.v6)]
    #else
    return [.iOS(.v11), .macOS(.v10_13), .tvOS(.v11), .watchOS(.v4)]
    #endif
}

let package = Package(
    name: "SpotifyAPI",
    platforms: supportedPlatforms,
    products: [
        .library(
            name: "SpotifyAPI",
            targets: ["SpotifyWebAPI", "SpotifyExampleContent"]
        ),
        .library(
            name: "_SpotifyAPITestUtilities",
            targets: ["SpotifyAPITestUtilities"]
        )
    ],
    dependencies: packageDependencies,
    targets: [
        .target(
            name: "SpotifyWebAPI",
            dependencies: spotifyWebAPIDependencies,
            exclude: ["README.md"]
        ),
        .target(
            name: "SpotifyExampleContent",
            dependencies: ["SpotifyWebAPI"],
            exclude: ["README.md"]
            // resources: [
            //     .process("Resources")
            // ],
        ),
        .target(
            name: "SpotifyAPITestUtilities",
            dependencies: spotifyAPITestUtilitiesDependencies
            // exclude: ["README.md"]
        ),
        
        // MARK: Test Targets
        
        .testTarget(
            name: "SpotifyAPIMainTests",
            dependencies: [
                "SpotifyWebAPI",
                "SpotifyExampleContent",
                "RegularExpressions",
                "SpotifyAPITestUtilities"
            ]
        )
    ]
)