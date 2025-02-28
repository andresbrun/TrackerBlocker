import Foundation
import ProjectDescription

public let schemes: [Scheme] = [
    .create(
        name: "iOS α",
        configRunAndTest: .alphaDebug,
        configArchive: .alphaDebug,
        testableTargets: [
            .unit,
//            .integration,
//            .screenshot
        ]
    ),
    .create(
        name: "iOS β",
        configRunAndTest: .betaDebug,
        configArchive: .betaRelease,
        testableTargets: [
            // .endToEnd
        ]
    ),
    .create(
        name: "iOS AppStore",
        configRunAndTest: .appStoreRelease,
        configArchive: .appStoreRelease
    )
]
