import Foundation

public struct SpamNumber: Codable, Identifiable, Hashable {
    public var id: String { phoneNumber }
    public let phoneNumber: String
    public var callerName: String?
    public var carrier: String?
    public var categoryBreakdown: [String: Int]
    public var totalTags: Int
    public var lastUpdated: Date
    public var isUserFlagged: Bool
    public var reassignmentStatus: String? // e.g. "Verified Active", "Recycled", "Unknown"
    public var dnoMatched: Bool // Do Not Originate list match
    
    // Custom initializer
    public init(
        phoneNumber: String,
        callerName: String? = nil,
        carrier: String? = nil,
        categoryBreakdown: [String: Int] = [:],
        totalTags: Int = 0,
        lastUpdated: Date = Date(),
        isUserFlagged: Bool = false,
        reassignmentStatus: String? = nil,
        dnoMatched: Bool = false
    ) {
        self.phoneNumber = phoneNumber
        self.callerName = callerName
        self.carrier = carrier
        self.categoryBreakdown = categoryBreakdown
        self.totalTags = totalTags
        self.lastUpdated = lastUpdated
        self.isUserFlagged = isUserFlagged
        self.reassignmentStatus = reassignmentStatus
        self.dnoMatched = dnoMatched
    }
    
    // Helper to get the top reported category
    public var primaryCategory: String {
        if categoryBreakdown.isEmpty { return "Unknown" }
        return categoryBreakdown.max(by: { $0.value < $1.value })?.key ?? "Spam"
    }
    
    // Calculates dynamic threat tier based on configured threshold
    // Tier 1 (3-9 tags): Suspected Spam (Show warning label)
    // Tier 2 (10-49 tags): Silenced (Send to silent spam folder)
    // Tier 3 (50+ tags / DNO matched): Blocked (Block at system level)
    public func threatTier(threshold: Int) -> Int {
        if dnoMatched { return 3 }
        if isUserFlagged { return 3 } // If manually reported by this user, block immediately!
        
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
    
    // Text label for the threat level
    public func threatLabel(threshold: Int) -> String {
        switch threatTier(threshold: threshold) {
        case 3: return "Tier 3: Blocked"
        case 2: return "Tier 2: Silenced"
        case 1: return "Tier 1: Suspected"
        default: return "Low Risk"
        }
    }
}
