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

enum class LiveTVCategory(
    val label: String,
    val icon: ImageVector?,
    val color: Color
) {
    ALL("All", null, OpenFlixColors.Primary),
    FAVORITES("Favorites", Icons.Default.Star, Color(0xFFFFB800)),
    SPORTS("Sports", Icons.Default.SportsSoccer, OpenFlixColors.SportsColor),
    NEWS("News", Icons.Default.Newspaper, OpenFlixColors.NewsColor),
    MOVIES("Movies", Icons.Default.Movie, OpenFlixColors.MoviesColor),
    KIDS("Kids", Icons.Default.ChildCare, OpenFlixColors.KidsColor)
}

@Composable
fun CategoryFilterBar(
    selectedCategory: LiveTVCategory,
    onCategorySelected: (LiveTVCategory) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .horizontalScroll(rememberScrollState())
            .padding(horizontal = 16.dp, vertical = 6.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        LiveTVCategory.entries.forEach { category ->
            CategoryChip(
                category = category,
                isSelected = selectedCategory == category,
                onClick = { onCategorySelected(category) }
            )
        }
    }
}

@Composable
private fun CategoryChip(
    category: LiveTVCategory,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    val bgColor = if (isSelected) category.color.copy(alpha = 0.2f)
        else OpenFlixColors.SurfaceVariant
    val textColor = if (isSelected) category.color else OpenFlixColors.TextSecondary

    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(16.dp))
            .background(bgColor)
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        category.icon?.let { icon ->
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = textColor,
                modifier = Modifier.size(16.dp)
            )
        }
        Text(
            text = category.label,
            color = textColor,
            fontSize = 13.sp,
            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium
        )
    }
}
