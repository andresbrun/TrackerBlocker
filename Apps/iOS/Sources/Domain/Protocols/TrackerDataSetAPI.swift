import Foundation

protocol TrackerDataSetAPI {
    func downloadLatestTDS(withETag: String?) async throws -> (data: Data?, etag: String?)
} 

class DefaultTrackerDataSetAPI: TrackerDataSetAPI {
    private let tdsURL = URL(string: "https://staticcdn.duckduckgo.com/trackerblocking/v2.1/tds.json")!
    
    // TODO: Review
    func downloadLatestTDS(withETag: String?) async throws -> (data: Data?, etag: String?) {
        var request = URLRequest(url: tdsURL)
        if let etag = withETag {
            request.addValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            return (nil, nil)
        }
        
        // Return nil for 304 Not Modified responses
        guard httpResponse.statusCode == 200 else {
            return (nil, nil)
        }
        
        let newETag = httpResponse.allHeaderFields["ETag"] as? String
        return (data, newETag)
    }
}
