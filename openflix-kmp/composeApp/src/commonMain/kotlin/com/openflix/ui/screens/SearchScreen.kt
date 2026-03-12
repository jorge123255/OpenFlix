package com.openflix.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil3.compose.AsyncImage
import com.openflix.domain.model.MediaItem
import com.openflix.ui.theme.OpenFlixColors
import com.openflix.ui.viewmodel.SearchViewModel
import org.koin.compose.viewmodel.koinViewModel

private data class GenreTile(val name: String, val color: Color)

private val genreTiles = listOf(
    GenreTile("Action", Color(0xFFE53E3E)),
    GenreTile("Comedy", Color(0xFFDD6B20)),
    GenreTile("Drama", Color(0xFF805AD5)),
    GenreTile("Sci-Fi", Color(0xFF3182CE)),
    GenreTile("Horror", Color(0xFF1A202C)),
    GenreTile("Romance", Color(0xFFD53F8C)),
    GenreTile("Thriller", Color(0xFF2D3748)),
    GenreTile("Animation", Color(0xFF38A169)),
    GenreTile("Documentary", Color(0xFF718096)),
    GenreTile("Kids", Color(0xFFED8936)),
    GenreTile("Music", Color(0xFF9F7AEA)),
    GenreTile("Sports", Color(0xFF319795))
)

@Composable
fun SearchScreen(
    onMediaClick: (String) -> Unit = {},
    viewModel: SearchViewModel = koinViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(OpenFlixColors.Background)
            .padding(horizontal = 16.dp)
    ) {
        Spacer(modifier = Modifier.height(12.dp))

        // Search bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(12.dp))
                .background(OpenFlixColors.SurfaceElevated)
                .padding(horizontal = 12.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.Search,
                contentDescription = null,
                tint = OpenFlixColors.TextTertiary,
                modifier = Modifier.size(20.dp)
            )

            Spacer(modifier = Modifier.width(8.dp))

            Box(modifier = Modifier.weight(1f)) {
                if (uiState.query.isEmpty()) {
                    Text(
                        text = "Search movies, shows, sports...",
                        color = OpenFlixColors.TextTertiary,
                        fontSize = 15.sp
                    )
                }
                BasicTextField(
                    value = uiState.query,
                    onValueChange = viewModel::updateQuery,
                    singleLine = true,
                    textStyle = TextStyle(
                        color = OpenFlixColors.TextPrimary,
                        fontSize = 15.sp
                    ),
                    cursorBrush = SolidColor(OpenFlixColors.Primary),
                    modifier = Modifier.fillMaxWidth()
                )
            }

            if (uiState.query.isNotEmpty()) {
                Box(
                    modifier = Modifier
                        .size(28.dp)
                        .clip(CircleShape)
                        .background(OpenFlixColors.TextTertiary.copy(alpha = 0.3f))
                        .clickable { viewModel.updateQuery("") },
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Close,
                        contentDescription = "Clear",
                        tint = Color.White,
                        modifier = Modifier.size(16.dp)
                    )
                }
                Spacer(modifier = Modifier.width(8.dp))
            }

            Icon(
                imageVector = Icons.Default.Search,
                contentDescription = "Voice search",
                tint = OpenFlixColors.TextTertiary,
                modifier = Modifier.size(22.dp)
            )
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Content
        when {
            uiState.isLoading -> {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = OpenFlixColors.Primary, modifier = Modifier.size(32.dp))
                }
            }
            uiState.query.isBlank() && uiState.selectedGenre == null -> {
                GenreBrowseGrid(onGenreSelected = viewModel::searchByGenre)
            }
            uiState.results.isEmpty() -> {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    val searchTerm = uiState.selectedGenre ?: uiState.query
                    Text(
                        text = "No results found for \"$searchTerm\"",
                        style = MaterialTheme.typography.bodyLarge,
                        color = OpenFlixColors.TextSecondary
                    )
                }
            }
            uiState.groupedResults.isNotEmpty() -> {
                GroupedSearchResults(
                    groupedResults = uiState.groupedResults,
                    onMediaClick = onMediaClick
                )
            }
        }
    }
}

@Composable
private fun GenreBrowseGrid(onGenreSelected: (String) -> Unit) {
    Column {
        Text(
            text = "Browse by Genre",
            color = OpenFlixColors.TextPrimary,
            fontSize = 24.sp,
            fontWeight = FontWeight.Bold
        )

        Spacer(modifier = Modifier.height(20.dp))

        LazyVerticalGrid(
            columns = GridCells.Fixed(3),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            items(genreTiles) { genre ->
                GenreTileCard(
                    genre = genre,
                    onClick = { onGenreSelected(genre.name) }
                )
            }
        }
    }
}

@Composable
private fun GenreTileCard(
    genre: GenreTile,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .aspectRatio(1f)
            .clip(RoundedCornerShape(12.dp))
            .background(genre.color)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.BottomCenter
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        colors = listOf(Color.Transparent, Color.Black.copy(alpha = 0.5f))
                    )
                )
        )
        Text(
            text = genre.name,
            color = Color.White,
            fontSize = 14.sp,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center,
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp)
        )
    }
}

@Composable
private fun GroupedSearchResults(
    groupedResults: Map<String, List<MediaItem>>,
    onMediaClick: (String) -> Unit
) {
    LazyColumn(
        verticalArrangement = Arrangement.spacedBy(24.dp)
    ) {
        groupedResults.forEach { (sectionTitle, items) ->
            item {
                Column {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = sectionTitle,
                            color = OpenFlixColors.TextPrimary,
                            fontSize = 20.sp,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = "${items.size} results",
                            color = OpenFlixColors.TextTertiary,
                            fontSize = 14.sp
                        )
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    LazyRow(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        items(items) { item ->
                            SearchResultCard(
                                item = item,
                                onClick = { onMediaClick(item.key) }
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun SearchResultCard(
    item: MediaItem,
    onClick: () -> Unit
) {
    Column(
        modifier = Modifier
            .width(130.dp)
            .clickable(onClick = onClick)
    ) {
        Box(
            modifier = Modifier
                .size(130.dp, 195.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(OpenFlixColors.Card)
        ) {
            val imageUrl = item.thumb
            if (imageUrl != null) {
                AsyncImage(
                    model = imageUrl,
                    contentDescription = item.title,
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )
            }
        }
        Spacer(modifier = Modifier.height(6.dp))
        Text(
            text = item.title,
            color = OpenFlixColors.TextPrimary,
            fontSize = 13.sp,
            fontWeight = FontWeight.Medium,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis
        )
    }
}
