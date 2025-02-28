import ProjectDescription

let project = Project(
    name: "iOS",
    targets: [
        .target(
            name: "iOS",
            destinations: .iOS,
            product: .app,
            bundleId: "io.tuist.iOS",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["iOS/Sources/**"],
            resources: ["iOS/Resources/**"],
            dependencies: []
        ),
        .target(
            name: "iOSTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "io.tuist.iOSTests",
            infoPlist: .default,
            sources: ["iOS/Tests/**"],
            resources: [],
            dependencies: [.target(name: "iOS")]
        ),
    ]
)
