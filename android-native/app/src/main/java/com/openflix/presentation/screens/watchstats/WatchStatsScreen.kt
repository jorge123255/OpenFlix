package com.openflix.presentation.screens.watchstats

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.material3.*
import com.openflix.data.local.ContentType
import com.openflix.data.local.DailyStat
import com.openflix.data.local.MostWatchedItem
import com.openflix.data.local.WatchHistoryItem
import java.text.SimpleDateFormat
import java.util.*

/**
 * Watch Stats color theme - Green/Teal for analytics
 */
private object StatsTheme {
    val Background = Color(0xFF0A0A0A)
    val Surface = Color(0xFF1A1A1A)
    val SurfaceVariant = Color(0xFF252525)
    val Accent = Color(0xFF10B981)  // Emerald green
    val AccentSecondary = Color(0xFF06B6D4)  // Cyan
    val TextPrimary = Color.White
    val TextSecondary = Color(0xFFB0B0B0)
    val TextMuted = Color(0xFF666666)
    val ChartBar = Color(0xFF10B981)
    val ChartBarSecondary = Color(0xFF064E3B)
}

@Composable
fun WatchStatsScreen(
    onBack: () -> Unit,
    viewModel: WatchStatsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(StatsTheme.Background)
            .padding(24.dp)
    ) {
        // Header
        StatsHeader(onBack = onBack)

        Spacer(modifier = Modifier.height(24.dp))

        if (uiState.isLoading) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "● ● ●",
                    color = StatsTheme.Accent,
                    fontSize = 24.sp
                )
            }
        } else {
            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(24.dp)
            ) {
                // Overview Cards
                item {
                    OverviewSection(uiState)
                }

                // Daily Activity Chart
                item {
                    DailyActivityChart(
                        dailyStats = uiState.dailyStats,
                        maxMinutes = uiState.maxDailyMinutes,
                        formatTime = { uiState.formatTime(it) }
                    )
                }

                // Content Type Breakdown
                item {
                    ContentTypeSection(
                        stats = uiState.contentTypeStats,
                        formatTime = { uiState.formatTime(it) }
                    )
                }

                // Most Watched
                if (uiState.mostWatched.isNotEmpty()) {
                    item {
                        MostWatchedSection(
                            items = uiState.mostWatched,
                            formatTime = { uiState.formatTime(it) }
                        )
                    }
                }

                // Recent History
                if (uiState.watchHistory.isNotEmpty()) {
                    item {
                        RecentHistorySection(
                            items = uiState.watchHistory,
                            formatTime = { uiState.formatTime(it) }
                        )
                    }
                }

                // Empty state
                if (uiState.totalWatchTime == 0L) {
                    item {
                        EmptyStatsState()
                    }
                }

                item {
                    Spacer(modifier = Modifier.height(48.dp))
                }
            }
        }
    }
}

@Composable
private fun StatsHeader(onBack: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        IconButton(onClick = onBack) {
            Icon(
                Icons.AutoMirrored.Filled.ArrowBack,
                contentDescription = "Back",
                tint = StatsTheme.TextPrimary
            )
        }

        Spacer(modifier = Modifier.width(16.dp))

        Box(
            modifier = Modifier
                .clip(RoundedCornerShape(8.dp))
                .background(StatsTheme.Accent)
                .padding(horizontal = 12.dp, vertical = 6.dp)
        ) {
            Text(
                text = "WATCH STATS",
                color = Color.White,
                fontWeight = FontWeight.Bold,
                fontSize = 14.sp
            )
        }

        Spacer(modifier = Modifier.width(12.dp))

        Text(
            text = "Your viewing activity",
            color = StatsTheme.TextSecondary,
            fontSize = 16.sp
        )
    }
}

