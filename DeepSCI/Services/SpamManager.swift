import Foundation
import CallKit
import Combine

public final class SpamManager: ObservableObject {
    public static let shared = SpamManager()
    
    @Published public var spamNumbers: [SpamNumber] = []
    @Published public var userTags: [SpamTag] = []
    @Published public var isSyncing: Bool = false
    @Published public var escalationThreshold: Int = 10
    
    // Sybil resistance parameters
    @Published public var taggerReputation: Double = 0.85 // Start at 85% trust
    
    private let extensionBundleIdentifier = "com.deepsci.app.directory"
    private let thresholdKey = "com.spamcalltagging.threshold"
    
    private init() {
        // Load threshold settings from shared suite if available, fallback to standard defaults
        let sharedDefaults = UserDefaults(suiteName: "group.com.deepsci.app")
        if let thresholdValue = sharedDefaults?.object(forKey: "com.spamcalltagging.threshold") as? Int {
            self.escalationThreshold = thresholdValue
        } else if UserDefaults.standard.object(forKey: thresholdKey) != nil {
            self.escalationThreshold = UserDefaults.standard.integer(forKey: thresholdKey)
        } else {
            self.escalationThreshold = 10
        }
        
        loadLocalData()
        calculateUserReputation()
    }
    
    public func loadLocalData() {
        self.spamNumbers = DatabaseManager.shared.loadSpamNumbers()
        self.userTags = DatabaseManager.shared.loadUserTags()
        
        // If first launch, seed data via SyncService
        if self.spamNumbers.isEmpty {
            syncData()
        }
    }
    
    public func updateThreshold(_ newThreshold: Int) {
        self.escalationThreshold = newThreshold
        UserDefaults.standard.set(newThreshold, forKey: thresholdKey)
        
        // Save to shared App Group suite for app extension access
        let sharedDefaults = UserDefaults(suiteName: "group.com.deepsci.app")
        sharedDefaults?.set(newThreshold, forKey: "com.spamcalltagging.threshold")
        
        // Settings changed -> Force CallKit to reload directories
        reloadCallDirectoryExtension()
    }
    
    // Calculates reputation score based on activity and accuracy (Sybil resistance)
    public func calculateUserReputation() {
        let tags = DatabaseManager.shared.loadUserTags()
        if tags.isEmpty {
            self.taggerReputation = 0.85 // Default trust
            return
        }
        
        // Base reputation increases with participation, maxes at 0.95
        var baseRep = 0.85 + (Double(tags.count) * 0.01)
        baseRep = min(baseRep, 0.95)
        
        // Check if any user tags have been disputed/overturned
        // For simulation, we scan spamNumbers to see if any number the user tagged has been resolved to "Not Spam"
        let numbers = DatabaseManager.shared.loadSpamNumbers()
        var penalties = 0.0
        
        for tag in tags {
            if let num = numbers.first(where: { $0.phoneNumber == tag.phoneNumber }) {
                // If a number the user tagged is now classified as "Not Spam", apply penalty
                if num.primaryCategory == "Not Spam" && tag.category != "Not Spam" {
                    penalties += 0.15 // Deduct 15% for false flagging
                }
            }
        }
        
        self.taggerReputation = max(0.10, baseRep - penalties) // Minimum 10% reputation
    }
    
    // Submits a tag for a number
    public func tagNumber(phoneNumber: String, category: String, geoRegion: String) {
        // Enforce rate limiting: only 1 tag per user per number per 24 hours
        let recentTags = userTags.filter { $0.phoneNumber == phoneNumber }
        if let lastTag = recentTags.max(by: { $0.timestamp < $1.timestamp }) {
            let hoursSinceLastTag = Date().timeIntervalSince(lastTag.timestamp) / 3600
            if hoursSinceLastTag < 24 {
                print("Rate limit: Already tagged \(phoneNumber) in the last 24 hours.")
                return
            }
        }
        
        // Calculate voter weight
        calculateUserReputation()
        let tag = SpamTag(
            phoneNumber: phoneNumber,
            category: category,
            geoRegion: geoRegion,
            userReputationWeight: self.taggerReputation
        )
        
        isSyncing = true
        SyncService.shared.submitTag(tag) { [weak self] result in
            DispatchQueue.main.async {
                self?.isSyncing = false
                switch result {
                case .success:
                    self?.loadLocalData()
                    self?.calculateUserReputation()
                    self?.reloadCallDirectoryExtension()
                case .failure(let error):
                    print("Failed to submit tag: \(error)")
                }
            }
        }
    }
    
    // Simulates pulling data updates from backend
    public func syncData() {
        isSyncing = true
        SyncService.shared.fetchLatestUpdates { [weak self] result in
            DispatchQueue.main.async {
                self?.isSyncing = false
                switch result {
                case .success(let numbers):
                    self?.spamNumbers = numbers
                    self?.reloadCallDirectoryExtension()
                case .failure(let error):
                    print("Sync error: \(error)")
                }
            }
        }
    }
    
    // Resolves an appeal (clears flags) for testing purposes
    public func submitAppeal(for phoneNumber: String) {
        isSyncing = true
        SyncService.shared.resolveAppeal(for: phoneNumber) { [weak self] result in
            DispatchQueue.main.async {
                self?.isSyncing = false
                switch result {
                case .success:
                    self?.loadLocalData()
                    self?.calculateUserReputation()
                    self?.reloadCallDirectoryExtension()
                case .failure(let error):
                    print("Appeal failed: \(error)")
                }
            }
        }
    }
    
    // Triggers iOS system CallKit reload for our Call Directory app extension
    public func reloadCallDirectoryExtension() {
        CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: extensionBundleIdentifier) { [weak self] status, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error checking extension status: \(error.localizedDescription)")
            }
            
            print("Call Directory Extension status: \(status.rawValue) (0=unknown, 1=disabled, 2=enabled)")
            
            // Trigger reload regardless, to push latest updates
            CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: self.extensionBundleIdentifier) { reloadError in
                if let reloadError = reloadError {
                    print("Failed to reload Call Directory Extension: \(reloadError.localizedDescription)")
                } else {
                    print("✓ Call Directory Extension updated successfully with new blocklists.")
                }
            }
        }
    }
}
