@testable import iOS

class MockAnalyticsServices: EventTracking {
    var trackedEvents: [AnalyticsEvent] = []
    
    func trackEvent(_ event: AnalyticsEvent) {
        trackedEvents.append(event)
    }
}
