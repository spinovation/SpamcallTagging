import Foundation
import CallKit

public final class CallDirectoryHandler: CXCallDirectoryProvider {
    
    private let appGroupIdentifier = "group.com.deepsci.app"
    private let spamFileName = "spam_numbers.json"
    
    // Local copy of model for memory efficiency
    private struct ExtensionSpamNumber: Decodable {
        let phoneNumber: String
        let callerName: String?
        let categoryBreakdown: [String: Int]
        let totalTags: Int
        let dnoMatched: Bool
        
        var primaryCategory: String {
            if categoryBreakdown.isEmpty { return "Spam" }
            return categoryBreakdown.max(by: { $0.value < $1.value })?.key ?? "Spam"
        }
        
        func threatTier(threshold: Int) -> Int {
            if dnoMatched { return 3 }
            
            let tier1Threshold = max(1, threshold / 3) // e.g. 3 tags
            let tier2Threshold = threshold             // e.g. 10 tags
            let tier3Threshold = threshold * 5         // e.g. 50 tags
            
            if totalTags >= tier3Threshold {
                return 3
            } else if totalTags >= tier2Threshold {
                return 2
            } else if totalTags >= tier1Threshold {
                return 1
            }
            return 0
        }
    }

    public override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self
        
        // Retrieve list of numbers to block and identify
        addAllBlockingPhoneNumbers(to: context)
        addAllIdentificationPhoneNumbers(to: context)
        
        context.completeRequest()
    }
    
    // MARK: - CallKit Registry Ingestion
    
    private func addAllBlockingPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        let blockingNumbers = loadSortedNumbers(forTiers: [2, 3])
        for number in blockingNumbers {
            context.addBlockingEntry(withNextSequentialPhoneNumber: number)
        }
    }
    
    private func addAllIdentificationPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        let identifications = loadSortedIdentifications()
        for (number, label) in identifications {
            context.addIdentificationEntry(withNextSequentialPhoneNumber: number, label: label)
        }
    }
    
    // MARK: - Data Loading Helpers
    
    private func getStorageDirectory() -> URL {
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            return containerURL
        }
        // Fallback for debug local testing
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func loadThreshold() -> Int {
        if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            let val = sharedDefaults.integer(forKey: "com.spamcalltagging.threshold")
            return val == 0 ? 10 : val
        }
        return 10
    }
    
    private func parsePhoneNumberToInt(_ phoneStr: String) -> Int64? {
        let digits = phoneStr.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Int64(digits)
    }
    
    private func loadRawNumbers() -> [ExtensionSpamNumber] {
        let fileURL = getStorageDirectory().appendingPathComponent(spamFileName)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            return try decoder.decode([ExtensionSpamNumber].self, from: data)
        } catch {
            print("Extension error loading spam numbers: \(error)")
            return []
        }
    }
    
    // Returns sorted numbers for blocking (Tier 2 and Tier 3)
    private func loadSortedNumbers(forTiers tiers: Set<Int>) -> [CXCallDirectoryPhoneNumber] {
        let rawNumbers = loadRawNumbers()
        let threshold = loadThreshold()
        var list: [CXCallDirectoryPhoneNumber] = []
        
        for num in rawNumbers {
            let tier = num.threatTier(threshold: threshold)
            if tiers.contains(tier) {
                if let intVal = parsePhoneNumberToInt(num.phoneNumber) {
                    list.append(intVal)
                }
            }
        }
        
        // STRICT REQUIREMENT: Must be sorted ascending
        return list.sorted()
    }
    
    // Returns sorted numbers and labels for identification (Tier 1)
    private func loadSortedIdentifications() -> [(CXCallDirectoryPhoneNumber, String)] {
        let rawNumbers = loadRawNumbers()
        let threshold = loadThreshold()
        var list: [(CXCallDirectoryPhoneNumber, String)] = []
        
        for num in rawNumbers {
            let tier = num.threatTier(threshold: threshold)
            if tier == 1 {
                if let intVal = parsePhoneNumberToInt(num.phoneNumber) {
                    let label = "Suspected \(num.primaryCategory) (Deep SCI)"
                    list.append((intVal, label))
                }
            }
        }
        
        // STRICT REQUIREMENT: Must be sorted ascending by phone number
        return list.sorted(by: { $0.0 < $1.0 })
    }
}

// MARK: - CXCallDirectoryExtensionContextDelegate

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    public func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        print("Extension request failed: \(error.localizedDescription)")
    }
}