@Composable
private fun OverviewSection(uiState: WatchStatsUiState) {
    Column {
        Text(
            text = "Overview",
            color = StatsTheme.TextPrimary,
            fontSize = 20.sp,
            fontWeight = FontWeight.Bold
        )

        Spacer(modifier = Modifier.height(16.dp))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            StatCard(
                modifier = Modifier.weight(1f),
                icon = Icons.Default.Timer,
                label = "Total Watch Time",
                value = uiState.formatTime(uiState.totalWatchTime),
                accentColor = StatsTheme.Accent
            )

            StatCard(
                modifier = Modifier.weight(1f),
                icon = Icons.Default.Today,
                label = "Today",
                value = uiState.formatTime(uiState.todayWatchTime),
                accentColor = StatsTheme.AccentSecondary
            )

            StatCard(
                modifier = Modifier.weight(1f),
                icon = Icons.Default.DateRange,
                label = "This Week",
                value = uiState.formatTime(uiState.weekWatchTime),
                accentColor = Color(0xFF8B5CF6)
            )

            StatCard(
                modifier = Modifier.weight(1f),
                icon = Icons.Default.CalendarMonth,
                label = "This Month",
                value = uiState.formatTime(uiState.monthWatchTime),
                accentColor = Color(0xFFF59E0B)
            )
        }

        Spacer(modifier = Modifier.height(16.dp))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            StatCard(
                modifier = Modifier.weight(1f),
                icon = Icons.Default.TrendingUp,
                label = "Daily Average",
                value = uiState.formatTime(uiState.averageDailyTime),
                accentColor = Color(0xFFEC4899)
            )

            StatCard(
                modifier = Modifier.weight(1f),
                icon = Icons.Default.VideoLibrary,
                label = "Content Watched",
                value = "${uiState.totalContentWatched}",
                accentColor = Color(0xFF6366F1)
            )

            uiState.favoriteContentType?.let { favorite ->
                StatCard(
                    modifier = Modifier.weight(1f),
                    icon = getContentTypeIcon(favorite),
                    label = "Favorite Type",
                    value = favorite.name.replace("_", " "),
                    accentColor = Color(0xFF14B8A6)
                )
            } ?: Spacer(modifier = Modifier.weight(1f))

            Spacer(modifier = Modifier.weight(1f))
        }
    }
}

