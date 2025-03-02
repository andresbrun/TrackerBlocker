import Foundation
import ProjectDescription

public let testTargets: [Target] =
[
    .unit,
//    .screenshot,
//    .integration,
//    .endToEnd,
//] + [
//    .pageObjects,
//    .snapshotTesting,
//    .testing,
]

extension Target {
//    public static var integration: Self {
//        .createTest(
//            name: "Integration",
//            dependencies: [
//                .target(name: "TrackerBlockerMVP"),
//                .target(name: "DuckSnapshotTesting"),
//                .target(name: "DuckDuckPageObjects")
//            ]
//        )
//    }
//    
//    public static var endToEnd: Self {
//        .createTest(
//            name: "End-to-end",
//            dependencies: [
//                .target(name: "DuckTesting"),
//                .target(name: "TrackerBlockerMVP"),
//                .target(name: "DuckPageObjects")
//            ]
//        )
//    }
//    
    public static var unit: Self {
        .createTest(
            name: "Unit",
            product: .unitTests,
            dependencies: [
                .target(name: "iOS")
//                .target(name: "DuckSnapshotTesting"),
//                .testing
            ]
        )
    }
//    
//    public static var screenshot: Self {
//        .createTest(
//            name: "Screenshot",
//            product: .unitTests,
//            dependencies: [
//                .target(name: "TrackerBlockerMVP"),
//                .target(name: "DuckSnapshotTesting"),
//                .testing
//            ]
//        )
//    }
//    
//    public static var pageObjects: Self {
//        .createTestFramework(
//            name: "PageObjects",
//            sources: [
//                // "Tests/Frameworks/DuckPageObjects/**",
//            ],
//            dependencies: [
//                .testing,
//                .sdk(name: "XCTest", type: .framework),
//            ]
//        )
//    }
//    
//    public static var snapshotTesting: Self {
//        .createTestFramework(
//            name: "SnapshotTesting",
//            sources: [
//                // "Tests/Frameworks/DuckSnapshotTesting/**"
//            ],
//            dependencies: [
//                .external(name: "SnapshotTesting"),
//                .sdk(name: "XCTest", type: .framework),
//            ]
//        )
//    }
//    
//    public static var testing: Self {
//        .createTestFramework(
//            name: "Testing",
//            sources: [
//                // "Tests/Frameworks/DuckTesting/**"
//            ],
//            dependencies: [
//                .sdk(name: "XCTest", type: .framework)
//            ]
//        )
//    }
}

//public extension TargetDependency {
//    static var testing: TargetDependency {
//        .target(name: "CabiTesting")
//    }
//}
