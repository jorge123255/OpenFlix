package com.openflix.presentation.screens.epg

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.openflix.domain.model.Channel
import com.openflix.domain.model.ChannelWithPrograms
import com.openflix.domain.model.Program
import com.openflix.domain.model.ProgramBadge
import com.openflix.presentation.theme.OpenFlixColors
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

// Modern EPG Grid dimensions
private val CHANNEL_WIDTH = 240.dp
private val ROW_HEIGHT = 96.dp
private val TIME_HEADER_HEIGHT = 56.dp
private val TIME_SLOT_WIDTH = 280.dp

/**
 * Modern EPG Guide Screen - Channels DVR inspired design
 * Glass effects, smooth animations, category colors
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EPGGuideScreenModern(
    onBack: () -> Unit,
    onChannelSelected: (String) -> Unit,
    onArchivePlayback: (channelId: String, programStartTime: Long) -> Unit = { _, _ -> },
    viewModel: EPGGuideViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val focusRequester = remember { FocusRequester() }
    val coroutineScope = rememberCoroutineScope()
    
    // Scroll states
    val channelListState = rememberLazyListState()
    val horizontalScrollState = rememberScrollState()
    
    // Category filter
    var selectedCategory by remember { mutableStateOf<String?>(null) }
    var showQuickNav by remember { mutableStateOf(true) }
    
    LaunchedEffect(Unit) {
        focusRequester.requestFocus()
    }
    
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(OpenFlixColors.Background)
    ) {
        Column(modifier = Modifier.fillMaxSize()) {
            // Quick Navigation Bar
            AnimatedVisibility(
                visible = showQuickNav,
                enter = slideInVertically() + fadeIn(),
                exit = slideOutVertically() + fadeOut()
            ) {
                ModernQuickNavBar(
                    onJumpToNow = { viewModel.scrollToNow() },
                    onJumpToPrimetime = { /* Jump to 8pm */ },
                    onFilter = { /* Show filter */ },
                    onSearch = { /* Show search */ }
                )
            }
            
            // Category Tabs
            ModernCategoryTabs(
                categories = uiState.categories,
                selectedCategory = selectedCategory,
                onCategorySelected = { selectedCategory = it }
            )
            
            // Main EPG Grid
            Box(modifier = Modifier.fillMaxSize()) {
                Column {
                    // Time Header
                    ModernTimeHeader(
                        timeSlots = uiState.timeSlots,
                        scrollState = horizontalScrollState
                    )
                    
                    // Channel rows
                    LazyColumn(
                        state = channelListState,
                        modifier = Modifier.fillMaxSize()
                    ) {
                        itemsIndexed(
                            items = filterChannels(uiState.channels, selectedCategory),
                            key = { _, item -> item.channel.id }
                        ) { index, channelWithPrograms ->
                            ModernEPGRow(
                                channelWithPrograms = channelWithPrograms,
                                isPlaying = uiState.currentChannelId == channelWithPrograms.channel.id,
                                horizontalScrollState = horizontalScrollState,
                                startTimeSeconds = uiState.startTimeSeconds,
                                onChannelSelect = { onChannelSelected(channelWithPrograms.channel.id) },
                                onProgramSelect = { program ->
                                    viewModel.selectProgram(program, channelWithPrograms.channel)
                                }
                            )
                        }
                    }
                }
                
                // Now line overlay
                ModernNowLine(
                    startTimeSeconds = uiState.startTimeSeconds,
                    scrollState = horizontalScrollState
                )
                
                // Mini player preview (top-right corner)
                if (uiState.currentChannel != null) {
                    ModernNowPlayingCard(
                        channel = uiState.currentChannel!!,
                        program = uiState.currentProgram,
                        modifier = Modifier
                            .align(Alignment.TopEnd)
                            .padding(16.dp),
                        onClick = { uiState.currentChannel?.let { onChannelSelected(it.id) } }
                    )
                }
            }
        }
        
        // Program detail sheet
        if (uiState.selectedProgram != null && uiState.selectedChannel != null) {
            ModernProgramDetailSheet(
                program = uiState.selectedProgram!!,
                channel = uiState.selectedChannel!!,
                onDismiss = { viewModel.clearSelection() },
                onWatch = { onChannelSelected(uiState.selectedChannel!!.id) },
                onRecord = { /* Record */ }
            )
        }
    }
}

