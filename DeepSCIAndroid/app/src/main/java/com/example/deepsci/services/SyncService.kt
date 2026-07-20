package com.example.deepsci.services

import com.example.deepsci.models.SpamNumber
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class SyncService private constructor() {
    
    companion object {
        private var globalServerDatabase: MutableList<SpamNumber> = mutableListOf()
        val shared = SyncService()
    }
    
    init {
        if (globalServerDatabase.isEmpty()) {
            globalServerDatabase = getSeedSpamNumbers().toMutableList()
        }
    }
    
    private fun getSeedSpamNumbers(): List<SpamNumber> {
        val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)
        val nowStr = sdf.format(Date())
        return listOf(
            SpamNumber(
                phoneNumber = "+18005550199",
                callerName = "IRS Tax Administration",
                carrier = "Bandwidth.com",
                categoryBreakdown = mapOf("Scam/Fraud" to 84, "Robocall" to 12),
                totalTags = 96,
                lastUpdatedString = nowStr,
                isUserFlagged = false,
                reassignmentStatus = "Verified Active",
                dnoMatched = true
            ),
            SpamNumber(
                phoneNumber = "+18882345678",
                callerName = "Student Loan Forgiveness",
                carrier = "Inteliquent",
                categoryBreakdown = mapOf("Spam/Telemarketing" to 42, "Robocall" to 38, "Scam/Fraud" to 8),
                totalTags = 88,
                lastUpdatedString = nowStr,
                isUserFlagged = false,
                reassignmentStatus = "Unknown",
                dnoMatched = false
            ),
            SpamNumber(
                phoneNumber = "+12125550143",
                callerName = "NYC Utility Corp",
                carrier = "Verizon Wireless",
                categoryBreakdown = mapOf("Scam/Fraud" to 14, "Robocall" to 2),
                totalTags = 16,
                lastUpdatedString = nowStr,
                isUserFlagged = false,
                reassignmentStatus = "Verified Active",
                dnoMatched = false
            ),
            SpamNumber(
                phoneNumber = "+13125550155",
                callerName = "Auto Warranty CenterCenter",
                carrier = "Twilio",
                categoryBreakdown = mapOf("Spam/Telemarketing" to 55, "Robocall" to 21),
                totalTags = 76,
                lastUpdatedString = nowStr,
                isUserFlagged = false,
                reassignmentStatus = "Unknown",
                dnoMatched = false
            ),
            SpamNumber(
                phoneNumber = "+14155550162",
                callerName = "San Francisco School District",
                carrier = "AT&T",
                categoryBreakdown = mapOf("Not Spam" to 15, "Spam/Telemarketing" to 1),
                totalTags = 16,
                lastUpdatedString = nowStr,
                isUserFlagged = false,
                reassignmentStatus = "Verified Active",
                dnoMatched = false
            ),
            SpamNumber(
                phoneNumber = "+16175550181",
                callerName = "Free Cruise Rewards",
                carrier = "Peerless Network",
                categoryBreakdown = mapOf("Scam/Fraud" to 32, "Robocall" to 24, "Spam/Telemarketing" to 18),
                totalTags = 74,
                lastUpdatedString = nowStr,
                isUserFlagged = false,
                reassignmentStatus = "Unknown",
                dnoMatched = false
            ),
            SpamNumber(
                phoneNumber = "+12065550121",
                callerName = "Amazon Order Security",
                carrier = "Sinclaire Telecom",
                categoryBreakdown = mapOf("Scam/Fraud" to 8, "Robocall" to 1),
                totalTags = 9,
                lastUpdatedString = nowStr,
                isUserFlagged = false,
                reassignmentStatus = "Unknown",
                dnoMatched = false
            ),
            SpamNumber(
                phoneNumber = "+17025550110",
                callerName = "Las Vegas Casino VIP",
                carrier = "Vonage",
                categoryBreakdown = mapOf("Spam/Telemarketing" to 6, "Robocall" to 2),
                totalTags = 8,
                lastUpdatedString = nowStr,
                isUserFlagged = false,
                reassignmentStatus = "Unknown",
                dnoMatched = false
            ),
            SpamNumber(
                phoneNumber = "+13055550102",
                callerName = "Miami Beach Resort",
                carrier = "T-Mobile",
                categoryBreakdown = mapOf("Spam/Telemarketing" to 4, "Robocall" to 1),
                totalTags = 5,
                lastUpdatedString = nowStr,
                isUserFlagged = false,
                reassignmentStatus = "Recycled",
                dnoMatched = false
            )
        )
    }

    suspend fun fetchLatestUpdates(localNumbers: List<SpamNumber>): List<SpamNumber> = withContext(Dispatchers.IO) {
        delay(1000) // Simulate network delay
        val serverList = globalServerDatabase.toMutableList()
        
        // Simulate background crowdsourcing activity from other users
        if (serverList.isNotEmpty()) {
            val randomIndex = (0 until serverList.size).random()
            val existing = serverList[randomIndex]
            val updatedCategoryMap = existing.categoryBreakdown.toMutableMap()
            val primary = existing.primaryCategory
            updatedCategoryMap[primary] = (updatedCategoryMap[primary] ?: 0) + 1
            
            serverList[randomIndex] = existing.copy(
                totalTags = existing.totalTags + 1,
                categoryBreakdown = updatedCategoryMap,
                lastUpdatedString = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US).format(Date())
            )
            globalServerDatabase = serverList
        }
        
        // Merge server listings with client local overrides (like user flagged state)
        serverList.map { serverNum ->
            val localMatch = localNumbers.find { it.phoneNumber == serverNum.phoneNumber }
            if (localMatch != null) {
                serverNum.copy(isUserFlagged = localMatch.isUserFlagged)
            } else {
                serverNum
            }
        }
    }

    suspend fun submitTag(phoneNumber: String, category: String, localReputation: Double): Boolean = withContext(Dispatchers.IO) {
        delay(800) // Network delay
        val serverList = globalServerDatabase.toMutableList()
        val index = serverList.indexOfFirst { it.phoneNumber == phoneNumber }
        
        val nowStr = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US).format(Date())
        
        if (index != -1) {
            val existing = serverList[index]
            val updatedCategoryMap = existing.categoryBreakdown.toMutableMap()
            updatedCategoryMap[category] = (updatedCategoryMap[category] ?: 0) + 1
            
            serverList[index] = existing.copy(
                totalTags = existing.totalTags + 1,
                categoryBreakdown = updatedCategoryMap,
                lastUpdatedString = nowStr
            )
        } else {
            // New spam number reported
            val carrierSeed = listOf("AT&T", "Verizon", "T-Mobile", "Twilio", "Bandwidth").random()
            serverList.add(
                SpamNumber(
                    phoneNumber = phoneNumber,
                    callerName = "Caller Report",
                    carrier = carrierSeed,
                    categoryBreakdown = mapOf(category to 1),
                    totalTags = 1,
                    lastUpdatedString = nowStr,
                    isUserFlagged = true,
                    reassignmentStatus = "Unknown",
                    dnoMatched = false
                )
            )
        }
        
        globalServerDatabase = serverList
        true
    }

    suspend fun resolveAppeal(phoneNumber: String): Boolean = withContext(Dispatchers.IO) {
        delay(1000)
        val serverList = globalServerDatabase.toMutableList()
        val index = serverList.indexOfFirst { it.phoneNumber == phoneNumber }
        
        if (index != -1) {
            val existing = serverList[index]
            // Clear spam flags by resetting breakdowns to "Not Spam" dominance
            serverList[index] = existing.copy(
                totalTags = 0,
                categoryBreakdown = mapOf("Not Spam" to 10),
                lastUpdatedString = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US).format(Date()),
                isUserFlagged = false,
                dnoMatched = false
            )
            globalServerDatabase = serverList
            true
        } else {
            false
        }
    }
}
