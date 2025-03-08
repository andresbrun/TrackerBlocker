import WebKit
import Combine
import TrackerRadarKit
import os
import Foundation

/// A manager class responsible for handling content blocking rules for WKWebKit.
///
/// The `WKContentRuleListManager` manages the lifecycle of content blocking rules, including:
/// - Loading and caching of Tracker Definition Set (TDS) data
/// - Compiling WebKit content blocking rules
/// - Managing whitelist domains
/// - Handling rule updates and state changes
///
/// ## Overview
/// The manager provides functionality to:
/// - Load existing rule lists from cache
/// - Download and compile new TDS files
/// - Handle whitelist domain updates
/// - Manage rule compilation and state updates
///
/// ## Example Usage
/// ```swift
/// let manager = WKContentRuleListManager(...)
/// manager.onInit()
/// ```
///
/// ## Error Handling
/// Errors are tracked and logged for:
/// - Rule list compilation failures
/// - TDS download issues
/// - JSON encoding/decoding problems
/// - Cache lookup errors
final class WKContentRuleListManager {
    private let logger = Logger.default
    
    // MARK: - Dependencies
    private let userDefaults: UserDefaultsProtocol
    private let ruleListStore: ContentRuleListStoreProtocol
    private let tdsAPI: TrackerDataSetAPI
    private let fileCache: TDSFileStorageCache
    private let whitelistDomainsUpdates: CurrentValueSubject<[String], Never>
    private let ruleListStateUpdates: CurrentValueSubject<RuleListStateUpdates?, Never>
    private let analyticsServices: AnalyticsServices
    
    // MARK: - State
    private var cancellables = Set<AnyCancellable>()
    private var compilationTask: Task<Void, Never>?
    
    // MARK: - Accessors
    private var lastIdentifier: WKContentRuleListIdentifier? {
        get {
            guard let identifierData = userDefaults.data(forKey: Constants.Key.Identifier) else { return nil }
            return try? JSONDecoder().decode(WKContentRuleListIdentifier.self, from: identifierData)
        }
        set {
            guard let newValue else {
                userDefaults.setValue(nil, forKey: Constants.Key.Identifier)
                return
            }
            let identifierData = try? JSONEncoder().encode(newValue)
            userDefaults.setValue(identifierData, forKey: Constants.Key.Identifier)
        }
    }
    
    private var lastEtag: String? {
        get {
            userDefaults.string(forKey: Constants.Key.Etag)
        }
        set {
            userDefaults.setValue(newValue, forKey: Constants.Key.Etag)
        }
    }
    
