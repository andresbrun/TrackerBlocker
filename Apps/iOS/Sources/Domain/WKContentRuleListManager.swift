import WebKit
import Combine
import TrackerRadarKit
import os
import Foundation

struct Identifier: Codable {
    let etag: String?
    let domains: [String]
    
    var value: String {
        let sortedDomainsHash = domains.sorted().joined().data(using: .utf8)?.base64EncodedString() ?? ""
        return "\(etag ?? "local_file")_\(sortedDomainsHash)"
    }
}

class WKContentRuleListManager {
    struct Constants {
        static let IdentifierKey = "LastRuleListIdentifier"
        static let EtagKey = "ETag"
    }
    
    private let userDefaults: UserDefaultsProtocol
    private let ruleListStore: ContentRuleListStoreProtocol
    private let tdsAPI: TrackerDataSetAPI
    private let fileCache: TDSFileStorageCache
    private let whitelistDomainsUpdates: CurrentValueSubject<[String], Never>
    private let ruleListStateUpdates: CurrentValueSubject<RuleListStateUpdates?, Never>
    
    private var cancellables = Set<AnyCancellable>()
    private var compilationTask: Task<Void, Never>?
    
    private let logger = Logger.default
    
    private var lastIdentifier: Identifier? {
        get {
            guard let identifierData = userDefaults.data(forKey: Constants.IdentifierKey) else { return nil }
            return try? JSONDecoder().decode(Identifier.self, from: identifierData)
        }
        set {
            guard let newValue else {
                userDefaults.setValue(nil, forKey: Constants.IdentifierKey)
                return
            }
            let identifierData = try? JSONEncoder().encode(newValue)
            userDefaults.setValue(identifierData, forKey: Constants.IdentifierKey)
        }
    }
    
    init(
        userDefaults: UserDefaultsProtocol,
        ruleListStore: ContentRuleListStoreProtocol,
        tdsAPI: TrackerDataSetAPI,
        fileCache: TDSFileStorageCache,
        whitelistDomainsUpdates: CurrentValueSubject<[String], Never>,
        ruleListStateUpdates: CurrentValueSubject<RuleListStateUpdates?, Never>
    ) {
        self.userDefaults = userDefaults
        self.ruleListStore = ruleListStore
        self.tdsAPI = tdsAPI
        self.fileCache = fileCache
        self.whitelistDomainsUpdates = whitelistDomainsUpdates
        self.ruleListStateUpdates = ruleListStateUpdates
        
    }
    
    public func onInit() {
        logger.info("Initializing WKContentRuleListManager")
        subscribeToWhitelistDomainsUpdates()
        
        Task {
            await loadCurrentRuleListOrCompileWithCachedTDS()
        }
        
        Task {
            await tryToDownloadNewTDSIfExists()
        }
    }
    
    private func loadCurrentRuleListOrCompileWithCachedTDS() async {
        if let identifier = lastIdentifier {
            await retrieveCachedRuleList(identifier: identifier.value)
        } else {
            logger.warning("No cached rule list found, loading cached TDS data")
            let tdsData = await loadCachedTDS()
            await scheduleCompilationIfNeeded(
                with: tdsData,
                whitelistDomains: whitelistDomainsUpdates.value,
                reason: .initialLoad
            )
        }
    }
    
    private func tryToDownloadNewTDSIfExists() async {
        logger.info("Attempting to download new TDS file")
        guard let tdsData = await downloadTDSFileIfNeeded() else { return }
        await scheduleCompilationIfNeeded(
            with: tdsData,
            whitelistDomains: whitelistDomainsUpdates.value,
            reason: .newTDS
        )
    }
    
