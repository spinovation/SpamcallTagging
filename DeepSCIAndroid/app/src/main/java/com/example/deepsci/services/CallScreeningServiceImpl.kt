package com.example.deepsci.services

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.telecom.Call
import android.telecom.CallScreeningService
import androidx.core.app.NotificationCompat
import com.example.deepsci.MainActivity
import com.example.deepsci.SpamManager
import com.example.deepsci.models.SpamNumber
import kotlinx.serialization.json.Json

class CallScreeningServiceImpl : CallScreeningService() {

    override fun onScreenCall(callDetails: Call.Details) {
        val handle = callDetails.handle
        if (handle == null || handle.scheme != "tel") {
            respondWithAllow(callDetails)
            return
        }

        val rawNumber = handle.schemeSpecificPart
        val cleanNumber = rawNumber.filter { it.isDigit() || it == '+' }

        // Read preferences directly since CallScreeningService runs in background process
        val sharedPrefs = getSharedPreferences("group.com.deepsci.app", Context.MODE_PRIVATE)
        val activeShielding = sharedPrefs.getBoolean("com.spamcalltagging.activeShieldingEnabled", true)
        
        if (!activeShielding) {
            respondWithAllow(callDetails)
            return
        }

        val threshold = sharedPrefs.getInt("com.spamcalltagging.threshold", 10)
        val jsonStr = sharedPrefs.getString("com.spamcalltagging.numbers_json", null)
        
        val spamNumbers: List<SpamNumber> = if (jsonStr != null) {
            try {
                Json.decodeFromString<List<SpamNumber>>(jsonStr)
            } catch (e: Exception) {
                emptyList()
            }
        } else {
            emptyList()
        }

        // Match clean E164 phone numbers
        val match = spamNumbers.find { 
            val cleanDb = it.phoneNumber.filter { c -> c.isDigit() || c == '+' }
            cleanDb == cleanNumber || cleanDb.contains(cleanNumber.replace("+", "")) || cleanNumber.contains(cleanDb.replace("+", ""))
        }

        if (match != null) {
            val tier = match.threatTier(threshold)
            if (tier >= 2) {
                // Reject the call
                val response = CallResponse.Builder()
                    .setDisallowCall(true)
                    .setRejectCall(true)
                    .setSkipCallLog(false)
                    .setSkipNotification(true)
                    .build()
                
                respondToCall(callDetails, response)
                showBlockNotification(rawNumber, match.callerName ?: "Spam Sender", match.primaryCategory)
                return
            }
        }

        respondWithAllow(callDetails)
    }

    private fun respondWithAllow(callDetails: Call.Details) {
        val response = CallResponse.Builder()
            .setDisallowCall(false)
            .setRejectCall(false)
            .setSkipCallLog(false)
            .setSkipNotification(false)
            .build()
        respondToCall(callDetails, response)
    }

    private fun showBlockNotification(phoneNumber: String, name: String, category: String) {
        val channelId = "spam_blocked_channel"
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Blocked Calls Log",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Deep SCI logs of call interceptions"
            }
            notificationManager.createNotificationChannel(channel)
        }

        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val formattedPhone = SpamManager.formatPhoneNumber(phoneNumber)
        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(android.R.drawable.stat_notify_error)
            .setContentTitle("Spam Call Blocked")
            .setContentText("Intercepted: $formattedPhone ($name) - $category")
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()

        notificationManager.notify(phoneNumber.hashCode(), notification)
    }
}