@Composable
private fun StatCard(
    modifier: Modifier = Modifier,
    icon: ImageVector,
    label: String,
    value: String,
    accentColor: Color
) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(12.dp))
            .background(StatsTheme.Surface)
            .padding(16.dp)
    ) {
        Column {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    icon,
                    contentDescription = null,
                    tint = accentColor,
                    modifier = Modifier.size(20.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = label,
                    color = StatsTheme.TextSecondary,
                    fontSize = 12.sp
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = value,
                color = StatsTheme.TextPrimary,
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

@Composable
private fun DailyActivityChart(
    dailyStats: List<DailyStat>,
    maxMinutes: Int,
    formatTime: (Int) -> String
) {
    Column {
        Text(
            text = "Daily Activity",
            color = StatsTheme.TextPrimary,
            fontSize = 20.sp,
            fontWeight = FontWeight.Bold
        )

        Spacer(modifier = Modifier.height(16.dp))

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(12.dp))
                .background(StatsTheme.Surface)
                .padding(16.dp)
        ) {
            Column {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(120.dp),
                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                    verticalAlignment = Alignment.Bottom
                ) {
                    dailyStats.forEach { stat ->
                        val height = if (maxMinutes > 0) {
                            (stat.minutes.toFloat() / maxMinutes * 100).dp
                        } else 4.dp

                        Column(
                            modifier = Modifier.weight(1f),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(height.coerceAtLeast(4.dp))
                                    .clip(RoundedCornerShape(topStart = 4.dp, topEnd = 4.dp))
                                    .background(
                                        Brush.verticalGradient(
                                            colors = listOf(
                                                StatsTheme.ChartBar,
                                                StatsTheme.ChartBarSecondary
                                            )
                                        )
                                    )
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(8.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    dailyStats.forEach { stat ->
                        Text(
                            text = stat.dayOfWeek,
                            modifier = Modifier.weight(1f),
                            color = StatsTheme.TextMuted,
                            fontSize = 10.sp,
                            maxLines = 1
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun ContentTypeSection(
    stats: Map<ContentType, Int>,
    formatTime: (Int) -> String
) {
    if (stats.isEmpty()) return

    Column {
        Text(
            text = "By Content Type",
            color = StatsTheme.TextPrimary,
            fontSize = 20.sp,
            fontWeight = FontWeight.Bold
        )

        Spacer(modifier = Modifier.height(16.dp))

        LazyRow(
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            items(stats.entries.sortedByDescending { it.value }) { (type, minutes) ->
                ContentTypeCard(
                    type = type,
                    minutes = minutes,
                    formatTime = formatTime
                )
            }
        }
    }
}

@Composable
private fun ContentTypeCard(
    type: ContentType,
    minutes: Int,
    formatTime: (Int) -> String
) {
    val (icon, color) = when (type) {
        ContentType.MOVIE -> Icons.Default.Movie to Color(0xFFEF4444)
        ContentType.TV_SHOW -> Icons.Default.Tv to Color(0xFF3B82F6)
        ContentType.LIVE_TV -> Icons.Default.LiveTv to Color(0xFF10B981)
        ContentType.DVR_RECORDING -> Icons.Default.FiberManualRecord to Color(0xFFF59E0B)
        ContentType.SPORTS -> Icons.Default.SportsFootball to Color(0xFF8B5CF6)
    }

    Box(
        modifier = Modifier
            .width(140.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(StatsTheme.Surface)
            .padding(16.dp)
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.fillMaxWidth()
        ) {
            Icon(
                icon,
                contentDescription = null,
                tint = color,
                modifier = Modifier.size(32.dp)
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = type.name.replace("_", " "),
                color = StatsTheme.TextSecondary,
                fontSize = 12.sp
            )

            Spacer(modifier = Modifier.height(4.dp))

            Text(
                text = formatTime(minutes),
                color = StatsTheme.TextPrimary,
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

@Composable
private fun MostWatchedSection(
    items: List<MostWatchedItem>,
    formatTime: (Int) -> String
) {
    Column {
        Text(
            text = "Most Watched",
            color = StatsTheme.TextPrimary,
            fontSize = 20.sp,
            fontWeight = FontWeight.Bold
        )

        Spacer(modifier = Modifier.height(16.dp))

        LazyRow(
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            items(items) { item ->
                MostWatchedCard(item = item, formatTime = formatTime)
            }
        }
    }
}

@Composable
private fun MostWatchedCard(
    item: MostWatchedItem,
    formatTime: (Int) -> String
) {
    Box(
        modifier = Modifier
            .width(200.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(StatsTheme.Surface)
            .padding(16.dp)
    ) {
        Column {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    getContentTypeIcon(item.contentType),
                    contentDescription = null,
                    tint = StatsTheme.Accent,
                    modifier = Modifier.size(16.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = item.contentType.name.replace("_", " "),
                    color = StatsTheme.TextMuted,
                    fontSize = 10.sp
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = item.title,
                color = StatsTheme.TextPrimary,
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium,
                maxLines = 2
            )

            Spacer(modifier = Modifier.height(8.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = formatTime(item.totalMinutes),
                    color = StatsTheme.Accent,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "${item.watchCount}x",
                    color = StatsTheme.TextSecondary,
                    fontSize = 12.sp
                )
            }
        }
    }
}

@Composable
private fun RecentHistorySection(
    items: List<WatchHistoryItem>,
    formatTime: (Int) -> String
) {
    Column {
        Text(
            text = "Recent History",
            color = StatsTheme.TextPrimary,
            fontSize = 20.sp,
            fontWeight = FontWeight.Bold
        )

        Spacer(modifier = Modifier.height(16.dp))

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(12.dp))
                .background(StatsTheme.Surface)
                .padding(8.dp)
        ) {
            Column {
                items.take(10).forEach { item ->
                    HistoryRow(item = item, formatTime = formatTime)
                }
            }
        }
    }
}

@Composable
private fun HistoryRow(
    item: WatchHistoryItem,
    formatTime: (Int) -> String
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            getContentTypeIcon(item.contentType),
            contentDescription = null,
            tint = StatsTheme.TextMuted,
            modifier = Modifier.size(20.dp)
        )

        Spacer(modifier = Modifier.width(12.dp))

        Column(
            modifier = Modifier.weight(1f)
        ) {
            Text(
                text = item.title,
                color = StatsTheme.TextPrimary,
                fontSize = 14.sp,
                maxLines = 1
            )
            Text(
                text = formatDate(item.watchedAt),
                color = StatsTheme.TextMuted,
                fontSize = 12.sp
            )
        }

        Text(
            text = formatTime(item.durationMinutes),
            color = StatsTheme.TextSecondary,
            fontSize = 14.sp
        )
    }
}

@Composable
private fun EmptyStatsState() {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(StatsTheme.Surface)
            .padding(48.dp)
    ) {
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                Icons.Default.Analytics,
                contentDescription = null,
                tint = StatsTheme.TextMuted,
                modifier = Modifier.size(64.dp)
            )

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = "No Watch Stats Yet",
                color = StatsTheme.TextPrimary,
                fontSize = 20.sp,
                fontWeight = FontWeight.Medium
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "Start watching content to see your viewing statistics here.",
                color = StatsTheme.TextSecondary,
                fontSize = 14.sp
            )
        }
    }
}

private fun getContentTypeIcon(type: ContentType): ImageVector {
    return when (type) {
        ContentType.MOVIE -> Icons.Default.Movie
        ContentType.TV_SHOW -> Icons.Default.Tv
        ContentType.LIVE_TV -> Icons.Default.LiveTv
        ContentType.DVR_RECORDING -> Icons.Default.FiberManualRecord
        ContentType.SPORTS -> Icons.Default.SportsFootball
    }
}

private fun formatDate(timestamp: Long): String {
    val sdf = SimpleDateFormat("MMM d, h:mm a", Locale.getDefault())
    return sdf.format(Date(timestamp))
}
