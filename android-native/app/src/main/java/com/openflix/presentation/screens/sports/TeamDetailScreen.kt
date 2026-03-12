package com.openflix.presentation.screens.sports

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.tv.material3.Text

@Composable
fun TeamDetailScreen(
    sport: String,
    league: String,
    teamId: String,
    onBack: () -> Unit = {}
) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Text("Team Detail: $teamId")
    }
}
