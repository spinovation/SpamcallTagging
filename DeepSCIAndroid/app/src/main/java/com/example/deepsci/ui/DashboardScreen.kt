package com.example.deepsci.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.deepsci.SpamManager
import com.example.deepsci.theme.*

@Composable
fun DashboardScreen(
    spamManager: SpamManager,
    modifier: Modifier = Modifier
) {
    val spamNumbers = spamManager.spamNumbers
    val totalBlocked = spamNumbers.count { it.threatTier(spamManager.escalationThreshold) >= 2 }
    val userReports = spamNumbers.count { it.isUserFlagged }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(DarkBg)
            .padding(16.dp)
    ) {
        Text(
            text = "Dashboard",
            fontSize = 32.sp,
            fontWeight = FontWeight.Bold,
            color = Color.White,
            modifier = Modifier.padding(bottom = 20.dp)
        )

        // Shielding Card
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 16.dp),
            colors = CardDefaults.cardColors(containerColor = DarkSurfaceCard),
            shape = RoundedCornerShape(16.dp)
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = "Active Shielding",
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                    Text(
                        text = if (spamManager.activeShieldingEnabled) "Real-time shielding active" else "Real-time shielding paused",
                        fontSize = 13.sp,
                        color = if (spamManager.activeShieldingEnabled) SafeGreen else TextSecondary
                    )
                }
                Switch(
                    checked = spamManager.activeShieldingEnabled,
                    onCheckedChange = { spamManager.updateActiveShielding(it) },
                    colors = SwitchDefaults.colors(
                        checkedThumbColor = Color.White,
                        checkedTrackColor = BrandRed,
                        uncheckedThumbColor = Color.LightGray,
                        uncheckedTrackColor = Color.DarkGray
                    )
                )
            }
        }

        // Stats Cards Row
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 20.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Card(
                modifier = Modifier.weight(1f),
                colors = CardDefaults.cardColors(containerColor = DarkSurfaceCard),
                shape = RoundedCornerShape(16.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(text = "Total Blocked", fontSize = 12.sp, color = TextSecondary)
                    Text(
                        text = totalBlocked.toString(),
                        fontSize = 28.sp,
                        fontWeight = FontWeight.Bold,
                        color = BrandRed,
                        modifier = Modifier.padding(top = 4.dp)
                    )
                }
            }
            Card(
                modifier = Modifier.weight(1f),
                colors = CardDefaults.cardColors(containerColor = DarkSurfaceCard),
                shape = RoundedCornerShape(16.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(text = "Your Reports", fontSize = 12.sp, color = TextSecondary)
                    Text(
                        text = userReports.toString(),
                        fontSize = 28.sp,
                        fontWeight = FontWeight.Bold,
                        color = SafeGreen,
                        modifier = Modifier.padding(top = 4.dp)
                    )
                }
            }
        }

        // Recent Block Logs Header
        Text(
            text = "Recent Interceptions",
            fontSize = 18.sp,
            fontWeight = FontWeight.Bold,
            color = Color.White,
            modifier = Modifier.padding(bottom = 12.dp)
        )

        val blockedNumbers = spamNumbers.filter { it.threatTier(spamManager.escalationThreshold) >= 2 }
        
        if (blockedNumbers.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "No recent blocked calls.",
                    fontSize = 14.sp,
                    color = TextSecondary
                )
            }
        } else {
            LazyColumn(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                items(blockedNumbers) { number ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(12.dp))
                            .background(DarkSurfaceCard)
                            .padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Box(
                            modifier = Modifier
                                .size(40.dp)
                                .clip(RoundedCornerShape(20.dp))
                                .background(BrandRed.copy(alpha = 0.1f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.Warning,
                                contentDescription = "Blocked",
                                tint = BrandRed,
                                modifier = Modifier.size(20.dp)
                            )
                        }
                        
                        Column(
                            modifier = Modifier
                                .padding(start = 12.dp)
                                .weight(1f)
                        ) {
                            Text(
                                text = SpamManager.formatPhoneNumber(number.phoneNumber),
                                fontSize = 15.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color.White
                            )
                            Text(
                                text = number.callerName ?: "Spam Campaign",
                                fontSize = 12.sp,
                                color = TextSecondary
                            )
                        }

                        Column(horizontalAlignment = Alignment.End) {
                            Text(
                                text = number.primaryCategory,
                                fontSize = 11.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = BrandRed
                            )
                            Text(
                                text = "Tier ${number.threatTier(spamManager.escalationThreshold)}",
                                fontSize = 10.sp,
                                color = TextSecondary
                            )
                        }
                    }
                }
            }
        }
    }
}
