package com.example.deepsci.ui

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.provider.CallLog
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import com.example.deepsci.SpamManager
import com.example.deepsci.models.SpamNumber
import com.example.deepsci.theme.*
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

data class CallLogEntry(
    val phoneNumber: String,
    val callerName: String?,
    val timestamp: Long,
    val type: Int // 1: Incoming, 2: Outgoing, 3: Missed
)

@Composable
fun CallLogScreen(
    spamManager: SpamManager,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    var hasCallLogPermission by remember {
        mutableStateOf(
            ContextCompat.checkSelfPermission(context, Manifest.permission.READ_CALL_LOG) == PackageManager.PERMISSION_GRANTED
        )
    }

    val launcher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission(),
        onResult = { granted ->
            hasCallLogPermission = granted
        }
    )

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(DarkBg)
            .padding(16.dp)
    ) {
        Text(
            text = "Call History",
            fontSize = 32.sp,
            fontWeight = FontWeight.Bold,
            color = Color.White,
            modifier = Modifier.padding(bottom = 20.dp)
        )

        if (!hasCallLogPermission) {
            // Permission Request Card
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f),
                contentAlignment = Alignment.Center
            ) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = DarkSurfaceCard),
                    shape = RoundedCornerShape(16.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(56.dp)
                                .clip(RoundedCornerShape(28.dp))
                                .background(NeutralBlue.copy(alpha = 0.1f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(Icons.Default.Call, contentDescription = "Call Log", tint = NeutralBlue, modifier = Modifier.size(28.dp))
                        }
                        
                        Text(
                            text = "Access System Call History",
                            fontSize = 18.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                        
                        Text(
                            text = "Unlike iOS, Android allows third-party apps to access the system's incoming call history database. Grant permission to see recent calls and flag spammers instantly.",
                            fontSize = 13.sp,
                            color = TextSecondary,
                            modifier = Modifier.padding(horizontal = 8.dp),
                            lineHeight = 18.sp
                        )

                        Button(
                            onClick = { launcher.launch(Manifest.permission.READ_CALL_LOG) },
                            colors = ButtonDefaults.buttonColors(containerColor = BrandRed),
                            shape = RoundedCornerShape(10.dp)
                        ) {
                            Text("Enable Call Log Integration", color = Color.White, fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }
        } else {
            // Display System Call Log
            val callLogs = remember(spamManager.spamNumbers) { readCallLogs(context) }
            
            LazyColumn(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                items(callLogs) { entry ->
                    val cleanPhone = entry.phoneNumber.filter { it.isDigit() || it == '+' }
                    val dbMatch = spamManager.spamNumbers.find { it.phoneNumber == cleanPhone }
                    
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(12.dp))
                            .background(DarkSurfaceCard)
                            .padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Icon indicator
                        val isBlocked = dbMatch?.threatTier(spamManager.escalationThreshold) ?: 0 >= 2
                        val iconBg = if (isBlocked) ScamRed.copy(alpha = 0.15f) else SafeGreen.copy(alpha = 0.15f)
                        val iconColor = if (isBlocked) ScamRed else SafeGreen
                        
                        Box(
                            modifier = Modifier
                                .size(40.dp)
                                .clip(RoundedCornerShape(20.dp))
                                .background(iconBg),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = if (isBlocked) Icons.Default.Warning else Icons.Default.Call,
                                contentDescription = if (isBlocked) "Blocked" else "Call",
                                tint = iconColor,
                                modifier = Modifier.size(18.dp)
                            )
                        }

                        Column(
                            modifier = Modifier
                                .padding(start = 12.dp)
                                .weight(1f)
                        ) {
                            Text(
                                text = SpamManager.formatPhoneNumber(entry.phoneNumber),
                                fontSize = 15.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color.White
                            )
                            val typeLabel = when (entry.type) {
                                3 -> "Missed Call"
                                2 -> "Outgoing Call"
                                else -> "Incoming Call"
                            }
                            Text(
                                text = "$typeLabel • ${entry.callerName ?: dbMatch?.callerName ?: "Unknown Caller"}",
                                fontSize = 11.sp,
                                color = TextSecondary,
                                modifier = Modifier.padding(top = 2.dp)
                            )
                        }

                        // Quick tag button
                        if (isBlocked) {
                            Text(
                                text = "Blocked",
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                color = ScamRed,
                                modifier = Modifier.padding(horizontal = 8.dp)
                            )
                        } else {
                            Button(
                                onClick = { spamManager.tagNumber(entry.phoneNumber, "Scam/Fraud") },
                                colors = ButtonDefaults.buttonColors(containerColor = BrandRed.copy(alpha = 0.15f)),
                                shape = RoundedCornerShape(8.dp),
                                contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp),
                                modifier = Modifier.height(28.dp)
                            ) {
                                Text("Block", color = BrandRed, fontSize = 11.sp, fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                }
            }
        }
    }
}

private fun readCallLogs(context: Context): List<CallLogEntry> {
    val list = mutableListOf<CallLogEntry>()
    val hasPermission = ContextCompat.checkSelfPermission(context, Manifest.permission.READ_CALL_LOG) == PackageManager.PERMISSION_GRANTED
    
    if (hasPermission) {
        val resolver = context.contentResolver
        val cursor = resolver.query(
            CallLog.Calls.CONTENT_URI,
            arrayOf(CallLog.Calls.NUMBER, CallLog.Calls.CACHED_NAME, CallLog.Calls.DATE, CallLog.Calls.TYPE),
            null,
            null,
            CallLog.Calls.DATE + " DESC LIMIT 50"
        )
        
        cursor?.use {
            val numIdx = it.getColumnIndex(CallLog.Calls.NUMBER)
            val nameIdx = it.getColumnIndex(CallLog.Calls.CACHED_NAME)
            val dateIdx = it.getColumnIndex(CallLog.Calls.DATE)
            val typeIdx = it.getColumnIndex(CallLog.Calls.TYPE)
            
            while (it.moveToNext()) {
                val num = it.getString(numIdx) ?: ""
                val name = it.getString(nameIdx)
                val dateVal = it.getLong(dateIdx)
                val typeVal = it.getInt(typeIdx)
                if (num.isNotEmpty()) {
                    list.add(CallLogEntry(num, name, dateVal, typeVal))
                }
            }
        }
    }
    
    // Seed mock calls if list is empty (e.g. running on blank emulator)
    if (list.isEmpty()) {
        val now = System.currentTimeMillis()
        list.addAll(
            listOf(
                CallLogEntry("+18005550199", "IRS Tax Administration", now - 1000 * 60 * 12, 1), // Blocked Scam
                CallLogEntry("+18882345678", "Student Loan Center", now - 1000 * 60 * 60 * 2, 3), // Blocked Robocall
                CallLogEntry("+14155550162", "SF School District", now - 1000 * 60 * 60 * 5, 1), // Safe
                CallLogEntry("+12065550121", "Amazon Security", now - 1000 * 60 * 60 * 24, 3), // Blocked
                CallLogEntry("+16505550100", "Mom", now - 1000 * 60 * 60 * 30, 1) // Safe
            )
        )
    }
    
    return list
}
