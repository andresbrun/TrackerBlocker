@testable import iOS

final class FeatureProviderMock: FeatureProvider {
    var featureFlags: [FeatureFlag: Bool] = [
        .enhancedTrackingProtection: true
    ]
    
    func isFeatureEnabled(_ feature: FeatureFlag) -> Bool {
        featureFlags[feature] ?? false
    }
}
