@testable import iOS

final class AnalyticsServicesMock: AnalyticsServices {
    var trackedEvents: [AnalyticsEvent] = []
    
    func trackEvent(_ event: AnalyticsEvent) {
        trackedEvents.append(event)
    }
}
