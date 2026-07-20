package com.example.deepsci.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.deepsci.theme.*

@Composable
fun HelpScreen(
    modifier: Modifier = Modifier
) {
    val scrollState = rememberScrollState()
    val uriHandler = LocalUriHandler.current

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(DarkBg)
            .padding(16.dp)
            .verticalScroll(scrollState)
    ) {
        Text(
            text = "Help & Support",
            fontSize = 32.sp,
            fontWeight = FontWeight.Bold,
            color = Color.White,
            modifier = Modifier.padding(bottom = 20.dp)
        )

        // Banner Header
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 16.dp),
            colors = CardDefaults.cardColors(containerColor = DarkSurfaceCard),
            shape = RoundedCornerShape(16.dp)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Box(
                    modifier = Modifier
                        .size(60.dp)
                        .clip(CircleShape)
                        .background(BrandRed.copy(alpha = 0.1f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Info,
                        contentDescription = "Help",
                        tint = BrandRed,
                        modifier = Modifier.size(36.dp)
                    )
                }

                Text(
                    text = "How Can We Help?",
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White,
                    modifier = Modifier.padding(top = 12.dp)
                )

                Text(
                    text = "Deep SCI Android Support Guide & FAQs",
                    fontSize = 13.sp,
                    color = TextSecondary,
                    modifier = Modifier.padding(top = 4.dp)
                )
            }
        }

        // Quick Start Guide Section
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 16.dp),
            colors = CardDefaults.cardColors(containerColor = DarkSurfaceCard),
            shape = RoundedCornerShape(16.dp)
        ) {
            Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                Text(
                    text = "Quick Start Guide",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )

                GuideRow(step = "1", title = "Enable Shielding", desc = "Go to Dashboard and toggle 'Active Shielding' ON. Deep SCI will screen incoming calls natively in the background.")
                GuideRow(step = "2", title = "Sync Spam lists", desc = "Click 'Sync' icon in Directory or Dashboard to fetch the latest crowdsourced numbers list.")
                GuideRow(step = "3", title = "Call History Integration", desc = "Go to Call History tab and grant access to instantly report incoming numbers as spam.")
            }
        }

        // FAQ Section
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 16.dp),
            colors = CardDefaults.cardColors(containerColor = DarkSurfaceCard),
            shape = RoundedCornerShape(16.dp)
        ) {
            Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                Text(
                    text = "Frequently Asked Questions",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )

                FaqRow(q = "How does call screening work?", a = "Android calls our CallScreeningService when a call rings. The service matches the number against the database and rejects spam calls immediately.")
                FaqRow(q = "Is my privacy protected?", a = "Yes. Deep SCI performs lookup scanning entirely locally. Your personal calls lists are never sent to external servers.")
                FaqRow(q = "How do I report a false positive?", a = "Select the disputed number from the Directory list, and click on 'Appeal/Unblock' to clear it.")
            }
        }

        // Assistance/Contact Section
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 20.dp),
            colors = CardDefaults.cardColors(containerColor = DarkSurfaceCard),
            shape = RoundedCornerShape(16.dp)
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Text(
                    text = "Need Further Assistance?",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )

                Text(
                    text = "If you have any questions, feedback, or need support with the app, we are here to help.",
                    fontSize = 12.sp,
                    color = TextSecondary,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(horizontal = 8.dp)
                )

                // Google Form Button
                Button(
                    onClick = { uriHandler.openUri("https://docs.google.com/forms/d/13CRQ9jmb16aVFZFT4Td5FRRR6nxrHa7VjW0rJk5YhE0/viewform") },
                    colors = ButtonDefaults.buttonColors(containerColor = NeutralBlue),
                    shape = RoundedCornerShape(10.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Open Support Form", color = Color.White, fontWeight = FontWeight.Bold)
                }

                // Email Button
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(10.dp))
                        .background(Color.White.copy(alpha = 0.04f))
                        .border(1.dp, Color.White.copy(alpha = 0.1f), RoundedCornerShape(10.dp))
                        .clickable { uriHandler.openUri("mailto:sridhargs@gmail.com?subject=Deep%20SCI%20Feedback%20%26%20Support") }
                        .padding(vertical = 12.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text("Send Email Support", color = Color.White, fontWeight = FontWeight.SemiBold)
                }
            }
        }
    }
}

@Composable
fun GuideRow(step: String, title: String, desc: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.Top
    ) {
        Box(
            modifier = Modifier
                .size(24.dp)
                .clip(CircleShape)
                .background(BrandRed),
            contentAlignment = Alignment.Center
        ) {
            Text(text = step, fontSize = 12.sp, fontWeight = FontWeight.Bold, color = Color.White)
        }

        Column(
            modifier = Modifier
                .padding(start = 12.dp)
                .weight(1f)
        ) {
            Text(text = title, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = Color.White)
            Text(text = desc, fontSize = 12.sp, color = TextSecondary, modifier = Modifier.padding(top = 2.dp))
        }
    }
}

@Composable
fun FaqRow(q: String, a: String) {
    Column(modifier = Modifier.fillMaxWidth()) {
        Text(text = q, fontSize = 14.sp, fontWeight = FontWeight.Bold, color = BrandRed)
        Text(text = a, fontSize = 12.sp, color = TextSecondary, modifier = Modifier.padding(top = 2.dp))
    }
}
