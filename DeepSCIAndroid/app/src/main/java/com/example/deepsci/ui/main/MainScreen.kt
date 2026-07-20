package com.example.deepsci.ui.main

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation3.runtime.NavKey
import com.example.deepsci.SpamManager
import com.example.deepsci.theme.*
import com.example.deepsci.ui.*

sealed class TabScreen(val route: String, val icon: ImageVector, val label: String) {
    object Dashboard : TabScreen("dashboard", Icons.Default.Home, "Dashboard")
    object Directory : TabScreen("directory", Icons.Default.List, "Directory")
    object CallLog : TabScreen("calllog", Icons.Default.Call, "History")
    object Settings : TabScreen("settings", Icons.Default.Settings, "Settings")
    object Help : TabScreen("help", Icons.Default.Info, "Help")
}

@Composable
fun MainScreen(
    onItemClick: (NavKey) -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val spamManager = remember { SpamManager.initialize(context.applicationContext) }
    var selectedTab by remember { mutableStateOf<TabScreen>(TabScreen.Dashboard) }

    val tabs = listOf(
        TabScreen.Dashboard,
        TabScreen.Directory,
        TabScreen.CallLog,
        TabScreen.Settings,
        TabScreen.Help
    )

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        containerColor = DarkBg,
        bottomBar = {
            NavigationBar(
                containerColor = DarkSurface,
                tonalElevation = 8.dp
            ) {
                tabs.forEach { tab ->
                    val isSelected = selectedTab.route == tab.route
                    NavigationBarItem(
                        selected = isSelected,
                        onClick = { selectedTab = tab },
                        icon = { Icon(tab.icon, contentDescription = tab.label) },
                        label = { Text(tab.label, fontSize = 11.sp) },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = Color.White,
                            selectedTextColor = Color.White,
                            indicatorColor = BrandRed,
                            unselectedIconColor = TextSecondary,
                            unselectedTextColor = TextSecondary
                        )
                    )
                }
            }
        }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            when (selectedTab) {
                TabScreen.Dashboard -> DashboardScreen(spamManager)
                TabScreen.Directory -> DirectoryScreen(spamManager)
                TabScreen.CallLog -> CallLogScreen(spamManager)
                TabScreen.Settings -> SettingsScreen(spamManager)
                TabScreen.Help -> HelpScreen()
            }
        }
    }
}
