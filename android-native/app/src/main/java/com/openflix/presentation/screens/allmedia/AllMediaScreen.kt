package com.openflix.presentation.screens.allmedia

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Sort
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Category
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Shield
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.material3.*
import com.openflix.domain.model.MediaItem
import com.openflix.presentation.components.MediaCard
import com.openflix.presentation.theme.OpenFlixColors

@Composable
fun AllMediaScreen(
    onBackClick: () -> Unit,
    onMediaClick: (String) -> Unit,
    viewModel: AllMediaViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val gridState = rememberLazyGridState()
    var showSortMenu by remember { mutableStateOf(false) }
    var showGenreMenu by remember { mutableStateOf(false) }
    var showYearMenu by remember { mutableStateOf(false) }
    var showRatingMenu by remember { mutableStateOf(false) }
    var isSearchFocused by remember { mutableStateOf(false) }
    val searchFocusRequester = remember { FocusRequester() }
    val focusManager = LocalFocusManager.current

    // Check if any filters are active
    val hasActiveFilters = uiState.searchQuery.isNotEmpty() ||
        uiState.selectedGenre != null ||
        uiState.selectedYear != null ||
        uiState.selectedContentRating != null

    // Load more when reaching end of list
    LaunchedEffect(gridState) {
        snapshotFlow {
            val layoutInfo = gridState.layoutInfo
            val totalItems = layoutInfo.totalItemsCount
            val lastVisibleItem = layoutInfo.visibleItemsInfo.lastOrNull()?.index ?: 0
            lastVisibleItem >= totalItems - 10
        }.collect { shouldLoadMore ->
            if (shouldLoadMore && !uiState.isLoadingMore && uiState.hasMore) {
                viewModel.loadMore()
            }
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(OpenFlixColors.Background)
    ) {
        Column(modifier = Modifier.fillMaxSize()) {
            // App Bar
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 48.dp, vertical = 24.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    // Back button
                    Surface(
                        onClick = onBackClick,
                        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
                        colors = ClickableSurfaceDefaults.colors(
                            containerColor = OpenFlixColors.SurfaceVariant,
                            focusedContainerColor = OpenFlixColors.SurfaceHighlight
                        )
                    ) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back",
                            tint = OpenFlixColors.TextPrimary,
                            modifier = Modifier.padding(12.dp)
                        )
                    }

                    Column {
                        Text(
                            text = uiState.title,
                            style = MaterialTheme.typography.headlineMedium,
                            fontWeight = FontWeight.Bold,
                            color = OpenFlixColors.TextPrimary
                        )
                        if (uiState.items.isNotEmpty() || uiState.searchQuery.isNotEmpty()) {
                            val countText = if (uiState.searchQuery.isNotEmpty()) {
                                "${uiState.items.size} of ${uiState.allItems.size} items"
                            } else {
                                "${uiState.items.size}${if (uiState.hasMore) "+" else ""} items"
                            }
                            Text(
                                text = countText,
                                style = MaterialTheme.typography.bodyMedium,
                                color = OpenFlixColors.TextSecondary
                            )
                        }
                    }
                }

                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    // Search field
                    Surface(
                        onClick = { searchFocusRequester.requestFocus() },
                        modifier = Modifier
                            .width(280.dp)
                            .onFocusChanged { isSearchFocused = it.hasFocus },
                        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
                        colors = ClickableSurfaceDefaults.colors(
                            containerColor = OpenFlixColors.SurfaceVariant,
                            focusedContainerColor = OpenFlixColors.SurfaceHighlight
                        )
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Filled.Search,
                                contentDescription = "Search",
                                tint = OpenFlixColors.TextSecondary,
                                modifier = Modifier.size(20.dp)
                            )
                            BasicTextField(
                                value = uiState.searchQuery,
                                onValueChange = { viewModel.search(it) },
                                modifier = Modifier
                                    .weight(1f)
                                    .focusRequester(searchFocusRequester),
                                textStyle = TextStyle(
                                    color = OpenFlixColors.TextPrimary,
                                    fontSize = 14.sp
                                ),
                                cursorBrush = SolidColor(OpenFlixColors.Primary),
                                singleLine = true,
                                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                                keyboardActions = KeyboardActions(
                                    onSearch = { focusManager.clearFocus() }
                                ),
                                decorationBox = { innerTextField ->
                                    Box {
                                        if (uiState.searchQuery.isEmpty()) {
                                            Text(
                                                text = "Search...",
                                                style = MaterialTheme.typography.bodyMedium,
                                                color = OpenFlixColors.TextTertiary
                                            )
                                        }
                                        innerTextField()
                                    }
                                }
                            )
                            if (uiState.searchQuery.isNotEmpty()) {
                                Surface(
                                    onClick = { viewModel.search("") },
                                    modifier = Modifier.size(20.dp),
                                    shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(10.dp)),
                                    colors = ClickableSurfaceDefaults.colors(
                                        containerColor = OpenFlixColors.TextTertiary.copy(alpha = 0.3f),
                                        focusedContainerColor = OpenFlixColors.Primary
                                    )
                                ) {
                                    Icon(
                                        imageVector = Icons.Filled.Clear,
                                        contentDescription = "Clear search",
                                        tint = OpenFlixColors.TextPrimary,
                                        modifier = Modifier
                                            .fillMaxSize()
                                            .padding(2.dp)
                                    )
                                }
                            }
                        }
                    }

                    // Sort button
                    Surface(
                        onClick = { showSortMenu = !showSortMenu; showGenreMenu = false; showYearMenu = false; showRatingMenu = false },
                        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
                        colors = ClickableSurfaceDefaults.colors(
                            containerColor = OpenFlixColors.SurfaceVariant,
                            focusedContainerColor = OpenFlixColors.SurfaceHighlight
                        )
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Icon(
                                imageVector = Icons.AutoMirrored.Filled.Sort,
                                contentDescription = "Sort",
                                tint = OpenFlixColors.TextPrimary
                            )
                            Text(
                                text = when (uiState.sortBy) {
                                    SortOption.TITLE -> "Title"
                                    SortOption.DATE_ADDED -> "Date Added"
                                    SortOption.YEAR -> "Year"
                                    SortOption.RATING -> "Rating"
                                },
                                style = MaterialTheme.typography.bodyMedium,
                                color = OpenFlixColors.TextPrimary
                            )
                        }
                    }
                }
            }

            // Filter row with genre, year, and sort buttons
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 48.dp)
                    .padding(bottom = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Genre filter button
                Surface(
                    onClick = { showGenreMenu = !showGenreMenu; showYearMenu = false; showSortMenu = false; showRatingMenu = false },
                    shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
                    colors = ClickableSurfaceDefaults.colors(
                        containerColor = if (uiState.selectedGenre != null)
                            OpenFlixColors.Primary.copy(alpha = 0.2f)
                        else OpenFlixColors.SurfaceVariant,
                        focusedContainerColor = OpenFlixColors.SurfaceHighlight
                    )
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Filled.Category,
                            contentDescription = "Genre",
                            tint = if (uiState.selectedGenre != null) OpenFlixColors.Primary else OpenFlixColors.TextSecondary,
                            modifier = Modifier.size(18.dp)
                        )
                        Text(
                            text = uiState.selectedGenre ?: "Genre",
                            style = MaterialTheme.typography.bodyMedium,
                            color = OpenFlixColors.TextPrimary
                        )
                    }
                }

                // Year filter button
                Surface(
                    onClick = { showYearMenu = !showYearMenu; showGenreMenu = false; showSortMenu = false; showRatingMenu = false },
                    shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
                    colors = ClickableSurfaceDefaults.colors(
                        containerColor = if (uiState.selectedYear != null)
                            OpenFlixColors.Primary.copy(alpha = 0.2f)
                        else OpenFlixColors.SurfaceVariant,
                        focusedContainerColor = OpenFlixColors.SurfaceHighlight
                    )
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Filled.CalendarMonth,
                            contentDescription = "Year",
                            tint = if (uiState.selectedYear != null) OpenFlixColors.Primary else OpenFlixColors.TextSecondary,
                            modifier = Modifier.size(18.dp)
                        )
                        Text(
                            text = uiState.selectedYear?.toString() ?: "Year",
                            style = MaterialTheme.typography.bodyMedium,
                            color = OpenFlixColors.TextPrimary
                        )
                    }
                }

                // Content Rating filter button
                Surface(
                    onClick = { showRatingMenu = !showRatingMenu; showGenreMenu = false; showYearMenu = false; showSortMenu = false },
                    shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
                    colors = ClickableSurfaceDefaults.colors(
                        containerColor = if (uiState.selectedContentRating != null)
                            OpenFlixColors.Primary.copy(alpha = 0.2f)
                        else OpenFlixColors.SurfaceVariant,
                        focusedContainerColor = OpenFlixColors.SurfaceHighlight
                    )
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Filled.Shield,
                            contentDescription = "Rating",
                            tint = if (uiState.selectedContentRating != null) OpenFlixColors.Primary else OpenFlixColors.TextSecondary,
                            modifier = Modifier.size(18.dp)
                        )
                        Text(
                            text = uiState.selectedContentRating ?: "Rating",
                            style = MaterialTheme.typography.bodyMedium,
                            color = OpenFlixColors.TextPrimary
                        )
                    }
                }

                // Clear filters button (only show when filters are active)
                if (hasActiveFilters) {
                    Surface(
                        onClick = { viewModel.clearFilters() },
                        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
                        colors = ClickableSurfaceDefaults.colors(
                            containerColor = OpenFlixColors.Error.copy(alpha = 0.2f),
                            focusedContainerColor = OpenFlixColors.Error.copy(alpha = 0.3f)
                        )
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Filled.Clear,
                                contentDescription = "Clear filters",
                                tint = OpenFlixColors.Error,
                                modifier = Modifier.size(18.dp)
                            )
                            Text(
                                text = "Clear",
                                style = MaterialTheme.typography.bodyMedium,
                                color = OpenFlixColors.Error
                            )
                        }
                    }
                }
            }

            // Genre menu dropdown
            if (showGenreMenu && uiState.availableGenres.isNotEmpty()) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 48.dp)
                        .padding(bottom = 16.dp),
                    horizontalArrangement = Arrangement.Start
                ) {
                    Surface(
                        modifier = Modifier.widthIn(min = 200.dp, max = 300.dp),
                        shape = RoundedCornerShape(8.dp),
                        tonalElevation = 8.dp
                    ) {
                        Column(
                            modifier = Modifier
                                .background(OpenFlixColors.Surface)
                                .heightIn(max = 400.dp)
                        ) {
                            // "All Genres" option
                            Surface(
                                onClick = {
                                    viewModel.setGenreFilter(null)
                                    showGenreMenu = false
                                },
                                modifier = Modifier.fillMaxWidth(),
                                colors = ClickableSurfaceDefaults.colors(
                                    containerColor = if (uiState.selectedGenre == null)
                                        OpenFlixColors.Primary.copy(alpha = 0.2f)
                                    else OpenFlixColors.Surface,
                                    focusedContainerColor = OpenFlixColors.SurfaceHighlight
                                )
                            ) {
                                Text(
                                    text = "All Genres",
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.SemiBold,
                                    color = OpenFlixColors.TextPrimary,
                                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)
                                )
                            }
                            uiState.availableGenres.forEach { genre ->
                                Surface(
                                    onClick = {
                                        viewModel.setGenreFilter(genre)
                                        showGenreMenu = false
                                    },
                                    modifier = Modifier.fillMaxWidth(),
                                    colors = ClickableSurfaceDefaults.colors(
                                        containerColor = if (uiState.selectedGenre == genre)
                                            OpenFlixColors.Primary.copy(alpha = 0.2f)
                                        else OpenFlixColors.Surface,
                                        focusedContainerColor = OpenFlixColors.SurfaceHighlight
                                    )
                                ) {
                                    Text(
                                        text = genre,
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = OpenFlixColors.TextPrimary,
                                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)
                                    )
                                }
                            }
                        }
                    }
                }
            }

            // Year menu dropdown
            if (showYearMenu && uiState.availableYears.isNotEmpty()) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 48.dp)
                        .padding(bottom = 16.dp),
                    horizontalArrangement = Arrangement.Start
                ) {
                    Surface(
                        modifier = Modifier.widthIn(min = 150.dp, max = 200.dp),
                        shape = RoundedCornerShape(8.dp),
                        tonalElevation = 8.dp
                    ) {
                        Column(
                            modifier = Modifier
                                .background(OpenFlixColors.Surface)
                                .heightIn(max = 400.dp)
                        ) {
                            // "All Years" option
                            Surface(
                                onClick = {
                                    viewModel.setYearFilter(null)
                                    showYearMenu = false
                                },
                                modifier = Modifier.fillMaxWidth(),
                                colors = ClickableSurfaceDefaults.colors(
                                    containerColor = if (uiState.selectedYear == null)
                                        OpenFlixColors.Primary.copy(alpha = 0.2f)
                                    else OpenFlixColors.Surface,
                                    focusedContainerColor = OpenFlixColors.SurfaceHighlight
                                )
                            ) {
                                Text(
                                    text = "All Years",
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.SemiBold,
                                    color = OpenFlixColors.TextPrimary,
                                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)
                                )
                            }
                            uiState.availableYears.forEach { year ->
                                Surface(
                                    onClick = {
                                        viewModel.setYearFilter(year)
                                        showYearMenu = false
                                    },
                                    modifier = Modifier.fillMaxWidth(),
                                    colors = ClickableSurfaceDefaults.colors(
                                        containerColor = if (uiState.selectedYear == year)
                                            OpenFlixColors.Primary.copy(alpha = 0.2f)
                                        else OpenFlixColors.Surface,
                                        focusedContainerColor = OpenFlixColors.SurfaceHighlight
                                    )
                                ) {
                                    Text(
                                        text = year.toString(),
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = OpenFlixColors.TextPrimary,
                                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)
                                    )
                                }
                            }
                        }
                    }
                }
            }

            // Content Rating menu dropdown
            if (showRatingMenu && uiState.availableContentRatings.isNotEmpty()) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 48.dp)
                        .padding(bottom = 16.dp),
                    horizontalArrangement = Arrangement.Start
                ) {
                    Surface(
                        modifier = Modifier.widthIn(min = 150.dp, max = 200.dp),
                        shape = RoundedCornerShape(8.dp),
                        tonalElevation = 8.dp
                    ) {
                        Column(
                            modifier = Modifier
                                .background(OpenFlixColors.Surface)
                                .heightIn(max = 400.dp)
                        ) {
                            // "All Ratings" option
                            Surface(
                                onClick = {
                                    viewModel.setContentRatingFilter(null)
                                    showRatingMenu = false
                                },
                                modifier = Modifier.fillMaxWidth(),
                                colors = ClickableSurfaceDefaults.colors(
                                    containerColor = if (uiState.selectedContentRating == null)
                                        OpenFlixColors.Primary.copy(alpha = 0.2f)
                                    else OpenFlixColors.Surface,
                                    focusedContainerColor = OpenFlixColors.SurfaceHighlight
                                )
                            ) {
                                Text(
                                    text = "All Ratings",
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.SemiBold,
                                    color = OpenFlixColors.TextPrimary,
                                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)
                                )
                            }
                            uiState.availableContentRatings.forEach { rating ->
                                Surface(
                                    onClick = {
                                        viewModel.setContentRatingFilter(rating)
                                        showRatingMenu = false
                                    },
                                    modifier = Modifier.fillMaxWidth(),
                                    colors = ClickableSurfaceDefaults.colors(
                                        containerColor = if (uiState.selectedContentRating == rating)
                                            OpenFlixColors.Primary.copy(alpha = 0.2f)
                                        else OpenFlixColors.Surface,
                                        focusedContainerColor = OpenFlixColors.SurfaceHighlight
                                    )
                                ) {
                                    Text(
                                        text = rating,
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = OpenFlixColors.TextPrimary,
                                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)
                                    )
                                }
                            }
                        }
                    }
                }
            }

            // Sort menu dropdown
            if (showSortMenu) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 48.dp)
                        .padding(bottom = 16.dp),
                    horizontalArrangement = Arrangement.End
                ) {
                    Surface(
                        modifier = Modifier.width(200.dp),
                        shape = RoundedCornerShape(8.dp),
                        tonalElevation = 8.dp
                    ) {
                        Column(modifier = Modifier.background(OpenFlixColors.Surface)) {
                            SortOption.entries.forEach { option ->
                                Surface(
                                    onClick = {
                                        viewModel.setSortBy(option)
                                        showSortMenu = false
                                    },
                                    modifier = Modifier.fillMaxWidth(),
                                    colors = ClickableSurfaceDefaults.colors(
                                        containerColor = if (uiState.sortBy == option)
                                            OpenFlixColors.Primary.copy(alpha = 0.2f)
                                        else OpenFlixColors.Surface,
                                        focusedContainerColor = OpenFlixColors.SurfaceHighlight
                                    )
                                ) {
                                    Text(
                                        text = when (option) {
                                            SortOption.TITLE -> "Title"
                                            SortOption.DATE_ADDED -> "Date Added"
                                            SortOption.YEAR -> "Year"
                                            SortOption.RATING -> "Rating"
                                        },
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = OpenFlixColors.TextPrimary,
                                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)
                                    )
                                }
                            }
                        }
                    }
                }
            }

            // Content
            when {
                uiState.isLoading -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "Loading...",
                            style = MaterialTheme.typography.bodyLarge,
                            color = OpenFlixColors.TextSecondary
                        )
                    }
                }
                uiState.error != null -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(16.dp)
                        ) {
                            Text(
                                text = uiState.error!!,
                                style = MaterialTheme.typography.bodyLarge,
                                color = OpenFlixColors.Error
                            )
                            Surface(
                                onClick = viewModel::refresh,
                                shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
                                colors = ClickableSurfaceDefaults.colors(
                                    containerColor = OpenFlixColors.SurfaceVariant,
                                    focusedContainerColor = OpenFlixColors.SurfaceHighlight
                                )
                            ) {
                                Text(
                                    text = "Retry",
                                    style = MaterialTheme.typography.titleMedium,
                                    color = OpenFlixColors.TextPrimary,
                                    modifier = Modifier.padding(horizontal = 24.dp, vertical = 12.dp)
                                )
                            }
                        }
                    }
                }
                uiState.items.isEmpty() -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Filled.Search,
                                contentDescription = null,
                                tint = OpenFlixColors.TextTertiary,
                                modifier = Modifier.size(48.dp)
                            )
                            Text(
                                text = if (uiState.searchQuery.isNotEmpty()) {
                                    "No results for \"${uiState.searchQuery}\""
                                } else {
                                    "No items found"
                                },
                                style = MaterialTheme.typography.bodyLarge,
                                color = OpenFlixColors.TextSecondary
                            )
                            if (uiState.searchQuery.isNotEmpty()) {
                                Surface(
                                    onClick = { viewModel.search("") },
                                    shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
                                    colors = ClickableSurfaceDefaults.colors(
                                        containerColor = OpenFlixColors.SurfaceVariant,
                                        focusedContainerColor = OpenFlixColors.SurfaceHighlight
                                    )
                                ) {
                                    Text(
                                        text = "Clear Search",
                                        style = MaterialTheme.typography.titleMedium,
                                        color = OpenFlixColors.TextPrimary,
                                        modifier = Modifier.padding(horizontal = 24.dp, vertical = 12.dp)
                                    )
                                }
                            }
                        }
                    }
                }
                else -> {
                    LazyVerticalGrid(
                        columns = GridCells.Adaptive(minSize = 180.dp),
                        state = gridState,
                        contentPadding = PaddingValues(
                            start = 48.dp,
                            end = 48.dp,
                            bottom = 48.dp
                        ),
                        horizontalArrangement = Arrangement.spacedBy(20.dp),
                        verticalArrangement = Arrangement.spacedBy(20.dp),
                        modifier = Modifier.fillMaxSize()
                    ) {
                        items(
                            items = uiState.items,
                            key = { it.id }
                        ) { item ->
                            MediaCard(
                                mediaItem = item,
                                onClick = { onMediaClick(item.id) },
                                width = 180.dp,
                                aspectRatio = 1.5f
                            )
                        }

                        // Loading indicator at bottom
                        if (uiState.isLoadingMore) {
                            item(span = { GridItemSpan(maxLineSpan) }) {
                                Box(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(24.dp),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text(
                                        text = "Loading more...",
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = OpenFlixColors.TextSecondary
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
