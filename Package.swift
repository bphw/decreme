// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Decreme",
    platforms: [
        .iOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "Decreme",
            dependencies: [],
            path: "Sources"
        ),
        .target(
            name: "Decreme",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ]
        )
    ]
) 