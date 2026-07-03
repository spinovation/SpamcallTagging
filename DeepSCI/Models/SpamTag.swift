import Foundation

public struct SpamTag: Codable, Identifiable, Hashable {
    public let id: UUID
    public let phoneNumber: String
    public let category: String
    public let timestamp: Date
    public let geoRegion: String // Coarse location (e.g., area code or state name)
    public var userReputationWeight: Double // Weight based on tagger reputation (0.0 to 1.0)
    
    public init(
        id: UUID = UUID(),
        phoneNumber: String,
        category: String,
        timestamp: Date = Date(),
        geoRegion: String,
        userReputationWeight: Double = 1.0
    ) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.category = category
        self.timestamp = timestamp
        self.geoRegion = geoRegion
        self.userReputationWeight = userReputationWeight
    }
}