private fun filterChannels(
    channels: List<ChannelWithPrograms>,
    category: String?
): List<ChannelWithPrograms> {
    if (category == null) return channels
    return channels.filter { it.channel.group == category }
}

// MARK: - Quick Nav Bar

@Composable
private fun ModernQuickNavBar(
    onJumpToNow: () -> Unit,
    onJumpToPrimetime: () -> Unit,
    onFilter: () -> Unit,
    onSearch: () -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = OpenFlixColors.Surface.copy(alpha = 0.95f),
        tonalElevation = 4.dp
    ) {
        Row(
            modifier = Modifier
                .padding(horizontal = 24.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            QuickNavButton(
                icon = Icons.Default.AccessTime,
                label = "Now",
                onClick = onJumpToNow
            )
            QuickNavButton(
                icon = Icons.Default.NightsStay,
                label = "Tonight",
                onClick = onJumpToPrimetime
            )
            QuickNavButton(
                icon = Icons.Default.FilterList,
                label = "Filter",
                onClick = onFilter
            )
            QuickNavButton(
                icon = Icons.Default.Search,
                label = "Search",
                onClick = onSearch
            )
        }
    }
}

@Composable
private fun QuickNavButton(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    
    Surface(
        onClick = onClick,
        modifier = Modifier
            .onFocusChanged { isFocused = it.isFocused }
            .animateContentSize(),
        shape = RoundedCornerShape(20.dp),
        color = if (isFocused) OpenFlixColors.Primary.copy(alpha = 0.2f)
               else Color.White.copy(alpha = 0.1f),
        border = if (isFocused) BorderStroke(2.dp, OpenFlixColors.Primary) else null
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(18.dp),
                tint = if (isFocused) OpenFlixColors.Primary else Color.White
            )
            Text(
                text = label,
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium,
                color = if (isFocused) OpenFlixColors.Primary else Color.White
            )
        }
    }
}

// MARK: - Category Tabs

