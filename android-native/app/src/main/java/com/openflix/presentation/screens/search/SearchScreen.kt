package com.openflix.presentation.screens.search

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.material3.*
import com.openflix.presentation.components.FocusableTextField
import com.openflix.presentation.components.MediaCard
import com.openflix.presentation.theme.OpenFlixColors

@Composable
fun SearchScreen(
    onBack: () -> Unit,
    onMediaSelected: (String) -> Unit,
    viewModel: SearchViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val searchFocusRequester = remember { FocusRequester() }

    LaunchedEffect(Unit) {
        searchFocusRequester.requestFocus()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp)
    ) {
        // Header with back button
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Button(onClick = onBack) {
                Text("Back")
            }

            Spacer(modifier = Modifier.width(24.dp))

            FocusableTextField(
                value = uiState.query,
                onValueChange = viewModel::updateQuery,
                label = "Search",
                placeholder = "Search movies, shows, episodes...",
                modifier = Modifier
                    .weight(1f)
                    .focusRequester(searchFocusRequester),
                singleLine = true
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        // Results
        when {
            uiState.isLoading -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text("Searching...", color = OpenFlixColors.TextSecondary)
                }
            }
            uiState.query.isBlank() -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "Enter a search term to find content",
                        style = MaterialTheme.typography.bodyLarge,
                        color = OpenFlixColors.TextTertiary
                    )
                }
            }
            uiState.results.isEmpty() -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "No results found for \"${uiState.query}\"",
                        style = MaterialTheme.typography.bodyLarge,
                        color = OpenFlixColors.TextSecondary
                    )
                }
            }
            else -> {
                Text(
                    text = "${uiState.results.size} results",
                    style = MaterialTheme.typography.bodyMedium,
                    color = OpenFlixColors.TextTertiary
                )

                Spacer(modifier = Modifier.height(16.dp))

                LazyVerticalGrid(
                    columns = GridCells.Adaptive(minSize = 160.dp),
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    items(uiState.results) { item ->
                        MediaCard(
                            mediaItem = item,
                            onClick = { onMediaSelected(item.id) }
                        )
                    }
                }
            }
        }
    }
}
