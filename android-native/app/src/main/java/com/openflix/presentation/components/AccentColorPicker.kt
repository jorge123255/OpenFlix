package com.openflix.presentation.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog

/**
 * Predefined accent colors like Tivimate
 */
object AccentColors {
    val colors = listOf(
        // Blues
        0xFF3B82F6L to "Blue",
        0xFF6366F1L to "Indigo",
        0xFF8B5CF6L to "Violet",
        0xFFA855F7L to "Purple",

        // Pinks/Reds
        0xFFEC4899L to "Pink",
        0xFFF43F5EL to "Rose",
        0xFFEF4444L to "Red",
        0xFFF97316L to "Orange",

        // Yellows/Greens
        0xFFF59E0BL to "Amber",
        0xFFEAB308L to "Yellow",
        0xFF84CC16L to "Lime",
        0xFF22C55EL to "Green",

        // Teals/Cyans
        0xFF10B981L to "Emerald",
        0xFF14B8A6L to "Teal",
        0xFF06B6D4L to "Cyan",
        0xFF0EA5E9L to "Sky",

        // Neutrals
        0xFF64748BL to "Slate",
        0xFF78716CL to "Stone",
        0xFF737373L to "Gray",
        0xFFA3A3A3L to "Silver"
    )
}

/**
 * Color picker dialog for selecting accent color
 */
@Composable
fun AccentColorPickerDialog(
    currentColor: Long,
    onColorSelected: (Long) -> Unit,
    onDismiss: () -> Unit
) {
    Dialog(onDismissRequest = onDismiss) {
        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            shape = RoundedCornerShape(16.dp),
            color = Color(0xFF1a1a2e)
        ) {
            Column(
                modifier = Modifier.padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "Choose Accent Color",
                    color = Color.White,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold
                )

                Spacer(modifier = Modifier.height(8.dp))

                Text(
                    text = "This color will be used throughout the app",
                    color = Color.Gray,
                    fontSize = 14.sp
                )

                Spacer(modifier = Modifier.height(24.dp))

                // Color grid
                LazyVerticalGrid(
                    columns = GridCells.Fixed(4),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                    modifier = Modifier.height(280.dp)
                ) {
                    items(AccentColors.colors) { (colorValue, colorName) ->
                        ColorOption(
                            color = Color(colorValue),
                            name = colorName,
                            isSelected = colorValue == currentColor,
                            onClick = {
                                onColorSelected(colorValue)
                                onDismiss()
                            }
                        )
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // Cancel button
                TextButton(onClick = onDismiss) {
                    Text("Cancel", color = Color.Gray)
                }
            }
        }
    }
}

@Composable
private fun ColorOption(
    color: Color,
    name: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    val borderColor by animateColorAsState(
        targetValue = if (isSelected) Color.White else Color.Transparent,
        label = "border"
    )

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.clickable { onClick() }
    ) {
        Box(
            modifier = Modifier
                .size(48.dp)
                .clip(CircleShape)
                .background(color)
                .border(3.dp, borderColor, CircleShape),
            contentAlignment = Alignment.Center
        ) {
            if (isSelected) {
                Icon(
                    imageVector = Icons.Default.Check,
                    contentDescription = "Selected",
                    tint = Color.White,
                    modifier = Modifier.size(24.dp)
                )
            }
        }

        Spacer(modifier = Modifier.height(4.dp))

        Text(
            text = name,
            color = if (isSelected) color else Color.Gray,
            fontSize = 10.sp,
            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
        )
    }
}

/**
 * Settings row for accent color selection
 */
@Composable
fun AccentColorSettingRow(
    currentColor: Long,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() }
            .padding(vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Column {
            Text(
                text = "Accent Color",
                color = Color.White,
                fontSize = 16.sp
            )
            Text(
                text = AccentColors.colors.find { it.first == currentColor }?.second ?: "Custom",
                color = Color.Gray,
                fontSize = 13.sp
            )
        }

        // Color preview
        Box(
            modifier = Modifier
                .size(32.dp)
                .clip(CircleShape)
                .background(Color(currentColor))
                .border(2.dp, Color.White.copy(alpha = 0.3f), CircleShape)
        )
    }
}