@Composable
private fun ModernCategoryTabs(
    categories: List<String>,
    selectedCategory: String?,
    onCategorySelected: (String?) -> Unit
) {
    LazyRow(
        modifier = Modifier
            .fillMaxWidth()
            .background(OpenFlixColors.Surface.copy(alpha = 0.7f))
            .padding(vertical = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        contentPadding = PaddingValues(horizontal = 24.dp)
    ) {
        item {
            CategoryChip(
                label = "All Channels",
                isSelected = selectedCategory == null,
                onClick = { onCategorySelected(null) }
            )
        }
        item {
            CategoryChip(
                label = "⭐ Favorites",
                isSelected = false,
                onClick = { /* Filter favorites */ }
            )
        }
        items(categories.size) { index ->
            CategoryChip(
                label = categories[index],
                isSelected = selectedCategory == categories[index],
                onClick = { onCategorySelected(categories[index]) }
            )
        }
    }
}

@Composable
private fun CategoryChip(
    label: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    
    Surface(
        onClick = onClick,
        modifier = Modifier
            .onFocusChanged { isFocused = it.isFocused }
            .graphicsLayer {
                scaleX = if (isFocused) 1.05f else 1f
                scaleY = if (isFocused) 1.05f else 1f
            },
        shape = RoundedCornerShape(20.dp),
        color = when {
            isSelected -> OpenFlixColors.Primary
            isFocused -> OpenFlixColors.Primary.copy(alpha = 0.3f)
            else -> Color.White.copy(alpha = 0.1f)
        }
    ) {
        Text(
            text = label,
            modifier = Modifier.padding(horizontal = 20.dp, vertical = 10.dp),
            fontSize = 14.sp,
            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
            color = if (isSelected) Color.Black else Color.White
        )
    }
}

// MARK: - Time Header

@Composable
private fun ModernTimeHeader(
    timeSlots: List<Long>,
    scrollState: ScrollState
) {
    val timeFormatter = remember { SimpleDateFormat("h:mm a", Locale.getDefault()) }
    val now = System.currentTimeMillis() / 1000
    
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(OpenFlixColors.Surface.copy(alpha = 0.95f))
    ) {
        // Corner cell
        Box(
            modifier = Modifier
                .width(CHANNEL_WIDTH)
                .height(TIME_HEADER_HEIGHT)
                .background(OpenFlixColors.SurfaceVariant),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Default.Tv,
                contentDescription = null,
                tint = OpenFlixColors.Primary
            )
        }
        
        // Time slots
        Row(
            modifier = Modifier
                .horizontalScroll(scrollState)
                .height(TIME_HEADER_HEIGHT)
        ) {
            timeSlots.forEach { timeSeconds ->
                val isCurrentSlot = now >= timeSeconds && now < timeSeconds + 1800
                
                Box(
                    modifier = Modifier
                        .width(TIME_SLOT_WIDTH)
                        .fillMaxHeight()
                        .background(
                            if (isCurrentSlot) OpenFlixColors.Primary.copy(alpha = 0.15f)
                            else Color.Transparent
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            text = timeFormatter.format(Date(timeSeconds * 1000)),
                            fontSize = 14.sp,
                            fontWeight = if (isCurrentSlot) FontWeight.Bold else FontWeight.Medium,
                            color = if (isCurrentSlot) OpenFlixColors.Primary 
                                   else OpenFlixColors.TextSecondary
                        )
                        if (isCurrentSlot) {
                            Box(
                                modifier = Modifier
                                    .padding(top = 4.dp)
                                    .width(40.dp)
                                    .height(3.dp)
                                    .clip(RoundedCornerShape(2.dp))
                                    .background(OpenFlixColors.Primary)
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - EPG Row

@Composable
private fun ModernEPGRow(
    channelWithPrograms: ChannelWithPrograms,
    isPlaying: Boolean,
    horizontalScrollState: ScrollState,
    startTimeSeconds: Long,
    onChannelSelect: () -> Unit,
    onProgramSelect: (Program) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(ROW_HEIGHT)
            .padding(vertical = 1.dp)
    ) {
        // Channel cell
        ModernChannelCell(
            channel = channelWithPrograms.channel,
            isPlaying = isPlaying,
            onClick = onChannelSelect
        )
        
        // Programs
        Row(
            modifier = Modifier
                .horizontalScroll(horizontalScrollState)
                .fillMaxHeight()
                .padding(vertical = 2.dp),
            horizontalArrangement = Arrangement.spacedBy(2.dp)
        ) {
            channelWithPrograms.programs.forEach { program ->
                val width = calculateProgramWidth(program, startTimeSeconds)
                ModernProgramCell(
                    program = program,
                    width = width,
                    onClick = { onProgramSelect(program) }
                )
            }
        }
    }
}

// MARK: - Channel Cell

@Composable
private fun ModernChannelCell(
    channel: Channel,
    isPlaying: Boolean,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    
    Surface(
        onClick = onClick,
        modifier = Modifier
            .width(CHANNEL_WIDTH)
            .fillMaxHeight()
            .onFocusChanged { isFocused = it.isFocused },
        color = when {
            isFocused -> OpenFlixColors.Primary.copy(alpha = 0.2f)
            isPlaying -> OpenFlixColors.Success.copy(alpha = 0.15f)
            else -> OpenFlixColors.Surface
        },
        border = if (isFocused) BorderStroke(2.dp, OpenFlixColors.Primary) else null
    ) {
        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(12.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Logo
            Box(
                modifier = Modifier
                    .size(56.dp)
                    .clip(RoundedCornerShape(8.dp))
                    .background(Color.White.copy(alpha = 0.1f)),
                contentAlignment = Alignment.Center
            ) {
                if (channel.logo != null) {
                    AsyncImage(
                        model = channel.logo,
                        contentDescription = null,
                        modifier = Modifier.size(48.dp),
                        contentScale = ContentScale.Fit
                    )
                } else {
                    Text(
                        text = channel.number?.toString() ?: "?",
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        color = OpenFlixColors.TextSecondary
                    )
                }
                
                // Playing indicator
                if (isPlaying) {
                    Box(
                        modifier = Modifier
                            .align(Alignment.TopEnd)
                            .offset(x = 4.dp, y = (-4).dp)
                            .size(10.dp)
                            .clip(CircleShape)
                            .background(OpenFlixColors.Success)
                    )
                }
            }
            
            Column(
                modifier = Modifier.weight(1f)
            ) {
                // Channel number
                channel.number?.let {
                    Text(
                        text = it.toString(),
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = OpenFlixColors.Primary
                    )
                }
                
                // Channel name
                Text(
                    text = channel.name,
                    fontSize = 14.sp,
                    fontWeight = if (isFocused) FontWeight.SemiBold else FontWeight.Normal,
                    color = Color.White,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                
                // Favorite indicator
                if (channel.isFavorite) {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(2.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.Star,
                            contentDescription = null,
                            modifier = Modifier.size(10.dp),
                            tint = Color.Yellow.copy(alpha = 0.8f)
                        )
                        Text(
                            text = "Favorite",
                            fontSize = 10.sp,
                            color = Color.Yellow.copy(alpha = 0.8f)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Program Cell

@Composable
private fun ModernProgramCell(
    program: Program,
    width: Dp,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    val isAiring = program.isCurrentlyAiring
    val categoryColor = getCategoryColor(program.category)
    
    val scale by animateFloatAsState(
        targetValue = if (isFocused) 1.03f else 1f,
        animationSpec = spring(dampingRatio = 0.7f)
    )
    
    Surface(
        onClick = onClick,
        modifier = Modifier
            .width(width)
            .fillMaxHeight()
            .onFocusChanged { isFocused = it.isFocused }
            .graphicsLayer {
                scaleX = scale
                scaleY = scale
            },
        shape = RoundedCornerShape(12.dp),
        color = when {
            isFocused -> categoryColor.copy(alpha = 0.3f)
            isAiring -> OpenFlixColors.SurfaceHighlight
            else -> OpenFlixColors.Card
        },
        border = if (isFocused) BorderStroke(3.dp, categoryColor) else null,
        shadowElevation = if (isFocused) 16.dp else 4.dp
    ) {
        Box(modifier = Modifier.fillMaxSize()) {
            // Category stripe
            Box(
                modifier = Modifier
                    .width(4.dp)
                    .fillMaxHeight()
                    .padding(vertical = 8.dp)
                    .clip(RoundedCornerShape(2.dp))
                    .background(
                        Brush.verticalGradient(
                            colors = listOf(categoryColor, categoryColor.copy(alpha = 0.5f))
                        )
                    )
            )
            
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(start = 12.dp, end = 12.dp, top = 10.dp, bottom = 10.dp)
            ) {
                // Badges
                Row(
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    if (program.isLive) {
                        LiveBadge()
                    }
                    program.badges.take(2).forEach { badge ->
                        ProgramBadgeChip(badge = badge)
                    }
                }
                
                Spacer(modifier = Modifier.height(6.dp))
                
                // Title
                Text(
                    text = program.title,
                    fontSize = if (isFocused) 16.sp else 14.sp,
                    fontWeight = if (isAiring) FontWeight.Bold else FontWeight.SemiBold,
                    color = Color.White,
                    maxLines = if (isFocused) 3 else 2,
                    overflow = TextOverflow.Ellipsis
                )
                
                // Subtitle on focus
                AnimatedVisibility(visible = isFocused && program.subtitle != null) {
                    Text(
                        text = program.subtitle ?: "",
                        fontSize = 12.sp,
                        color = Color.White.copy(alpha = 0.7f),
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
                
                Spacer(modifier = Modifier.weight(1f))
                
                // Time and rating
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = formatTime(program.startTime),
                        fontSize = 12.sp,
                        color = OpenFlixColors.TextMuted
                    )
                    
                    program.rating?.let {
                        Text(
                            text = it,
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Medium,
                            color = Color.White.copy(alpha = 0.6f),
                            modifier = Modifier
                                .background(
                                    Color.White.copy(alpha = 0.15f),
                                    RoundedCornerShape(4.dp)
                                )
                                .padding(horizontal = 6.dp, vertical = 2.dp)
                        )
                    }
                }
                
                // Progress bar for currently airing
                if (isAiring) {
                    Spacer(modifier = Modifier.height(6.dp))
                    LinearProgressIndicator(
                        progress = { program.progress.toFloat() },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(3.dp)
                            .clip(RoundedCornerShape(2.dp)),
                        color = categoryColor,
                        trackColor = Color.White.copy(alpha = 0.2f)
                    )
                }
            }
        }
    }
}

@Composable
private fun LiveBadge() {
    val infiniteTransition = rememberInfiniteTransition()
    val scale by infiniteTransition.animateFloat(
        initialValue = 0.8f,
        targetValue = 1.2f,
        animationSpec = infiniteRepeatable(
            animation = tween(800),
            repeatMode = RepeatMode.Reverse
        )
    )
    
    Row(
        modifier = Modifier
            .background(OpenFlixColors.Live, RoundedCornerShape(4.dp))
            .padding(horizontal = 8.dp, vertical = 4.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(8.dp)
                .graphicsLayer { scaleX = scale; scaleY = scale }
                .clip(CircleShape)
                .background(Color.White)
        )
        Text(
            text = "LIVE",
            fontSize = 10.sp,
            fontWeight = FontWeight.Black,
            color = Color.White
        )
    }
}

@Composable
private fun ProgramBadgeChip(badge: ProgramBadge) {
    val (color, text) = when (badge) {
        ProgramBadge.NEW -> OpenFlixColors.Success to "NEW"
        ProgramBadge.PREMIERE -> OpenFlixColors.Primary to "PREMIERE"
        ProgramBadge.FINALE -> OpenFlixColors.Warning to "FINALE"
        ProgramBadge.RECORDING -> OpenFlixColors.Recording to "REC"
        else -> OpenFlixColors.TextSecondary to badge.name
    }
    
    Text(
        text = text,
        fontSize = 9.sp,
        fontWeight = FontWeight.Bold,
        color = Color.White,
        modifier = Modifier
            .background(color, RoundedCornerShape(4.dp))
            .padding(horizontal = 6.dp, vertical = 2.dp)
    )
}

// MARK: - Now Line

@Composable
private fun ModernNowLine(
    startTimeSeconds: Long,
    scrollState: ScrollState
) {
    val now = System.currentTimeMillis() / 1000
    val minutesSinceStart = ((now - startTimeSeconds) / 60).toInt()
    val density = LocalDensity.current
    val pixelsPerMinute = with(density) { TIME_SLOT_WIDTH.toPx() / 30 }
    val offset = (CHANNEL_WIDTH.value * density.density + minutesSinceStart * pixelsPerMinute - scrollState.value).dp
    
    if (offset.value > 0) {
        Column(
            modifier = Modifier.offset(x = offset),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Triangle marker
            Canvas(modifier = Modifier.size(12.dp, 8.dp)) {
                val path = androidx.compose.ui.graphics.Path().apply {
                    moveTo(size.width / 2, 0f)
                    lineTo(size.width, size.height)
                    lineTo(0f, size.height)
                    close()
                }
                drawPath(path, Color.Red)
            }
            
            // Vertical line
            Box(
                modifier = Modifier
                    .width(2.dp)
                    .fillMaxHeight()
                    .background(
                        Brush.verticalGradient(
                            colors = listOf(Color.Red, Color.Red.copy(alpha = 0.3f))
                        )
                    )
            )
        }
    }
}

// MARK: - Now Playing Card

@Composable
private fun ModernNowPlayingCard(
    channel: Channel,
    program: Program?,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    
    Surface(
        onClick = onClick,
        modifier = modifier
            .width(280.dp)
            .onFocusChanged { isFocused = it.isFocused },
        shape = RoundedCornerShape(16.dp),
        color = OpenFlixColors.Surface.copy(alpha = 0.95f),
        border = if (isFocused) BorderStroke(2.dp, OpenFlixColors.Primary) else null,
        shadowElevation = 8.dp
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Mini preview
            Box(
                modifier = Modifier
                    .size(width = 120.dp, height = 68.dp)
                    .clip(RoundedCornerShape(8.dp))
                    .background(Color.Black),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.PlayCircle,
                    contentDescription = null,
                    modifier = Modifier.size(32.dp),
                    tint = Color.White.copy(alpha = 0.5f)
                )
                
                // LIVE badge
                Text(
                    text = "LIVE",
                    fontSize = 8.sp,
                    fontWeight = FontWeight.Black,
                    color = Color.White,
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .padding(4.dp)
                        .background(Color.Red, RoundedCornerShape(3.dp))
                        .padding(horizontal = 4.dp, vertical = 2.dp)
                )
            }
            
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = channel.name,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = Color.White
                )
                
                program?.let {
                    Text(
                        text = it.title,
                        fontSize = 12.sp,
                        color = Color.White.copy(alpha = 0.7f),
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    
                    if (it.isCurrentlyAiring) {
                        LinearProgressIndicator(
                            progress = { it.progress.toFloat() },
                            modifier = Modifier
                                .padding(top = 6.dp)
                                .fillMaxWidth()
                                .height(3.dp)
                                .clip(RoundedCornerShape(2.dp)),
                            color = OpenFlixColors.Primary,
                            trackColor = Color.White.copy(alpha = 0.2f)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Program Detail Sheet

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ModernProgramDetailSheet(
    program: Program,
    channel: Channel,
    onDismiss: () -> Unit,
    onWatch: () -> Unit,
    onRecord: () -> Unit
) {
    val sheetState = rememberModalBottomSheetState()
    
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = OpenFlixColors.Surface,
        contentColor = Color.White
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp)
        ) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = program.title,
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                    
                    program.subtitle?.let {
                        Text(
                            text = it,
                            fontSize = 16.sp,
                            color = Color.White.copy(alpha = 0.7f)
                        )
                    }
                    
                    Row(
                        modifier = Modifier.padding(top = 8.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Text(
                            text = channel.name,
                            color = OpenFlixColors.Primary,
                            fontSize = 14.sp
                        )
                        Text(
                            text = "•",
                            color = Color.White.copy(alpha = 0.5f)
                        )
                        Text(
                            text = "${formatTime(program.startTime)} - ${formatTime(program.endTime)}",
                            color = Color.White.copy(alpha = 0.7f),
                            fontSize = 14.sp
                        )
                    }
                }
                
                // Badges
                Column(
                    horizontalAlignment = Alignment.End,
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    program.badges.forEach { badge ->
                        ProgramBadgeChip(badge = badge)
                    }
                }
            }
            
            // Description
            program.description?.let {
                Text(
                    text = it,
                    fontSize = 14.sp,
                    color = Color.White.copy(alpha = 0.7f),
                    modifier = Modifier.padding(top = 16.dp),
                    maxLines = 3,
                    overflow = TextOverflow.Ellipsis
                )
            }
            
            // Progress
            if (program.isCurrentlyAiring) {
                Column(modifier = Modifier.padding(top = 16.dp)) {
                    LinearProgressIndicator(
                        progress = { program.progress.toFloat() },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(6.dp)
                            .clip(RoundedCornerShape(3.dp)),
                        color = OpenFlixColors.Primary,
                        trackColor = Color.White.copy(alpha = 0.2f)
                    )
                    
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(top = 4.dp),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = "${(program.progress * 100).toInt()}% complete",
                            fontSize = 12.sp,
                            color = Color.White.copy(alpha = 0.5f)
                        )
                        Text(
                            text = "${program.remainingMinutes} min remaining",
                            fontSize = 12.sp,
                            color = Color.White.copy(alpha = 0.5f)
                        )
                    }
                }
            }
            
            // Actions
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 24.dp),
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Button(
                    onClick = onWatch,
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color.White,
                        contentColor = Color.Black
                    )
                ) {
                    Icon(Icons.Default.PlayArrow, null)
                    Spacer(Modifier.width(8.dp))
                    Text(if (program.isCurrentlyAiring) "Watch Live" else "Watch")
                }
                
                if (!program.hasRecording && !program.hasEnded) {
                    OutlinedButton(
                        onClick = onRecord,
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.outlinedButtonColors(
                            contentColor = Color.White
                        )
                    ) {
                        Icon(Icons.Default.FiberManualRecord, null, tint = Color.Red)
                        Spacer(Modifier.width(8.dp))
                        Text("Record")
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

// MARK: - Helpers

private fun calculateProgramWidth(program: Program, startTimeSeconds: Long): Dp {
    val durationMinutes = (program.endTime - program.startTime) / 60.0
    val width = (durationMinutes / 30.0 * TIME_SLOT_WIDTH.value).dp
    return maxOf(width, 100.dp)
}

private fun formatTime(timestamp: Long): String {
    val formatter = SimpleDateFormat("h:mm a", Locale.getDefault())
    return formatter.format(Date(timestamp * 1000))
}

private fun getCategoryColor(category: String?): Color {
    return when {
        category == null -> OpenFlixColors.Primary
        category.lowercase().contains("sport") -> OpenFlixColors.SportsColor
        category.lowercase().contains("movie") -> OpenFlixColors.MoviesColor
        category.lowercase().contains("news") -> OpenFlixColors.NewsColor
        category.lowercase().contains("kid") -> OpenFlixColors.KidsColor
        category.lowercase().contains("entertain") -> OpenFlixColors.EntertainmentColor
        else -> OpenFlixColors.Primary
    }
}
