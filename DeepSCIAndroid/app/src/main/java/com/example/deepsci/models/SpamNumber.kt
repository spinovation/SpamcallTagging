package com.example.deepsci.models

import kotlinx.serialization.Serializable

@Serializable
data class SpamNumber(
    val phoneNumber: String,
    val callerName: String? = null,
    val carrier: String? = null,
    val categoryBreakdown: Map<String, Int> = emptyMap(),
    val totalTags: Int = 0,
    val lastUpdatedString: String = "",
    var isUserFlagged: Boolean = false,
    val reassignmentStatus: String? = null,
    val dnoMatched: Boolean = false
) {
    val primaryCategory: String
        get() {
            if (categoryBreakdown.isEmpty()) return "Unknown"
            return categoryBreakdown.maxByOrNull { it.value }?.key ?: "Spam"
        }

    fun threatTier(threshold: Int): Int {
        if (dnoMatched) return 3
        if (isUserFlagged) return 3
        
        val tier1Threshold = maxOf(1, threshold / 3)
        val tier2Threshold = threshold
        val tier3Threshold = threshold * 5
        
        return when {
            totalTags >= tier3Threshold -> 3
            totalTags >= tier2Threshold -> 2
            totalTags >= tier1Threshold -> 1
            else -> 0
        }
    }

    fun threatLabel(threshold: Int): String {
        return when (threatTier(threshold)) {
            3 -> "Tier 3: Blocked"
            2 -> "Tier 2: Silenced"
            1 -> "Tier 1: Suspected"
            else -> "Low Risk"
        }
    }
}
