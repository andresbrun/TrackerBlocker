import Foundation
import ProjectDescription

public let schemes: [Scheme] = [
    .create(
        name: "iOS α",
        configRunAndTest: .alphaDebug,
        configArchive: .alphaDebug,
        testableTargets: [
            .unit
        ]
    ),
    .create(
        name: "iOS β",
        configRunAndTest: .betaDebug,
        configArchive: .betaRelease,
        testableTargets: []
    ),
    .create(
        name: "iOS AppStore",
        configRunAndTest: .appStoreRelease,
        configArchive: .appStoreRelease
    )
]
