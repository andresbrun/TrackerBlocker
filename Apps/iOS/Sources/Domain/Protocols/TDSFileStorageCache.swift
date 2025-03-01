import Foundation

protocol TDSFileStorageCache {
    func save(_ data: Data, forETag etag: String)
    func getData(forETag etag: String?) throws -> Data
} 

class DefaultTDSFileStorageCache: TDSFileStorageCache {
    private let fileManager = FileManager.default
    private let bundledTDSFileName = "tds_20250301.json"
    
    // TODO: Change directory
    private var cacheDirectory: URL {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("TDSCache")
    }
    
    init() {
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func save(_ data: Data, forETag etag: String) {
        let fileURL = cacheDirectory.appendingPathComponent(etag)
        try? data.write(to: fileURL)
    }
    
    func getData(forETag etag: String?) throws -> Data {
        if let etag {
            let fileURL = cacheDirectory.appendingPathComponent(etag)
            return try Data(contentsOf: fileURL)
        } else {
            return try loadBundledTDS()
        }
    }
    
    private func loadBundledTDS() throws -> Data {
        guard let bundleURL = Bundle.main.url(forResource: bundledTDSFileName, withExtension: nil),
              let data = try? Data(contentsOf: bundleURL) else {
            throw NSError(
                domain: "TDSError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to load bundled TDS file"]
            )
        }
        return data
    }
}
