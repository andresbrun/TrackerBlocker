import Foundation

protocol TrackerDataSetAPI {
    func downloadLatestTDS(withETag: String?) async throws -> (data: Data?, etag: String?)
} 

final class DefaultTrackerDataSetAPI: TrackerDataSetAPI {
    
    func downloadLatestTDS(
        withETag: String?
    ) async throws -> (data: Data?, etag: String?) {
        var request = URLRequest(url: URL(string: Constants.URL.TDS)!)
        if let etag = withETag {
            request.addValue(
                etag,
                forHTTPHeaderField: Constants.HTTP.Header.IfNoneMatch
            )
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            return (nil, nil)
        }
        
        switch httpResponse.statusCode {
        case 200:
            let newETag = httpResponse.value(
                forHTTPHeaderField: Constants.HTTP.Header.ETag
            )
            return (data, newETag)
        default:
            return (nil, nil)
        }
    }
}
