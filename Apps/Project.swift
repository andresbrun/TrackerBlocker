import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "TrackerBlockerMVP",
    options: .options(
        automaticSchemesOptions: .disabled
    ),
    settings: .settings(
        base: [
            "VALIDATE_WORKSPACE": true,
            "SWIFT_VERSION": "5.10"
        ],
        configurations: AppCustomConfiguration.allCases.map { $0.projectConfiguration() },
        defaultSettings: .recommended(excluding: ["SWIFT_ACTIVE_COMPILATION_CONDITIONS", "INFOPLIST_FILE"])
    ),
    targets: [
        .createApp()
    ]
    + testTargets,
    schemes: schemes,
    resourceSynthesizers: [.assets(), .strings()]
)
