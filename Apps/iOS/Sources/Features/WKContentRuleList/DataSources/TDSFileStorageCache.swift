import Foundation
import os

protocol TDSFileStorageCache {
    func save(_ data: Data, forETag etag: String)
    func getCachedData() -> Data
} 

final class DefaultTDSFileStorageCache: TDSFileStorageCache {
    private let fileManager = FileManager.default
    private let bundledTDSFileName = "tds_20250301.json"
    private let tdsCacheFileName = "tds_cached.json"
    private let logger = Logger.default
    
    private var cacheDirectory: URL {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("TDSCache")
    }
    
    init() {
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func save(_ data: Data, forETag etag: String) {
        var coordinatorError: NSError?

        let tdsFileURL = cacheDirectory.appendingPathComponent(tdsCacheFileName)
        
        NSFileCoordinator().coordinate(
            writingItemAt: tdsFileURL,
            options: .forReplacing,
            error: &coordinatorError
        ) { fileUrl in
            do {
                try data.write(to: fileUrl, options: .atomic)
                logger.debug("Store TDS successfully for \(etag) in \(fileUrl)")
            } catch let error {
                logger.error("Unable to store tds for \(etag): \(error.localizedDescription)")
            }
        }

        if let coordinatorError {
            logger.error("Unable to store tds for \(etag): \(coordinatorError.localizedDescription)")
        }
    }
    
    func getCachedData() -> Data {
        let tdsFileURL = cacheDirectory.appendingPathComponent(tdsCacheFileName)
        var data: Data?
        var coordinatorError: NSError?

        NSFileCoordinator().coordinate(
            readingItemAt: tdsFileURL,
            error: &coordinatorError
        ) { fileUrl in
            do {
                data = try Data(contentsOf: fileUrl)
                logger.debug("Retrieve TDS successfully in \(fileUrl)")
            } catch let error {
                logger.error("Unable to retrieve tds: \(error.localizedDescription)")
            }
        }

        if let coordinatorError {
            logger.error("Unable to retrieve tds: \(coordinatorError.localizedDescription)")
        }
        
        return data ?? loadBundledTDS()
    }
    
    private func loadBundledTDS() -> Data {
        // Allow force unwrapping because the file is in the bundle
        // And the data should be right
        let bundleURL = Bundle.main.url(forResource: bundledTDSFileName, withExtension: nil)!
        let data = try! Data(contentsOf: bundleURL)
        return data
    }
}
