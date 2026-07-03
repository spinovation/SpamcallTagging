import Foundation

public final class SyncService {
    public static let shared = SyncService()
    
    // Simulates the shared, global server database that all users sync with.
    // In a production environment, this would be a cloud database (e.g. Firestore / REST API).
    private static var globalServerDatabase: [SpamNumber] = []
    
    private init() {
        // Initialize the global server cache with seed data if it's empty
        if SyncService.globalServerDatabase.isEmpty {
            SyncService.globalServerDatabase = getSeedSpamNumbers()
        }
    }
    
    // Generates a seed list of initial spam numbers representing active campaigns
    public func getSeedSpamNumbers() -> [SpamNumber] {
        let calendar = Calendar.current
        let now = Date()
        
        return [
            SpamNumber(
                phoneNumber: "+18005550199",
                callerName: "IRS Tax Administration",
                carrier: "Bandwidth.com",
                categoryBreakdown: ["Scam/Fraud": 84, "Robocall": 12],
                totalTags: 96,
                lastUpdated: calendar.date(byAdding: .minute, value: -12, to: now) ?? now,
                isUserFlagged: false,
                reassignmentStatus: "Verified Active",
                dnoMatched: true
            ),
            SpamNumber(
                phoneNumber: "+18882345678",
                callerName: "Student Loan Forgiveness",
                carrier: "Inteliquent",
                categoryBreakdown: ["Spam/Telemarketing": 42, "Robocall": 38, "Scam/Fraud": 8],
                totalTags: 88,
                lastUpdated: calendar.date(byAdding: .hour, value: -2, to: now) ?? now,
                isUserFlagged: false,
                reassignmentStatus: "Unknown",
                dnoMatched: false
            ),
            SpamNumber(
                phoneNumber: "+12125550143",
                callerName: "NYC Utility Corp",
                carrier: "Verizon Wireless",
                categoryBreakdown: ["Scam/Fraud": 14, "Robocall": 2],
                totalTags: 16,
                lastUpdated: calendar.date(byAdding: .minute, value: -45, to: now) ?? now,
                isUserFlagged: false,
                reassignmentStatus: "Verified Active",
                dnoMatched: false
            ),
            SpamNumber(
                phoneNumber: "+13125550155",
                callerName: "Auto Warranty Center",
                carrier: "Twilio",
                categoryBreakdown: ["Spam/Telemarketing": 55, "Robocall": 21],
                totalTags: 76,
                lastUpdated: calendar.date(byAdding: .hour, value: -1, to: now) ?? now,
                isUserFlagged: false,
                reassignmentStatus: "Unknown",
                dnoMatched: false
            ),
            SpamNumber(
                phoneNumber: "+14155550162",
                callerName: "San Francisco Unified School District",
                carrier: "AT&T",
                categoryBreakdown: ["Not Spam": 15, "Spam/Telemarketing": 1],
                totalTags: 16,
                lastUpdated: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                isUserFlagged: false,
                reassignmentStatus: "Verified Active",
                dnoMatched: false
            ),
            SpamNumber(
                phoneNumber: "+16175550181",
                callerName: "Free Cruise Rewards",
                carrier: "Peerless Network",
                categoryBreakdown: ["Scam/Fraud": 32, "Robocall": 24, "Spam/Telemarketing": 18],
                totalTags: 74,
                lastUpdated: calendar.date(byAdding: .minute, value: -5, to: now) ?? now,
                isUserFlagged: false,
                reassignmentStatus: "Unknown",
                dnoMatched: false
            ),
            SpamNumber(
                phoneNumber: "+12065550121",
                callerName: "Amazon Order Security",
                carrier: "Sinclaire Telecom",
                categoryBreakdown: ["Scam/Fraud": 8, "Robocall": 1],
                totalTags: 9,
                lastUpdated: calendar.date(byAdding: .minute, value: -2, to: now) ?? now,
                isUserFlagged: false,
                reassignmentStatus: "Unknown",
                dnoMatched: false
            ),
            SpamNumber(
                phoneNumber: "+17025550110",
                callerName: "Las Vegas Casino VIP",
                carrier: "Vonage",
                categoryBreakdown: ["Spam/Telemarketing": 6, "Robocall": 2],
                totalTags: 8,
                lastUpdated: calendar.date(byAdding: .hour, value: -4, to: now) ?? now,
                isUserFlagged: false,
                reassignmentStatus: "Unknown",
                dnoMatched: false
            ),
            SpamNumber(
                phoneNumber: "+13055550102",
                callerName: "Miami Beach Resort",
                carrier: "T-Mobile",
                categoryBreakdown: ["Spam/Telemarketing": 4, "Robocall": 1],
                totalTags: 5,
                lastUpdated: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                isUserFlagged: false,
                reassignmentStatus: "Recycled",
                dnoMatched: false
            )
        ]
    }
    