    private func subscribeToWhitelistDomainsUpdates() {
        logger.info("Subscribing to whitelist domains updates")
        whitelistDomainsUpdates
            .pairwise()
            .sink { [weak self] oldDomains, newDomains in
                guard let self else { return }
                logger.info("Whitelist domains updated: oldDomains=\(oldDomains), newDomains=\(newDomains)")
                let etag = userDefaults.string(forKey: Constants.EtagKey)
                guard let cachedData = try? fileCache.getData(forETag: etag) else { return }
 
                let added = Set(newDomains).subtracting(oldDomains)
                let removed = Set(oldDomains).subtracting(newDomains)
                
                Task {
                    await self.scheduleCompilationIfNeeded(
                        with: cachedData,
                        whitelistDomains: newDomains,
                        reason: .whitelistUpdated(
                            added: Array(added),
                            removed: Array(removed)
                        )
                    )
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    private func publish(
        ruleList: WKContentRuleList,
        reason: CompilationReason
    ) {
        logger.info("Publishing rule list for reason: \(String(describing: reason))")
        let state = RuleListStateUpdates(
            ruleList: ruleList,
            reason: reason
        )
        ruleListStateUpdates.send(state)
    }
    
    private func retrieveCachedRuleList(identifier: String) async {
        do {
            logger.info("Looking up content rule list for identifier: \(identifier)")
            if let ruleList = try await ruleListStore.lookUpContentRuleList(forIdentifier: identifier) {
                await publish(ruleList: ruleList, reason: .initialLoad)
                return
            } else {
                // TODO: Track error
                logger.warning("No rule list found, loading cached TDS")
            }
        } catch let error {
            // TODO: Track error
            logger.error("Error retrieving cached rule list: \(error.localizedDescription)")
        }
        let tdsData = await loadCachedTDS()
        await scheduleCompilationIfNeeded(
            with: tdsData,
            whitelistDomains: whitelistDomainsUpdates.value,
            reason: .initialLoad
        )
    }
    
    private func downloadTDSFileIfNeeded() async -> Data? {
        let etag = userDefaults.string(forKey: Constants.EtagKey)
        return await downloadNewTDS(withETag: etag)
    }
    
    private func loadCachedTDS() async -> Data {
        let etag = userDefaults.string(forKey: Constants.EtagKey)
        return try! fileCache.getData(forETag: etag)
    }
    
    private func downloadNewTDS(withETag etag: String?) async -> Data? {
        let startTime = Date()
        do {
            logger.info("Downloading latest TDS with ETag: \(etag ?? "none")")
            let (data, newETag) = try await tdsAPI.downloadLatestTDS(withETag: etag)
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("TDS file downloaded in \(duration) seconds")
            
            if let data = data, let newETag = newETag {
                userDefaults.setValue(newETag, forKey: Constants.EtagKey)
                fileCache.save(data, forETag: newETag)
                return data
            }
        } catch {
            // TODO: Handle network errors
            logger.error("Error downloading TDS: \(error.localizedDescription)")
        }
        return nil
    }
    
    // TODO: too big
    @MainActor
    private func scheduleCompilationIfNeeded(
        with trackerData: Data,
        whitelistDomains: [String],
        reason: CompilationReason
    ) {
        let uuid = Int.random(in: 1...100)
        logger.info("Compilation Task(\(uuid)): Scheduling compilation for reason: \(String(describing: reason))")

        compilationTask?.cancel()
        compilationTask = Task.detached { [weak self, logger] in
            logger.info("Compilation Task(\(uuid)): Starting compilation operation")
            guard let self else { return }
            
            let startTime = Date()
            let etag = self.userDefaults.string(forKey: Constants.EtagKey)
            
            let identifier = Identifier(etag: etag, domains: whitelistDomains)
            logger.info("Compilation Task(\(uuid)): Generating rule list identifier \(identifier.value). Last identifier: \(String(describing: lastIdentifier?.value))")
            
            if let lastIdentifier = lastIdentifier,
               lastIdentifier.value == identifier.value {
                logger.info("Compilation Task(\(uuid)): Identifier hasn't changed, skipping compilation")
                return
            }
            
            let trackerDataModel: TrackerData
            do {
                logger.info("Compilation Task(\(uuid)): Decoding tracker data")
                trackerDataModel = try JSONDecoder().decode(TrackerData.self, from: trackerData)
            } catch {
                logger.error("Compilation Task(\(uuid)): Failed to decode tracker data: \(error.localizedDescription)")
                return
            }
            
            logger.info("Compilation Task(\(uuid)): Building content blocker rules")
            let builder = ContentBlockerRulesBuilder(trackerData: trackerDataModel)
            let rules = builder.buildRules(
                andTemporaryUnprotectedDomains: whitelistDomains
            )
            
            let data: Data
            do {
                logger.info("Compilation Task(\(uuid)): Encoding rules to JSON")
                data = try JSONEncoder().encode(rules)
            } catch {
                logger.error("Compilation Task(\(uuid)): Failed to encode rules: \(error.localizedDescription)")
                return
            }
            let jsonRules = String(data: data, encoding: .utf8)!
            
            do {
                guard !Task.isCancelled else {
                    logger.info("Compilation Task(\(uuid)): Operation was cancelled")
                    return
                }
                logger.info("Compilation Task(\(uuid)): Compiling content rule list")
                let ruleList = try await self.ruleListStore.compileContentRuleList(
                    forIdentifier: identifier.value,
                    encodedContentRuleList: jsonRules
                )
                
                guard let ruleList = ruleList else {
                    logger.error("Compilation Task(\(uuid)): Failed to compile rule list")
                    self.trackError()
                    return
                }
                
                logger.info("Compilation Task(\(uuid)): Clearing previous rule list")
                await self.clearPreviousRuleList()
                
                self.lastIdentifier = identifier
                
                logger.info("Compilation Task(\(uuid)): Publishing new rule list")
                await self.publish(ruleList: ruleList, reason: reason)
                
                let duration = Date().timeIntervalSince(startTime)
                logger.info("Compilation Task(\(uuid)): Rule list compiled and published in \(duration) seconds")
            } catch {
                logger.error("Compilation Task(\(uuid)): Error during rule list compilation: \(error.localizedDescription)")
                self.trackError()
            }
        }
    }
    
    private func clearPreviousRuleList() async {
        guard let identifier = lastIdentifier else { return }
        try? await ruleListStore.removeContentRuleList(forIdentifier: identifier.value)
    }
    
    private func trackError() {
        logger.error("Error compiling WKContentRuleList")
        // TODO: Add tracker
        print("Error compiling WKContentRuleList")
    }
    
    private func generateRuleListIdentifier(etag: String?, domains: [String]) -> String {
        let identifier = Identifier(etag: etag, domains: domains)
        return identifier.value
    }
}
