package com.openflix.presentation.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.openflix.presentation.theme.OpenFlixColors

/**
 * Page indicator dots for carousel navigation.
 */
@Composable
fun PageIndicator(
    pageCount: Int,
    currentPage: Int,
    modifier: Modifier = Modifier,
    activeColor: Color = OpenFlixColors.Primary,
    inactiveColor: Color = OpenFlixColors.TextSecondary.copy(alpha = 0.4f),
    activeWidth: Dp = 24.dp,
    inactiveWidth: Dp = 8.dp,
    dotHeight: Dp = 8.dp,
    dotSpacing: Dp = 8.dp
) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(dotSpacing),
        verticalAlignment = Alignment.CenterVertically
    ) {
        repeat(pageCount) { index ->
            val isActive = index == currentPage

            val width by animateDpAsState(
                targetValue = if (isActive) activeWidth else inactiveWidth,
                animationSpec = tween(durationMillis = 300),
                label = "dot_width"
            )

            val color by animateColorAsState(
                targetValue = if (isActive) activeColor else inactiveColor,
                animationSpec = tween(durationMillis = 300),
                label = "dot_color"
            )

            Box(
                modifier = Modifier
                    .width(width)
                    .height(dotHeight)
                    .clip(CircleShape)
                    .background(color)
            )
        }
    }
}

/**
 * Circular page indicator (simpler dots)
 */
@Composable
fun CircularPageIndicator(
    pageCount: Int,
    currentPage: Int,
    modifier: Modifier = Modifier,
    activeColor: Color = OpenFlixColors.Primary,
    inactiveColor: Color = OpenFlixColors.TextSecondary.copy(alpha = 0.4f),
    dotSize: Dp = 8.dp,
    activeDotSize: Dp = 10.dp,
    dotSpacing: Dp = 8.dp
) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(dotSpacing),
        verticalAlignment = Alignment.CenterVertically
    ) {
        repeat(pageCount) { index ->
            val isActive = index == currentPage

            val size by animateDpAsState(
                targetValue = if (isActive) activeDotSize else dotSize,
                animationSpec = tween(durationMillis = 200),
                label = "dot_size"
            )

            val color by animateColorAsState(
                targetValue = if (isActive) activeColor else inactiveColor,
                animationSpec = tween(durationMillis = 200),
                label = "dot_color"
            )

            Box(
                modifier = Modifier
                    .size(size)
                    .clip(CircleShape)
                    .background(color)
            )
        }
    }
}
