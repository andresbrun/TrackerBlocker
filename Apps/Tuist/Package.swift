// swift-tools-version: 6.0
import PackageDescription

#if TUIST
import ProjectDescription
import ProjectDescriptionHelpers

let packageSettings = PackageSettings(
    baseSettings: .settings(
        configurations: AppCustomConfiguration.allCases.map { $0.targetConfiguration(includingSettings: false) },
        defaultSettings: .recommended
    )
)
#endif

let package = Package(
    name: "TrackerBlockerMVP",
    dependencies: [
        .package(url: "https://github.com/duckduckgo/TrackerRadarKit", exact: "2.1.2")
    ]
)
