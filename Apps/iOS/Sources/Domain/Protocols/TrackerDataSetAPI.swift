import Foundation

protocol TrackerDataSetAPI {
    func downloadLatestTDS(withETag: String?) async throws -> (data: Data?, etag: String?)
} 

class DefaultTrackerDataSetAPI: TrackerDataSetAPI {
    
    // TODO: Review
    func downloadLatestTDS(withETag: String?) async throws -> (data: Data?, etag: String?) {
        var request = URLRequest(url: URL(string: Constants.URL.TDS)!)
        if let etag = withETag {
            request.addValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            return (nil, nil)
        }
        
        switch httpResponse.statusCode {
        case 200:
            let newETag = httpResponse.value(forHTTPHeaderField: "ETag")
            return (data, newETag)
        default:
            return (nil, nil)
        }
    }
}
