// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TargetWorkshop",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "TargetWorkshop",
            path: ".",
            sources: [
                "AppState.swift",
                "Models.swift",
                "RangeKeyHandling.swift",
                "RangeView.swift",
                "RootView.swift",
                "TargetWorkshopApp.swift",
                "WeaponDrawing.swift",
                "WeaponLibrary.swift",
                "WorkshopView.swift"
            ]
        )
    ]
)
