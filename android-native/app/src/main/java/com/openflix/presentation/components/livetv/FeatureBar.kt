package com.openflix.presentation.components.livetv

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.openflix.presentation.theme.OpenFlixColors

enum class FeatureAction(
    val label: String,
    val icon: ImageVector
) {
    GUIDE("Guide", Icons.Default.GridView),
    SURFING("Surfing", Icons.Default.SwapHoriz),
    CATCH_UP("Catch Up", Icons.Default.History),
    ON_LATER("On Later", Icons.Default.Schedule),
    TEAM_PASS("Team Pass", Icons.Default.SportsFootball),
    GROUPS("Groups", Icons.Default.Layers),
    MULTI_VIEW("Multi-View", Icons.Default.GridOn)
}

@Composable
fun FeatureBar(
    onAction: (FeatureAction) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .horizontalScroll(rememberScrollState())
            .padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        FeatureAction.entries.forEach { action ->
            FeatureChip(
                action = action,
                onClick = { onAction(action) }
            )
        }
    }
}

@Composable
private fun FeatureChip(
    action: FeatureAction,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(20.dp))
            .background(OpenFlixColors.Primary.copy(alpha = 0.15f))
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Icon(
            imageVector = action.icon,
            contentDescription = action.label,
            tint = OpenFlixColors.Primary,
            modifier = Modifier.size(18.dp)
        )
        Text(
            text = action.label,
            color = OpenFlixColors.Primary,
            fontSize = 13.sp,
            fontWeight = FontWeight.SemiBold
        )
    }
}
