import Foundation
import ProjectDescription

public extension TestableTarget {
    static var integration: Self {
        .testableTarget(target: "Integration", parallelization: .disabled)
    }
    static var unit: Self {
        .testableTarget(target: "Unit", parallelization: .disabled)
    }
    static var screenshot: Self {
        .testableTarget(target: "Screenshot", parallelization: .disabled)
    }
    static var endToEnd: Self {
        .testableTarget(target: "End-to-end", parallelization: .disabled)
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
                        "RUNNING_TESTS": "1",
                        "SNAPSHOT_ARTIFACTS": "/tmp/__SnapshotArtifacts__"
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
