package com.example.deepsci.ui

import java.util.Locale
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Info
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
fun SettingsScreen(
    spamManager: SpamManager,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(DarkBg)
            .padding(16.dp)
    ) {
        Text(
            text = "Settings",
            fontSize = 32.sp,
            fontWeight = FontWeight.Bold,
            color = Color.White,
            modifier = Modifier.padding(bottom = 20.dp)
        )

        // Threshold Customizer Section
        Text(
            text = "Crowd Consensus Threshold",
            fontSize = 16.sp,
            fontWeight = FontWeight.Bold,
            color = Color.White,
            modifier = Modifier.padding(bottom = 8.dp)
        )
        
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 20.dp),
            colors = CardDefaults.cardColors(containerColor = DarkSurfaceCard),
            shape = RoundedCornerShape(16.dp)
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(text = "Escalation Minimum", fontSize = 14.sp, color = TextSecondary)
                    Text(text = "${spamManager.escalationThreshold} Tags", fontSize = 14.sp, fontWeight = FontWeight.Bold, color = BrandRed)
                }

                Slider(
                    value = spamManager.escalationThreshold.toFloat(),
                    onValueChange = { spamManager.updateThreshold(it.toInt()) },
                    valueRange = 3f..50f,
                    colors = SliderDefaults.colors(
                        thumbColor = BrandRed,
                        activeTrackColor = BrandRed,
                        inactiveTrackColor = Color.DarkGray
                    ),
                    modifier = Modifier.padding(vertical = 8.dp)
                )

                Text(
                    text = "If a number receives at least this many tags from trusted community members, it is flagged as spam on your device.",
                    fontSize = 11.sp,
                    color = TextSecondary,
                    lineHeight = 15.sp
                )
            }
        }

        // Reputation Meter Section
        Text(
            text = "Tagger Identity & Reputation",
            fontSize = 16.sp,
            fontWeight = FontWeight.Bold,
            color = Color.White,
            modifier = Modifier.padding(bottom = 8.dp)
        )
        
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 20.dp),
            colors = CardDefaults.cardColors(containerColor = DarkSurfaceCard),
            shape = RoundedCornerShape(16.dp)
        ) {
            Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(text = "Tagger Reputation Weight", fontSize = 14.sp, color = TextSecondary)
                    val reputationPct = String.format(Locale.US, "%.1f%%", spamManager.taggerReputation * 100)
                    Text(text = reputationPct, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = SafeGreen)
                }

                LinearProgressIndicator(
                    progress = { spamManager.taggerReputation.toFloat() },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(8.dp)
                        .clip(RoundedCornerShape(4.dp)),
                    color = SafeGreen,
                    trackColor = Color.DarkGray
                )

                Text(
                    text = "To resist sybil injection attacks, reports are weighted dynamically based on submission history. Tagging active spammers correctly increases reputation. Filing false reports decreases it.",
                    fontSize = 11.sp,
                    color = TextSecondary,
                    lineHeight = 15.sp
                )
            }
        }

        // Lookup Credits Section
        Text(
            text = "Carrier CNAM Lookups",
            fontSize = 16.sp,
            fontWeight = FontWeight.Bold,
            color = Color.White,
            modifier = Modifier.padding(bottom = 8.dp)
        )

        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = DarkSurfaceCard),
            shape = RoundedCornerShape(16.dp)
        ) {
            Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(text = "Free Monthly Credits", fontSize = 14.sp, color = Color.White)
                        Text(text = "Resets on 1st of month", fontSize = 11.sp, color = TextSecondary)
                    }
                    Text(text = "${spamManager.freeLookupsLeft} left", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = Color.White)
                }

                Divider(color = Color.White.copy(alpha = 0.1f))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(text = "Purchased Credits", fontSize = 14.sp, color = Color.White)
                        Text(text = "Never expires", fontSize = 11.sp, color = TextSecondary)
                    }
                    Text(text = "${spamManager.purchasedCredits} left", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = Color.White)
                }

                Button(
                    onClick = { spamManager.buyCreditPack() },
                    colors = ButtonDefaults.buttonColors(containerColor = NeutralBlue),
                    shape = RoundedCornerShape(10.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 8.dp)
                ) {
                    Text("Buy 10 Credits ($0.99)", color = Color.White, fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}
