import Foundation
import ProjectDescription

public extension Target {
    static func createApp() -> Self {
        .target(
            name: "iOS",
            destinations: .iOS,
            product: .app,
            bundleId: "$(PRODUCT_BUNDLE_IDENTIFIER_BASE)",
            deploymentTargets: iOSDeploymentTargets,
            infoPlist: nil,
            sources: [
                .glob("Sources/**")
            ],
            resources: [
                .glob(pattern: "Resources/**"),
                .glob(pattern: "Supporting files/*.lproj/*.{storyboard,strings}")
            ],
            dependencies: [
                .external(name: "TrackerRadarKit")
            ],
            settings: .settings( 
                configurations: AppCustomConfiguration.allCases.map { $0.targetConfiguration(for: .iOS) },
                defaultSettings: .recommended(excluding: ["SWIFT_ACTIVE_COMPILATION_CONDITIONS"])
            )
        )
    }
}

public extension Target {

    static func createTest(
        name: String,
        product: Product = .uiTests,
        dependencies: [TargetDependency],
        additionalSettings: SettingsDictionary = [:],
        additionalSources: [Path] = []
    ) -> Self {
        let sources: [Path] = [
            "Tests/\(name)/**"
        ] + additionalSources
        return .target(
            name: name,
            destinations: .iOS,
            product: product,
            bundleId: "$(PRODUCT_BUNDLE_IDENTIFIER_BASE).\(name)",
            deploymentTargets: iOSDeploymentTargets,
            infoPlist: .default,
            sources: .sourceFilesList(globs: sources.map { .glob($0) }),
            resources: [],
            dependencies: dependencies,
            settings: .settings(
                base: additionalSettings,
                defaultSettings: .recommended(excluding: ["SWIFT_ACTIVE_COMPILATION_CONDITIONS"])
            )
        )
    }
}
