import Foundation

@testable import iOS

final class TDSFileStorageCacheMock: TDSFileStorageCache {
    var savedInvocation: (Data, String)?
    
    func save(_ data: Data, forETag etag: String) {
        savedInvocation = (data, etag)
    }
    
    func getCachedData() -> Data {
        .mockedTDS
    }
} 
