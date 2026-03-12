package com.openflix.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.openflix.ui.theme.OpenFlixColors

private data class BrowseCategory(
    val name: String,
    val icon: ImageVector,
    val gradientStart: Color,
    val gradientEnd: Color
)

private val categories = listOf(
    BrowseCategory("Movies", Icons.Default.PlayArrow, Color(0xFF7C3AED), Color(0xFF4C1D95)),
    BrowseCategory("TV Shows", Icons.Default.Star, Color(0xFF8B5CF6), Color(0xFF5B21B6)),
    BrowseCategory("Sports Zone", Icons.Default.Favorite, Color(0xFF059669), Color(0xFF064E3B)),
    BrowseCategory("News", Icons.Default.Info, Color(0xFF2563EB), Color(0xFF1E3A8A)),
    BrowseCategory("Kids & Family", Icons.Default.Face, Color(0xFFF59E0B), Color(0xFF92400E)),
    BrowseCategory("Networks", Icons.Default.Home, Color(0xFF9333EA), Color(0xFF4A044E))
)

@Composable
fun BrowseScreen(
    onNavigateToSearch: () -> Unit = {},
    onCategoryClick: (String) -> Unit = {}
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(OpenFlixColors.Background)
            .padding(top = 8.dp)
    ) {
        // Search bar at top — taps navigate to Search tab
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(OpenFlixColors.SurfaceElevated)
                .clickable { onNavigateToSearch() }
                .padding(horizontal = 16.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.Search,
                contentDescription = null,
                tint = OpenFlixColors.TextTertiary,
                modifier = Modifier.size(20.dp)
            )
            Spacer(modifier = Modifier.width(12.dp))
            Text(
                text = "Search movies, shows, and more",
                color = OpenFlixColors.TextTertiary,
                fontSize = 15.sp
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        // 2-column category grid
        LazyVerticalGrid(
            columns = GridCells.Fixed(2),
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            items(categories) { category ->
                BrowseCategoryTile(
                    category = category,
                    onClick = { onCategoryClick(category.name) }
                )
            }
        }
    }
}

@Composable
private fun BrowseCategoryTile(
    category: BrowseCategory,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .aspectRatio(1.6f)
            .clip(RoundedCornerShape(16.dp))
            .background(
                Brush.verticalGradient(
                    colors = listOf(category.gradientStart, category.gradientEnd)
                )
            )
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Icon(
                imageVector = category.icon,
                contentDescription = null,
                tint = Color.White.copy(alpha = 0.9f),
                modifier = Modifier.size(32.dp)
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = category.name,
                color = Color.White,
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center
            )
        }
    }
}
