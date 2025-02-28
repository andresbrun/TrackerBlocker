import Foundation
import ProjectDescription

public enum AppCustomConfiguration: String, CaseIterable {
    public enum Target: String {
        case iOS = "iOS"
    }
    case alphaDebug = "Alpha Debug"
    case betaDebug = "Beta Debug"
    case betaRelease = "Beta Release"
    case appStoreRelease = "AppStore Release"
    
    public func projectConfiguration(includingSettings: Bool = true) -> Configuration {
        switch self {
        case .alphaDebug, .betaDebug:
            if includingSettings {
                return .debug(name: .configuration(rawValue), settings: projectSettings())
            } else {
                return .debug(name: .configuration(rawValue))
            }            
        case .betaRelease, .appStoreRelease:
            if includingSettings {
                return .release(name: .configuration(rawValue), settings: projectSettings())
            } else {
                return .release(name: .configuration(rawValue))
            }   
        }
    }
    
    private func projectSettings() -> SettingsDictionary {
        var custom: SettingsDictionary
        switch self {
        case .alphaDebug:
            custom = [
                "DISPLAY_NAME": "Tracker Blocker α",
                "PRODUCT_BUNDLE_IDENTIFIER_BASE": "com.brunos.trackerblockermvp.alpha",
                "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
                "ENABLE_TESTABILITY": "YES",
                "OTHER_SWIFT_FLAGS": "$(inherited) -Xfrontend -warn-long-expression-type-checking=240 -Xfrontend -debug-time-function-bodies -Xfrontend -warn-long-function-bodies=240"
            ]
        case .betaDebug:
            custom = [
                "DISPLAY_NAME": "Tracker Blocker β",
                "PRODUCT_BUNDLE_IDENTIFIER_BASE": "com.brunos.trackerblockermvp.beta",
                "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
                "ENABLE_TESTABILITY": "YES",
            ]
        case .betaRelease:
            custom = [
                "DISPLAY_NAME": "Tracker Blocker β",
                "PRODUCT_BUNDLE_IDENTIFIER_BASE": "com.brunos.trackerblockermvp.beta.release",
                "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "PRODUCTION"
            ]
        case .appStoreRelease:
            custom = [
                "DISPLAY_NAME": "Tracker Blocker",
                "PRODUCT_BUNDLE_IDENTIFIER_BASE": "com.brunos.trackerblockermvp",
                "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "PRODUCTION"
            ]
        }
        
        return projectBaseSettings.merging(custom, uniquingKeysWith: { _, custom in custom })
    }
    
    private var projectBaseSettings: SettingsDictionary {
        [
            "TARGETED_DEVICE_FAMILY": "1,2",
            "SDKROOT": "iphoneos",
            "APPLICATION_EXTENSION_API_ONLY": "NO",
            "SUPPORTS_MACCATALYST": "NO",
            "CODE_SIGN_STYLE": "Automatic"
        ]
    }
    
    public func targetConfiguration(for target: Target = .iOS, includingSettings: Bool = true) -> Configuration {
        switch self {
        case .alphaDebug, .betaDebug:
            if includingSettings {
                return .debug(name: .configuration(rawValue), settings: targetSettings(for: target))
            } else {
                return .debug(name: .configuration(rawValue))
            }
            
        case .betaRelease, .appStoreRelease:
            if includingSettings {
                return .release(name: .configuration(rawValue), settings: targetSettings(for: target))
            } else {
                return .release(name: .configuration(rawValue))
            }
        }
    }
    
    private func targetSettings(for target: Target) -> SettingsDictionary {
        let supportingFilesPath = "\(target.rawValue)/Supporting files"
        let custom: SettingsDictionary
        switch self {
        case .alphaDebug:
            custom = [
                "INFOPLIST_FILE": "\(supportingFilesPath)/Infoplist/Info-alpha.plist",
                "CODE_SIGN_ENTITLEMENTS": "\(supportingFilesPath)/Entitlements/DebugAlpha.entitlements",
            ]
        case .betaDebug:
            custom = [
                "INFOPLIST_FILE": "\(supportingFilesPath)/Infoplist/Info-beta.plist",
                "CODE_SIGN_ENTITLEMENTS": "\(supportingFilesPath)/Entitlements/DebugBeta.entitlements"
            ]
        case .betaRelease:
            custom = [
                "INFOPLIST_FILE": "\(supportingFilesPath)/Infoplist/Info-beta.plist",
                "CODE_SIGN_ENTITLEMENTS": "\(supportingFilesPath)/Entitlements/DebugBeta.entitlements",
            ]
        case .appStoreRelease:
            custom = [
                "INFOPLIST_FILE": "\(supportingFilesPath)/Infoplist/Info-appstore.plist",
                "CODE_SIGN_ENTITLEMENTS": "\(supportingFilesPath)/Entitlements/AppStore.entitlements"
            ]
        }
        
        return targetBaseSettings.merging(custom, uniquingKeysWith: { _, custom in custom })
    }
    
    private var targetBaseSettings: SettingsDictionary {
        [
            "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
            "LAUNCH_SCREEN": "LaunchScreen",
            "DEVELOPMENT_TEAM": "3C5G49HFXP"
        ]
    }
}
