// swift-tools-version:5.9
import PackageDescription

// This manifest sits at the REPOSITORY ROOT, not in ios/, and it has to.
//
// Swift Package Manager resolves a package by cloning a repository and reading
// Package.swift at its top level. There is no way to point it at a
// subdirectory — so a manifest living in ios/ would build fine on a developer's
// machine and then fail for every consumer who followed our own install
// instructions. The target paths reach into ios/ instead.
//
// No `dependencies:` anywhere in this file, and there never will be. An SDK a
// small business drops into their app must not drag trackers or a networking
// library in behind it; WKWebView is the only thing this package needs.
let package = Package(
    name: "TelyBot",
    platforms: [
        // UIKit + WKWebView presented as a sheet. iOS 15: Xcode 27 builds nothing
        // older (an iOS 13 minimum is an error there, in a CocoaPods build at
        // least), and the App Store has required Xcode 26, iOS 15 and up, since
        // April 2026.
        .iOS(.v15)
    ],
    products: [
        .library(name: "TelyBot", targets: ["TelyBot"]),
        // The 0.x product name, deprecated: re-exports TelyBot and aliases the old
        // type names (ios/Sources/KeydaBot). Removed in 2.0.0.
        .library(name: "KeydaBot", targets: ["KeydaBot"])
    ],
    targets: [
        // The privacy manifest ships inside the package (as a resource bundle),
        // which is where Xcode's privacy report looks for a dependency's.
        .target(
            name: "TelyBot",
            path: "ios/Sources/TelyBot",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .target(name: "KeydaBot", dependencies: ["TelyBot"], path: "ios/Sources/KeydaBot"),
        // Pure unit tests over client-id validation, URL building and the
        // stays-in-chat rule — no simulator, no host app. `swift test` runs
        // them on the machine you are sitting at.
        .testTarget(name: "TelyBotTests", dependencies: ["TelyBot"], path: "ios/Tests/TelyBotTests")
    ]
)
