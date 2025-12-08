// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "voicescribe",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "voicescribe",
            targets: ["voicescribe"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/amplify-aws/amplify-swift.git", from: "2.0.0"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.6.0")
    ],
    targets: [
        .executableTarget(
            name: "voicescribe",
            dependencies: [
                .product(name: "Amplify", package: "amplify-swift"),
                .product(name: "AWSCognitoAuthPlugin", package: "amplify-swift"),
                .product(name: "Alamofire", package: "Alamofire")
            ]
        ),
    ]
)
