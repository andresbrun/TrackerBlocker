import Foundation
import ProjectDescription

public let testTargets: [Target] = [.unit]

extension Target {
    public static var unit: Self {
        .createTest(
            name: "Unit",
            product: .unitTests,
            dependencies: [
                .target(name: "iOS")
            ]
        )
    }
}
