package com.example.deepsci.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Search
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
import com.example.deepsci.models.SpamNumber
import com.example.deepsci.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DirectoryScreen(
    spamManager: SpamManager,
    modifier: Modifier = Modifier
) {
    var searchQuery by remember { mutableStateOf("") }
    var selectedCategory by remember { mutableStateOf("All") }
    var showReportDialog by remember { mutableStateOf(false) }

    val categories = listOf("All", "My Tags", "Scam", "Robocall", "Marketing", "Safe")

    // Filter numbers
    val filteredNumbers = spamManager.spamNumbers.filter { number ->
        // Search comparison (format-insensitive)
        val cleanSearch = searchQuery.filter { it.isDigit() }
        val matchesSearch = if (cleanSearch.isEmpty()) {
            number.phoneNumber.contains(searchQuery, ignoreCase = true) ||
                    (number.callerName?.contains(searchQuery, ignoreCase = true) ?: false)
        } else {
            number.phoneNumber.filter { it.isDigit() }.contains(cleanSearch)
        }

        // Category filter matching
        val matchesCategory = when (selectedCategory) {
            "All" -> true
            "My Tags" -> number.isUserFlagged
            "Scam" -> number.primaryCategory.contains("Scam", ignoreCase = true)
            "Robocall" -> number.primaryCategory.contains("Robocall", ignoreCase = true)
            "Marketing" -> number.primaryCategory.contains("Marketing", ignoreCase = true) || number.primaryCategory.contains("Telemarketing", ignoreCase = true)
            "Safe" -> number.primaryCategory.contains("Not Spam", ignoreCase = true)
            else -> true
        }

        matchesSearch && matchesCategory
    }

    Scaffold(
        modifier = modifier.fillMaxSize(),
        containerColor = DarkBg,
        floatingActionButton = {
            FloatingActionButton(
                onClick = { showReportDialog = true },
                containerColor = BrandRed,
                contentColor = Color.White,
                shape = RoundedCornerShape(16.dp)
            ) {
                Icon(Icons.Default.Add, contentDescription = "Report Spammer")
            }
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp)
        ) {
            Text(
                text = "Spam Directory",
                fontSize = 32.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White,
                modifier = Modifier.padding(bottom = 12.dp)
            )

            // Search Bar
            TextField(
                value = searchQuery,
                onValueChange = { searchQuery = it },
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp)),
                placeholder = { Text("Search number or company...", color = TextSecondary, fontSize = 14.sp) },
                leadingIcon = { Icon(Icons.Default.Search, contentDescription = "Search", tint = TextSecondary) },
                colors = TextFieldDefaults.colors(
                    focusedContainerColor = DarkSurface,
                    unfocusedContainerColor = DarkSurface,
                    focusedTextColor = Color.White,
                    unfocusedTextColor = Color.White,
                    focusedIndicatorColor = Color.Transparent,
                    unfocusedIndicatorColor = Color.Transparent
                ),
                singleLine = true
            )

            // Category Chips (Horizontal Scroll to prevent vertical wrapping)
            LazyRow(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(categories) { cat ->
                    val isSelected = selectedCategory == cat
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(16.dp))
                            .background(if (isSelected) BrandRed else DarkSurface)
                            .clickable { selectedCategory = cat }
                            .padding(horizontal = 14.dp, vertical = 8.dp)
                    ) {
                        Text(
                            text = cat,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = if (isSelected) Color.White else TextSecondary
                        )
                    }
                }
            }

            // Results List
            if (filteredNumbers.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(1f),
                    contentAlignment = Alignment.Center
                ) {
                    Text("No records found.", color = TextSecondary, fontSize = 14.sp)
                }
            } else {
                LazyColumn(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    items(filteredNumbers) { item ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(12.dp))
                                .background(DarkSurfaceCard)
                                .padding(16.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = SpamManager.formatPhoneNumber(item.phoneNumber),
                                    fontSize = 16.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color.White
                                )
                                Text(
                                    text = item.callerName ?: "Unknown Spammer",
                                    fontSize = 12.sp,
                                    color = TextSecondary,
                                    modifier = Modifier.padding(top = 2.dp)
                                )
                                Text(
                                    text = item.carrier ?: "Unknown Carrier",
                                    fontSize = 10.sp,
                                    color = TextSecondary
                                )
                            }
                            Column(horizontalAlignment = Alignment.End) {
                                val label = item.threatLabel(spamManager.escalationThreshold)
                                val tierColor = when (item.threatTier(spamManager.escalationThreshold)) {
                                    3 -> ScamRed
                                    2 -> RobocallPurple
                                    1 -> MarketingOrange
                                    else -> SafeGreen
                                }
                                Text(
                                    text = label,
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = tierColor
                                )
                                Text(
                                    text = item.primaryCategory,
                                    fontSize = 10.sp,
                                    color = TextSecondary,
                                    modifier = Modifier.padding(top = 2.dp)
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    // Manual Report Dialog (Similar to Sheet)
    if (showReportDialog) {
        var reportPhone by remember { mutableStateOf("") }
        var reportCategory by remember { mutableStateOf("Scam/Fraud") }

        val reportCategories = listOf(
            Triple("Scam / Fraud", "Scam/Fraud", ScamRed),
            Triple("Robocall", "Robocall", RobocallPurple),
            Triple("Telemarketing", "Spam/Telemarketing", MarketingOrange),
            Triple("Not Spam", "Not Spam", SafeGreen)
        )

        AlertDialog(
            onDismissRequest = { showReportDialog = false },
            confirmButton = {
                Button(
                    onClick = {
                        val cleaned = reportPhone.filter { it.isDigit() || it == '+' }
                        if (cleaned.isNotEmpty()) {
                            spamManager.tagNumber(cleaned, reportCategory)
                            showReportDialog = false
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = BrandRed),
                    enabled = reportPhone.any { it.isDigit() }
                ) {
                    Text("Submit Report", color = Color.White, fontWeight = FontWeight.Bold)
                }
            },
            dismissButton = {
                TextButton(onClick = { showReportDialog = false }) {
                    Text("Cancel", color = ScamRed)
                }
            },
            title = { Text("Report Spammer", color = Color.White, fontWeight = FontWeight.Bold) },
            text = {
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    Text(
                        "Enter the phone number that called you to tag and add it to the Deep SCI spam database.",
                        fontSize = 12.sp,
                        color = TextSecondary
                    )

                    TextField(
                        value = reportPhone,
                        onValueChange = { reportPhone = it },
                        placeholder = { Text("+1 (555) 000-0000", color = TextSecondary) },
                        colors = TextFieldDefaults.colors(
                            focusedContainerColor = DarkBg,
                            unfocusedContainerColor = DarkBg,
                            focusedTextColor = Color.White,
                            unfocusedTextColor = Color.White
                        ),
                        singleLine = true
                    )

                    Text("Select Spam Category", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = TextSecondary)

                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        reportCategories.forEach { (name, key, color) ->
                            val isSelected = reportCategory == key
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(if (isSelected) color.copy(alpha = 0.15f) else DarkBg)
                                    .clickable { reportCategory = key }
                                    .padding(12.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                RadioButton(
                                    selected = isSelected,
                                    onClick = { reportCategory = key },
                                    colors = RadioButtonDefaults.colors(selectedColor = color, unselectedColor = TextSecondary)
                                )
                                Text(
                                    text = name,
                                    fontSize = 14.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color.White,
                                    modifier = Modifier.padding(start = 8.dp)
                                )
                            }
                        }
                    }
                }
            },
            containerColor = DarkSurfaceCard,
            shape = RoundedCornerShape(16.dp)
        )
    }
}
