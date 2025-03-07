import Foundation

enum FeatureFlag: String {
    case enhancedTrackingProtection
}

protocol FeatureProvider {
    func isFeatureEnabled(_ feature: FeatureFlag) -> Bool
}

// Since we don't have a real feature provider, we'll use a Fake
final class FakeFeatureProvider: FeatureProvider {
    private var featureFlags: [FeatureFlag: Bool] = [
        .enhancedTrackingProtection: true
    ]
    
    func isFeatureEnabled(_ feature: FeatureFlag) -> Bool {
        featureFlags[feature] ?? false
    }
}

final class FeatureStore {
    private let provider: FeatureProvider
    
    init(provider: FeatureProvider) {
        self.provider = provider
    }
    
    func isFeatureEnabled(_ feature: FeatureFlag) -> Bool {
        return provider.isFeatureEnabled(feature)
    }
}