    // Simulates pulling data from the global crowdsourced server (syncing replication changes from other users)
    public func fetchLatestUpdates(completion: @escaping (Result<[SpamNumber], Error>) -> Void) {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1.0) {
            var serverList = SyncService.globalServerDatabase
            let localList = DatabaseManager.shared.loadSpamNumbers()
            
            // For high fidelity: simulate ANOTHER user somewhere in the world tagging a number in the background.
            // This models crowdsourced replication: other users' actions sync down to this device.
            if !serverList.isEmpty {
                let indexToFlag = abs(Date().timeIntervalSince1970.hashValue) % serverList.count
                var spamNum = serverList[indexToFlag]
                spamNum.totalTags += 1
                spamNum.categoryBreakdown[spamNum.primaryCategory, default: 0] += 1
                spamNum.lastUpdated = Date()
                serverList[indexToFlag] = spamNum
                SyncService.globalServerDatabase = serverList
            }
            
            // Merge server replication updates with this client's user-flagged state
            var mergedList: [SpamNumber] = []
            for serverNum in serverList {
                var mergedNum = serverNum
                if let localNum = localList.first(where: { $0.phoneNumber == serverNum.phoneNumber }) {
                    mergedNum.isUserFlagged = localNum.isUserFlagged
                }
                mergedList.append(mergedNum)
            }
            
            DatabaseManager.shared.saveSpamNumbers(mergedList)
            completion(.success(mergedList))
        }
    }
    
    // Simulates pushing a user-submitted tag to the global crowdsourcing server, replicating it to other users
    public func submitTag(_ tag: SpamTag, completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.8) {
            
            // 1. Update the Global Server Database (replicates the tag so other users see it on sync)
            var serverList = SyncService.globalServerDatabase
            if let idx = serverList.firstIndex(where: { $0.phoneNumber == tag.phoneNumber }) {
                var spamNum = serverList[idx]
                spamNum.totalTags += 1
                spamNum.categoryBreakdown[tag.category, default: 0] += 1
                spamNum.lastUpdated = Date()
                serverList[idx] = spamNum
            } else {
                let newSpam = SpamNumber(
                    phoneNumber: tag.phoneNumber,
                    callerName: nil,
                    carrier: "Unknown Carrier",
                    categoryBreakdown: [tag.category: 1],
                    totalTags: 1,
                    lastUpdated: Date(),
                    isUserFlagged: false, // The global server doesn't mark it flagged by 'you' for other users
                    reassignmentStatus: "Unknown",
                    dnoMatched: false
                )
                serverList.append(newSpam)
            }
            SyncService.globalServerDatabase = serverList
            
            // 2. Also update our local database copy immediately so the current user sees it without waiting for next sync
            var localList = DatabaseManager.shared.loadSpamNumbers()
            if let idx = localList.firstIndex(where: { $0.phoneNumber == tag.phoneNumber }) {
                var spamNum = localList[idx]
                spamNum.totalTags += 1
                spamNum.categoryBreakdown[tag.category, default: 0] += 1
                spamNum.lastUpdated = Date()
                spamNum.isUserFlagged = true
                localList[idx] = spamNum
            } else {
                let newSpam = SpamNumber(
                    phoneNumber: tag.phoneNumber,
                    callerName: nil,
                    carrier: "Unknown Carrier",
                    categoryBreakdown: [tag.category: 1],
                    totalTags: 1,
                    lastUpdated: Date(),
                    isUserFlagged: true,
                    reassignmentStatus: "Unknown",
                    dnoMatched: false
                )
                localList.append(newSpam)
            }
            DatabaseManager.shared.saveSpamNumbers(localList)
            
            // 3. Save to user's personal tag history
            var userTags = DatabaseManager.shared.loadUserTags()
            userTags.append(tag)
            DatabaseManager.shared.saveUserTags(userTags)
            
            completion(.success(()))
        }
    }
    
    // Simulates resolving an appeal (removing flags globally)
    public func resolveAppeal(for phoneNumber: String, completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1.2) {
            
            // 1. Clear globally
            var serverList = SyncService.globalServerDatabase
            if let idx = serverList.firstIndex(where: { $0.phoneNumber == phoneNumber }) {
                var spamNum = serverList[idx]
                spamNum.totalTags = 0
                spamNum.categoryBreakdown = ["Not Spam": 10]
                spamNum.callerName = spamNum.callerName ?? "Verified Caller"
                spamNum.reassignmentStatus = "Verified Active"
                spamNum.dnoMatched = false
                serverList[idx] = spamNum
                SyncService.globalServerDatabase = serverList
            }
            
            // 2. Clear locally
            var localList = DatabaseManager.shared.loadSpamNumbers()
            if let idx = localList.firstIndex(where: { $0.phoneNumber == phoneNumber }) {
                var spamNum = localList[idx]
                spamNum.totalTags = 0
                spamNum.categoryBreakdown = ["Not Spam": 10]
                spamNum.callerName = spamNum.callerName ?? "Verified Caller"
                spamNum.reassignmentStatus = "Verified Active"
                spamNum.dnoMatched = false
                localList[idx] = spamNum
                DatabaseManager.shared.saveSpamNumbers(localList)
                completion(.success(()))
            } else {
                completion(.failure(NSError(domain: "SyncService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Phone number not found"])))
            }
        }
    }
}
