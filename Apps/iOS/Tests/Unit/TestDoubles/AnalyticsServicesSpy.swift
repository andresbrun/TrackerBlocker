@testable import iOS

final class AnalyticsServicesSpy: AnalyticsServices {
    var trackedEvents: [AnalyticsEvent] = []
    
    func trackEvent(_ event: AnalyticsEvent) {
        trackedEvents.append(event)
    }
}
