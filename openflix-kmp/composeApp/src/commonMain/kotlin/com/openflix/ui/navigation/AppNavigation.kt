package com.openflix.ui.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.openflix.ui.screens.ChannelStore
import com.openflix.ui.screens.GuideScreen
import com.openflix.ui.screens.LivePlayerScreen
import com.openflix.ui.screens.LoginScreen
import com.openflix.ui.screens.MainScreen
import com.openflix.ui.screens.VideoPlayerScreen

@Composable
fun AppNavigation() {
    val navController = rememberNavController()

    NavHost(
        navController = navController,
        startDestination = "login"
    ) {
        composable("login") {
            LoginScreen(
                onLoginSuccess = {
                    navController.navigate("main") {
                        popUpTo("login") { inclusive = true }
                    }
                }
            )
        }
        composable("main") {
            MainScreen(navController = navController)
        }
        composable(
            route = "player/{mediaKey}",
            arguments = listOf(
                navArgument("mediaKey") { type = NavType.StringType }
            )
        ) { backStackEntry ->
            VideoPlayerScreen(
                mediaKey = backStackEntry.arguments?.getString("mediaKey") ?: "",
                onBack = { navController.popBackStack() }
            )
        }
        composable(
            route = "live/{channelId}",
            arguments = listOf(
                navArgument("channelId") { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val channelId = backStackEntry.arguments?.getString("channelId") ?: ""
            val channel = ChannelStore.lastChannel
            LivePlayerScreen(
                channelId = channelId,
                channelName = channel?.name ?: "",
                channelNumber = channel?.number?.toString() ?: "",
                channelLogo = channel?.logo ?: "",
                streamUrl = channel?.streamUrl ?: "",
                archiveEnabled = channel?.archiveEnabled ?: false,
                onBack = { navController.popBackStack() }
            )
        }
        composable("guide") {
            GuideScreen(
                onChannelClick = { channelId ->
                    navController.navigate("live/$channelId")
                },
                onBack = { navController.popBackStack() }
            )
        }
        composable(
            route = "recording/{recordingId}",
            arguments = listOf(
                navArgument("recordingId") { type = NavType.StringType }
            )
        ) { backStackEntry ->
            VideoPlayerScreen(
                mediaKey = backStackEntry.arguments?.getString("recordingId") ?: "",
                isRecording = true,
                onBack = { navController.popBackStack() }
            )
        }
    }
}
