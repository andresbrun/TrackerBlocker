import Foundation
import ProjectDescription

public extension TestableTarget {
    static var unit: Self {
        .testableTarget(target: "Unit", parallelization: .disabled)
    }
}

public extension Scheme {
    static func create(
        name: String,
        configRunAndTest: AppCustomConfiguration,
        configArchive: AppCustomConfiguration,
        testableTargets: [TestableTarget] = []
    ) -> Self {
        .scheme(
            name: name,
            shared: true,
            testAction: .targets(
                testableTargets,
                arguments: .arguments(
                    environmentVariables: [
                        "RUNNING_TESTS": "1"
                    ]
                ),
                configuration: ConfigurationName(stringLiteral: configRunAndTest.rawValue),
                options: .options(language: "en", region: "ES", coverage: true)
            ),
            runAction: .runAction(
                configuration: ConfigurationName(stringLiteral: configRunAndTest.rawValue),
                executable: .target("iOS"),
                arguments: .arguments(environmentVariables: ["RUNNING_FROM_XCODE": "1"])
            ),
            archiveAction: .archiveAction(
                configuration: ConfigurationName(stringLiteral: configArchive.rawValue),
                revealArchiveInOrganizer: false,
                customArchiveName: "iOS"
            ),
            profileAction: .profileAction(
                configuration: ConfigurationName(stringLiteral: configRunAndTest.rawValue)
            ),
            analyzeAction: .analyzeAction(
                configuration: ConfigurationName(stringLiteral: configRunAndTest.rawValue)
            )
        )
    }
}
