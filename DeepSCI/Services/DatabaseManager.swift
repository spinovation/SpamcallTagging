import Foundation

public final class DatabaseManager {
    public static let shared = DatabaseManager()
    
    private let appGroupIdentifier = "group.com.deepsci.app"
    private let spamFileName = "spam_numbers.json"
    private let tagsFileName = "user_tags.json"
    
    private init() {}
    
    // Gets the directory path for the shared App Group, or falls back to standard documents directory
    public func getStorageDirectory() -> URL {
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            return containerURL
        }
        // Fallback for local debug testing without developer provisioning
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // MARK: - Spam Numbers Core Data Access
    
    public func loadSpamNumbers() -> [SpamNumber] {
        let fileURL = getStorageDirectory().appendingPathComponent(spamFileName)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            return try decoder.decode([SpamNumber].self, from: data)
        } catch {
            print("Error loading spam numbers: \(error)")
            return []
        }
    }
    
    public func saveSpamNumbers(_ numbers: [SpamNumber]) {
        let fileURL = getStorageDirectory().appendingPathComponent(spamFileName)
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(numbers)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Error saving spam numbers: \(error)")
        }
    }
    
    // MARK: - User Submitted Tags Data Access
    
    public func loadUserTags() -> [SpamTag] {
        let fileURL = getStorageDirectory().appendingPathComponent(tagsFileName)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            return try decoder.decode([SpamTag].self, from: data)
        } catch {
            print("Error loading user tags: \(error)")
            return []
        }
    }
    
    public func saveUserTags(_ tags: [SpamTag]) {
        let fileURL = getStorageDirectory().appendingPathComponent(tagsFileName)
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(tags)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Error saving user tags: \(error)")
        }
    }
    
    // MARK: - CallKit Optimized Sorted Data Retrieval
    
    // Converts phone number strings like "+15550192834" to Int64 (CallKit requirement)
    public func parsePhoneNumberToInt(_ phoneStr: String) -> Int64? {
        // Strip out non-digit characters
        let digits = phoneStr.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Int64(digits)
    }
    
    // Returns a list of sorted numbers to BLOCK (Tier 2 and Tier 3)
    // iOS CallKit REQUIRES numbers to be in strictly ascending order
    public func getSortedBlockingNumbers(threshold: Int) -> [Int64] {
        let numbers = loadSpamNumbers()
        var blockingInts: [Int64] = []
        
        for num in numbers {
            if num.threatTier(threshold: threshold) >= 2 {
                if let intVal = parsePhoneNumberToInt(num.phoneNumber) {
                    blockingInts.append(intVal)
                }
            }
        }
        
        // Return sorted ascending
        return blockingInts.sorted()
    }
    
    // Returns a dictionary of sorted numbers to IDENTIFY (Tier 1) mapped to their labels
    // iOS CallKit REQUIRES phone numbers to be in strictly ascending order
    public func getSortedIdentificationNumbers(threshold: Int) -> [(Int64, String)] {
        let numbers = loadSpamNumbers()
        var identifyingList: [(Int64, String)] = []
        
        for num in numbers {
            if num.threatTier(threshold: threshold) == 1 {
                if let intVal = parsePhoneNumberToInt(num.phoneNumber) {
                    let label = "Suspected \(num.primaryCategory) (SpamTag)"
                    identifyingList.append((intVal, label))
                }
            }
        }
        
        // Sort by the Int64 phone number ascending
        return identifyingList.sorted(by: { $0.0 < $1.0 })
    }
}