    // MARK: - Public
    init(
        userDefaults: UserDefaultsProtocol,
        ruleListStore: ContentRuleListStoreProtocol,
        tdsAPI: TrackerDataSetAPI,
        fileCache: TDSFileStorageCache,
        whitelistDomainsUpdates: CurrentValueSubject<[String], Never>,
        ruleListStateUpdates: CurrentValueSubject<RuleListStateUpdates?, Never>,
        analyticsServices: AnalyticsServices
    ) {
        self.userDefaults = userDefaults
        self.ruleListStore = ruleListStore
        self.tdsAPI = tdsAPI
        self.fileCache = fileCache
        self.whitelistDomainsUpdates = whitelistDomainsUpdates
        self.ruleListStateUpdates = ruleListStateUpdates
        self.analyticsServices = analyticsServices
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
    
    // MARK: - Private
    private func loadCurrentRuleListOrCompileWithCachedTDS() async {
        if let identifier = lastIdentifier {
            await retrieveCachedRuleList(identifier: identifier)
        } else {
            logger.warning("No cached rule list found, loading cached TDS data")
            await scheduleCompilationIfNeeded(
                with: loadCachedTDS(),
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
                let cachedData = fileCache.getCachedData()
                
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
    
    private func retrieveCachedRuleList(identifier: WKContentRuleListIdentifier) async {
        do {
            logger.info("Looking up content rule list for identifier: \(identifier)")
            if let ruleList = try await ruleListStore.lookUpContentRuleList(forIdentifier: identifier) {
                await publish(ruleList: ruleList, reason: .initialLoad)
                return
            } else {
                logger.warning("No rule list found, loading cached TDS")
            }
        } catch let error {
            trackError(type: "lookup_error", details: error.localizedDescription)
        }
        await scheduleCompilationIfNeeded(
            with: loadCachedTDS(),
            whitelistDomains: whitelistDomainsUpdates.value,
            reason: .initialLoad
        )
    }
    
    private func downloadTDSFileIfNeeded() async -> Data? {
        await downloadNewTDS(withETag: lastEtag)
    }
    
    private func loadCachedTDS() -> Data {
        fileCache.getCachedData()
    }
    
    private func downloadNewTDS(withETag etag: String?) async -> Data? {
        let startTime = Date()
        do {
            logger.info("Downloading latest TDS with ETag: \(etag ?? "none")")
            let (data, newETag) = try await tdsAPI.downloadLatestTDS(withETag: etag)
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("TDS file downloaded in \(duration) seconds")
            
            if let data = data, let newETag = newETag {
                lastEtag = newETag
                fileCache.save(data, forETag: newETag)
                return data
            }
        } catch let error {
            trackError(type: "download_error", details: error.localizedDescription)
        }
        return nil
    }
    
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
            
            let newIdentifier = WKContentRuleListIdentifier(etag: lastEtag, domains: whitelistDomains)
            logger.info("Compilation Task(\(uuid)): Generating rule list identifier \(newIdentifier.value). Last identifier: \(String(describing: lastIdentifier?.value))")
            
            if lastIdentifier?.value == newIdentifier.value {
                logger.info("Compilation Task(\(uuid)): Identifier hasn't changed, skipping compilation")
                return
            }
            
            let trackerDataModel: TrackerData
            do {
                logger.info("Compilation Task(\(uuid)): Decoding tracker data")
                trackerDataModel = try JSONDecoder().decode(TrackerData.self, from: trackerData)
            } catch {
                trackError(type: "decode_error", details: "Failed to decode tracker data: \(error.localizedDescription)")
                return
            }
            
            let builder = ContentBlockerRulesBuilder(trackerData: trackerDataModel)
            let rules = builder.buildRules(
                andTemporaryUnprotectedDomains: whitelistDomains
            )
            
            let data: Data
            do {
                logger.info("Compilation Task(\(uuid)): Encoding rules to JSON")
                data = try JSONEncoder().encode(rules)
            } catch {
                trackError(type: "encode_error", details: "Failed to encode rules: \(error.localizedDescription)")
                return
            }
            let jsonRules = String(data: data, encoding: .utf8)!
            
            do {
                guard !Task.isCancelled else {
                    logger.info("Compilation Task(\(uuid)): Operation was cancelled")
                    return
                }
                logger.info("Compilation Task(\(uuid)): Compiling content rule list")
                let ruleList = try await ruleListStore.compileContentRuleList(
                    forIdentifier: newIdentifier,
                    encodedContentRuleList: jsonRules
                )
                
                guard let ruleList else {
                    trackError(type: "compilation_error", details: "Rule list is nil after compilation")
                    return
                }
                
                logger.info("Compilation Task(\(uuid)): Clearing previous rule list")
                await self.clearPreviousRuleList()
                
                self.lastIdentifier = newIdentifier
                
                await self.publish(ruleList: ruleList, reason: reason)
                
                let duration = Date().timeIntervalSince(startTime)
                logger.info("Compilation Task(\(uuid)): Rule list compiled and published in \(duration) seconds")
            } catch let error {
                trackError(type: "compilation_error", details: error.localizedDescription)
            }
        }
    }
    
    private func clearPreviousRuleList() async {
        guard let lastIdentifier else { return }
        try? await ruleListStore.removeContentRuleList(forIdentifier: lastIdentifier)
    }
    
    private func trackError(type: String, details: String) {
        logger.error("Error in WKContentRuleList: \(type) - \(details)")
        analyticsServices.trackEvent(.contentRuleListError(type, details))
    }
}
