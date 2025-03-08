@testable import iOS

class MockAnalyticsServices: AnalyticsServices {
    var trackedEvents: [AnalyticsEvent] = []
    
    func trackEvent(_ event: AnalyticsEvent) {
        trackedEvents.append(event)
    }
}
