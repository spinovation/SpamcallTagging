package com.example.deepsci

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.example.deepsci.models.SpamNumber
import com.example.deepsci.services.SyncService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

class SpamManager private constructor(context: Context) {

    private val sharedPrefs = context.applicationContext.getSharedPreferences("group.com.deepsci.app", Context.MODE_PRIVATE)

    var spamNumbers by mutableStateOf<List<SpamNumber>>(emptyList())
        private set

    var escalationThreshold by mutableStateOf(10)
        private set

    var freeLookupsLeft by mutableStateOf(5)
        private set

    var purchasedCredits by mutableStateOf(0)
        private set

    var isSyncing by mutableStateOf(false)
        private set

    var taggerReputation by mutableStateOf(0.85)
        private set

    var activeShieldingEnabled by mutableStateOf(true)
        private set

    init {
        // Load settings
        escalationThreshold = sharedPrefs.getInt("com.spamcalltagging.threshold", 10)
        freeLookupsLeft = sharedPrefs.getInt("com.spamcalltagging.freeLookupsLeft", 5)
        purchasedCredits = sharedPrefs.getInt("com.spamcalltagging.purchasedCredits", 0)
        activeShieldingEnabled = sharedPrefs.getBoolean("com.spamcalltagging.activeShieldingEnabled", true)
        loadLocalData()
        calculateUserReputation()
    }

    private fun loadLocalData() {
        val jsonStr = sharedPrefs.getString("com.spamcalltagging.numbers_json", null)
        if (jsonStr != null) {
            try {
                spamNumbers = Json.decodeFromString<List<SpamNumber>>(jsonStr)
            } catch (e: Exception) {
                spamNumbers = emptyList()
            }
        }
        if (spamNumbers.isEmpty()) {
            // Seed data via SyncService
            syncData()
        }
    }

    private fun saveLocalData() {
        val jsonStr = Json.encodeToString(spamNumbers)
        sharedPrefs.edit().putString("com.spamcalltagging.numbers_json", jsonStr).apply()
    }

    fun updateThreshold(newThreshold: Int) {
        escalationThreshold = newThreshold
        sharedPrefs.edit().putInt("com.spamcalltagging.threshold", newThreshold).apply()
    }

    fun updateActiveShielding(enabled: Boolean) {
        activeShieldingEnabled = enabled
        sharedPrefs.edit().putBoolean("com.spamcalltagging.activeShieldingEnabled", enabled).apply()
    }

    fun buyCreditPack() {
        purchasedCredits += 10
        sharedPrefs.edit().putInt("com.spamcalltagging.purchasedCredits", purchasedCredits).apply()
    }

    fun syncData() {
        if (isSyncing) return
        isSyncing = true
        CoroutineScope(Dispatchers.Main).launch {
            try {
                val updatedList = SyncService.shared.fetchLatestUpdates(spamNumbers)
                spamNumbers = updatedList
                saveLocalData()
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                isSyncing = false
            }
        }
    }

    fun tagNumber(phoneNumber: String, category: String) {
        isSyncing = true
        CoroutineScope(Dispatchers.Main).launch {
            try {
                val success = SyncService.shared.submitTag(phoneNumber, category, taggerReputation)
                if (success) {
                    val cleanPhone = phoneNumber.filter { it.isDigit() || it == '+' }
                    val existing = spamNumbers.find { it.phoneNumber == cleanPhone }
                    if (existing != null) {
                        val updatedMap = existing.categoryBreakdown.toMutableMap()
                        updatedMap[category] = (updatedMap[category] ?: 0) + 1
                        spamNumbers = spamNumbers.map {
                            if (it.phoneNumber == cleanPhone) {
                                it.copy(
                                    totalTags = it.totalTags + 1,
                                    categoryBreakdown = updatedMap,
                                    isUserFlagged = true
                                )
                            } else it
                        }
                    } else {
                        val carrierSeed = listOf("AT&T", "Verizon", "T-Mobile", "Twilio", "Bandwidth").random()
                        val newSpam = SpamNumber(
                            phoneNumber = cleanPhone,
                            callerName = "Caller Report",
                            carrier = carrierSeed,
                            categoryBreakdown = mapOf(category to 1),
                            totalTags = 1,
                            isUserFlagged = true
                        )
                        spamNumbers = spamNumbers + newSpam
                    }
                    saveLocalData()
                    calculateUserReputation()
                }
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                isSyncing = false
            }
        }
    }

