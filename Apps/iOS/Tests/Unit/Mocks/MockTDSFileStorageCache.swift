import Foundation

@testable import iOS

class MockTDSFileStorageCache: TDSFileStorageCache {
    var savedInvocation: (Data, String)?
    
    func save(_ data: Data, forETag etag: String) {
        savedInvocation = (data, etag)
    }
    
    func getCachedData() -> Data {
        .mockedTDS
    }
} 
