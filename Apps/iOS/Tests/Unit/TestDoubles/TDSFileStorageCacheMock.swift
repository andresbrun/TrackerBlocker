import Foundation

@testable import iOS

final class TDSFileStorageCacheMock: TDSFileStorageCache {
    func save(_ data: Data, forETag etag: String) {}
    
    func getCachedData() -> Data {
        .mockedTDS
    }
} 
