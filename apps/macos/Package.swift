// swift-tools-version: 5.9
import PackageDescription

// The Rust static lib must be built first with scripts/build-engine.sh.
// CI runs build-engine.sh before swift build/test.
let package = Package(
    name: "phacius_vnkey",
    platforms: [.macOS(.v13)],
    targets: [
        // C-header-only target exposing the Rust FFI.
        .target(
            name: "VnkeyC",
            path: "Sources/VnkeyC",
            publicHeadersPath: "include"
        ),

        // Swift wrapper over the C API.
        .target(
            name: "Bridge",
            dependencies: ["VnkeyC"],
            path: "Sources/Bridge",
            linkerSettings: [
                .linkedLibrary("vnkey_ffi"),
                .unsafeFlags(["-L\(Context.packageDirectory)/Sources/VnkeyC"]),
            ]
        ),

        .executableTarget(
            name: "VnkeyApp",
            dependencies: ["Bridge", "EventTap", "MenuBar", "Preferences"],
            path: "Sources/VnkeyApp"
        ),
        .target(
            name: "EventTap",
            dependencies: ["Bridge"],
            path: "Sources/EventTap",
            linkerSettings: [
                .linkedFramework("ApplicationServices"),
                .linkedFramework("CoreGraphics"),
            ]
        ),
        .target(
            name: "MenuBar",
            dependencies: ["EventTap"],
            path: "Sources/MenuBar"
        ),
        .target(
            name: "Preferences",
            dependencies: ["Bridge"],
            path: "Sources/Preferences"
        ),
        .testTarget(
            name: "BridgeTests",
            dependencies: ["Bridge"],
            path: "Tests/BridgeTests"
        ),
    ]
)