    fun submitAppeal(phoneNumber: String) {
        isSyncing = true
        CoroutineScope(Dispatchers.Main).launch {
            try {
                val success = SyncService.shared.resolveAppeal(phoneNumber)
                if (success) {
                    spamNumbers = spamNumbers.map {
                        if (it.phoneNumber == phoneNumber) {
                            it.copy(
                                totalTags = 0,
                                categoryBreakdown = mapOf("Not Spam" to 10),
                                isUserFlagged = false,
                                dnoMatched = false
                            )
                        } else it
                    }
                    saveLocalData()
                    calculateUserReputation()
                }
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                isSyncing = false
            }
        }
    }

    fun calculateUserReputation() {
        val totalReported = spamNumbers.count { it.isUserFlagged }
        if (totalReported == 0) {
            taggerReputation = 0.85
            return
        }
        var baseRep = 0.85 + (totalReported * 0.02)
        baseRep = minOf(baseRep, 0.95)

        var penalties = 0.0
        for (num in spamNumbers) {
            if (num.isUserFlagged && num.primaryCategory == "Not Spam") {
                penalties += 0.15
            }
        }
        taggerReputation = maxOf(0.10, baseRep - penalties)
    }

    fun performGlobalLookup(phone: String, onComplete: (SpamNumber?) -> Unit): Boolean {
        if (freeLookupsLeft > 0) {
            freeLookupsLeft -= 1
            sharedPrefs.edit().putInt("com.spamcalltagging.freeLookupsLeft", freeLookupsLeft).apply()
        } else if (purchasedCredits > 0) {
            purchasedCredits -= 1
            sharedPrefs.edit().putInt("com.spamcalltagging.purchasedCredits", purchasedCredits).apply()
        } else {
            return false
        }

        CoroutineScope(Dispatchers.Main).launch {
            delay(1500)
            val cleanNumber = phone.filter { it.isDigit() }
            val carrier = listOf("Verizon Wireless", "AT&T", "T-Mobile", "Twilio", "Bandwidth.com").random()
            
            var name = "Potential Spam"
            if (cleanNumber.endsWith("187") || phone.contains("510")) {
                name = "Oakland Delivery"
            } else if (cleanNumber.endsWith("199") || phone.contains("800")) {
                name = "IRS Tax Administration"
            } else if (cleanNumber.endsWith("155") || phone.contains("312")) {
                name = "Auto Warranty Center"
            } else {
                val businessNames = listOf("Capital Debt Solutions", "Healthcare Enrollments", "Student Relief Association", "National Power & Gas", "Vacation Rewards Center")
                name = businessNames.random()
            }
            
            val lookupResult = SpamNumber(
                phoneNumber = phone,
                callerName = name,
                carrier = carrier,
                categoryBreakdown = mapOf("Spam/Telemarketing" to 1),
                totalTags = 1,
                isUserFlagged = false
            )
            
            if (!spamNumbers.any { it.phoneNumber == phone }) {
                spamNumbers = spamNumbers + lookupResult
                saveLocalData()
            }
            onComplete(lookupResult)
        }
        return true
    }

    companion object {
        private var instance: SpamManager? = null

        fun initialize(context: Context): SpamManager {
            return instance ?: synchronized(this) {
                instance ?: SpamManager(context).also { instance = it }
            }
        }

        fun getInstance(): SpamManager {
            return instance ?: throw IllegalStateException("SpamManager not initialized. Call initialize(context) first.")
        }

        fun formatPhoneNumber(phone: String): String {
            val clean = phone.filter { it.isDigit() }
            return when {
                clean.length == 10 -> {
                    val area = clean.substring(0, 3)
                    val prefix = clean.substring(3, 6)
                    val suffix = clean.substring(6, 10)
                    "($area) $prefix-$suffix"
                }
                clean.length == 11 && clean.startsWith("1") -> {
                    val area = clean.substring(1, 4)
                    val prefix = clean.substring(4, 7)
                    val suffix = clean.substring(7, 11)
                    "+1 ($area) $prefix-$suffix"
                }
                else -> {
                    if (phone.startsWith("+")) phone
                    else if (phone.all { it.isDigit() }) "+$phone"
                    else phone
                }
            }
        }
    }
}
