import Foundation

@testable import iOS

final class TrackerDataSetAPIMock: TrackerDataSetAPI {
    var shouldFailDownload = false
    var shouldReturnNewEtag = true
    
    func downloadLatestTDS(
        withETag: String?
    ) async throws -> (data: Data?, etag: String?) {
        try await Task.sleep(for: .seconds(0.2))
        if shouldFailDownload {
            throw NSError(domain: "NetworkError", code: -1, userInfo: nil)
        }
        if shouldReturnNewEtag {
            return (.mockedTDS, "newETag")
        } else {
            return (nil, nil)
        }
    }
} 
