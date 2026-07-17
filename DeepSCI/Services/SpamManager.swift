import Foundation
import CallKit
import Combine
import UIKit

public final class SpamManager: ObservableObject {
    public static let shared = SpamManager()
    
    @Published public var spamNumbers: [SpamNumber] = []
    @Published public var userTags: [SpamTag] = []
    @Published public var isSyncing: Bool = false
    @Published public var escalationThreshold: Int = 10
    
    // Sybil resistance parameters
    @Published public var taggerReputation: Double = 0.85 // Start at 85% trust
    
    // Version 1.1 Developer & Credit Settings
    @Published public var showDeveloperTools: Bool = false
    @Published public var freeLookupsLeft: Int = 5
    @Published public var purchasedCredits: Int = 0
    
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
        
        // Version 1.1 settings loading
        self.showDeveloperTools = UserDefaults.standard.bool(forKey: "com.deepsci.showDeveloperTools")
        if UserDefaults.standard.object(forKey: "com.spamcalltagging.freeLookupsLeft") != nil {
            self.freeLookupsLeft = UserDefaults.standard.integer(forKey: "com.spamcalltagging.freeLookupsLeft")
        } else {
            self.freeLookupsLeft = 5
        }
        self.purchasedCredits = UserDefaults.standard.integer(forKey: "com.spamcalltagging.purchasedCredits")
        
        loadLocalData()
        calculateUserReputation()
        checkMonthlyCreditsReset()
    }
    
    public func loadLocalData() {
        self.spamNumbers = DatabaseManager.shared.loadSpamNumbers()
        self.userTags = DatabaseManager.shared.loadUserTags()
        print("📁 [SpamManager] Loaded \(self.spamNumbers.count) spam numbers from database: \(self.spamNumbers.map { $0.phoneNumber })")
        
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
    
    // Submits a tag for a number. Returns true if accepted, false if rate limited.
    @discardableResult
    public func tagNumber(phoneNumber: String, category: String, geoRegion: String) -> Bool {
        // Enforce rate limiting: only 1 tag per user per number per 24 hours
        let recentTags = userTags.filter { $0.phoneNumber == phoneNumber }
        if let lastTag = recentTags.max(by: { $0.timestamp < $1.timestamp }) {
            let hoursSinceLastTag = Date().timeIntervalSince(lastTag.timestamp) / 3600
            if hoursSinceLastTag < 24 {
                print("⚠️ Rate limit: Already tagged \(phoneNumber) in the last 24 hours.")
                return false
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
                    print("✅ [SpamManager] Tag submitted successfully for \(phoneNumber). Reloading local data...")
                    self?.loadLocalData()
                    self?.calculateUserReputation()
                    self?.reloadCallDirectoryExtension()
                case .failure(let error):
                    print("❌ [SpamManager] Failed to submit tag for \(phoneNumber): \(error)")
                }
            }
        }
        return true
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
    
    // MARK: - Version 1.1 Credit & Developer Features
    
    private func checkMonthlyCreditsReset() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let currentMonthStr = formatter.string(from: Date())
        
        let lastResetMonth = UserDefaults.standard.string(forKey: "com.spamcalltagging.lastResetMonth") ?? ""
        
        if lastResetMonth != currentMonthStr {
            self.freeLookupsLeft = 5
            UserDefaults.standard.set(5, forKey: "com.spamcalltagging.freeLookupsLeft")
            UserDefaults.standard.set(currentMonthStr, forKey: "com.spamcalltagging.lastResetMonth")
            print("📅 [SpamManager] New month detected (\(currentMonthStr)). Free lookups reset to 5.")
        }
    }
    
    public func toggleDeveloperTools() {
        self.showDeveloperTools.toggle()
        UserDefaults.standard.set(self.showDeveloperTools, forKey: "com.deepsci.showDeveloperTools")
        
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
        print("🛠 [SpamManager] showDeveloperTools is now \(self.showDeveloperTools)")
    }
    
    public func buyCreditPack() {
        self.purchasedCredits += 10
        UserDefaults.standard.set(self.purchasedCredits, forKey: "com.spamcalltagging.purchasedCredits")
        
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
        print("💳 [SpamManager] Purchased 10 lookup credits. Total: \(self.purchasedCredits)")
    }
    
    @discardableResult
    public func performGlobalLookup(phoneNumber: String, completion: @escaping (Result<SpamNumber, Error>) -> Void) -> Bool {
        if freeLookupsLeft > 0 {
            freeLookupsLeft -= 1
            UserDefaults.standard.set(freeLookupsLeft, forKey: "com.spamcalltagging.freeLookupsLeft")
        } else if purchasedCredits > 0 {
            purchasedCredits -= 1
            UserDefaults.standard.set(purchasedCredits, forKey: "com.spamcalltagging.purchasedCredits")
        } else {
            print("❌ [SpamManager] Cannot perform global lookup: Out of credits.")
            return false
        }
        
        // Simulate a reverse lookup network call
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1.5) {
            let cleanNumber = phoneNumber.filter { $0.isNumber }
            let carrier = ["Verizon Wireless", "AT&T", "T-Mobile", "Twilio", "Bandwidth.com"].randomElement() ?? "Carrier Network"
            
            var name = "Potential Spam"
            if cleanNumber.hasSuffix("187") || phoneNumber.contains("510") {
                name = "Oakland Delivery"
            } else if cleanNumber.hasSuffix("199") || phoneNumber.contains("800") {
                name = "IRS Tax Administration"
            } else if cleanNumber.hasSuffix("155") || phoneNumber.contains("312") {
                name = "Auto Warranty Center"
            } else {
                let businessNames = ["Capital Debt Solutions", "Healthcare Enrollments", "Student Relief Association", "National Power & Gas", "Vacation Rewards Center"]
                name = businessNames.randomElement() ?? "Direct Sales Spammer"
            }
            
            let lookupResult = SpamNumber(
                phoneNumber: phoneNumber,
                callerName: name,
                carrier: carrier,
                categoryBreakdown: ["Spam/Telemarketing": 1],
                totalTags: 1,
                lastUpdated: Date(),
                isUserFlagged: false,
                reassignmentStatus: "Unknown",
                dnoMatched: false
            )
            
            DispatchQueue.main.async { [weak self] in
                var localList = DatabaseManager.shared.loadSpamNumbers()
                if !localList.contains(where: { $0.phoneNumber == phoneNumber }) {
                    localList.append(lookupResult)
                    DatabaseManager.shared.saveSpamNumbers(localList)
                    self?.loadLocalData()
                }
                completion(.success(lookupResult))
            }
        }
        return true
    }
}

// MARK: - Global Formatting Helpers

public func formatPhoneNumber(_ phone: String) -> String {
    let clean = phone.filter { $0.isNumber }
    
    if clean.count == 10 {
        let area = clean.prefix(3)
        let prefix = clean.dropFirst(3).prefix(3)
        let suffix = clean.dropFirst(6).prefix(4)
        return "(\(area)) \(prefix)-\(suffix)"
    } else if clean.count == 11 && clean.hasPrefix("1") {
        let area = clean.dropFirst(1).prefix(3)
        let prefix = clean.dropFirst(4).prefix(3)
        let suffix = clean.dropFirst(7).prefix(4)
        return "+1 (\(area)) \(prefix)-\(suffix)"
    }
    
    // For international or other lengths, prefix with + if it was clean and not already prefixed
    if phone.hasPrefix("+") {
        return phone
    } else if phone.allSatisfy({ $0.isNumber }) {
        return "+" + phone
    }
    return phone
}

