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
                .glob("iOS/**", excluding: ["iOS/Tests/**"])
            ],
            resources: [
                .glob(
                    pattern: "iOS/**/*.{storyboard,xib,strings,plist,xcassets,json,otf}",
                    excluding: [
                        "iOS/Supporting files/Infoplist/**",
                        "iOS/Supporting files/Entitlements/**"
                    ]
                )
            ],
            dependencies: [
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
            "iOS/Tests/\(name)/**"
        ] + additionalSources
        return .target(
            name: name,
            destinations: .iOS,
            product: product,
            bundleId: "$(PRODUCT_BUNDLE_IDENTIFIER_BASE).\(name)",
            deploymentTargets: iOSDeploymentTargets,
            infoPlist: .default,
            sources: .sourceFilesList(globs: sources.map { .glob($0) }),
            resources: [
//                .glob(pattern: "Tests/Shared/Common/Resources/**/*.{png,jpg,jpeg}")
            ],
            dependencies: dependencies,
            settings: .settings(
                base: additionalSettings,
                defaultSettings: .recommended(excluding: ["SWIFT_ACTIVE_COMPILATION_CONDITIONS"])
            )
        )
    }
    
//    static func createTestFramework(
//        name: String,
//        sources: SourceFilesList? = nil,
//        resources: ResourceFileElements? = nil,
//        scripts: [ProjectDescription.TargetScript] = [],
//        dependencies: [TargetDependency]
//    ) -> Self {
//        .target(
//            name: "Duck\(name)",
//            destinations: .iOS,
//            product: .framework,
//            bundleId: "$(PRODUCT_BUNDLE_IDENTIFIER_BASE).Duck\(name)",
//            deploymentTargets: iOSDeploymentTargets,
//            infoPlist: "iOS/Tests/Frameworks/Duck\(name)/Info.plist",
//            sources: sources,
//            resources: resources,
//            scripts: scripts,
//            dependencies: dependencies
//        )
//    }
}
