package com.openflix.presentation.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.tv.material3.MaterialTheme
import androidx.tv.material3.Text
import com.openflix.presentation.theme.OpenFlixColors

/**
 * TV-optimized text field with focus indication
 */
@Composable
fun FocusableTextField(
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    label: String? = null,
    placeholder: String? = null,
    enabled: Boolean = true,
    singleLine: Boolean = false,
    maxLines: Int = if (singleLine) 1 else Int.MAX_VALUE,
    visualTransformation: VisualTransformation = VisualTransformation.None,
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default.copy(
        imeAction = ImeAction.Next
    ),
    keyboardActions: KeyboardActions = KeyboardActions.Default
) {
    var isFocused by remember { mutableStateOf(false) }
    val innerFocusRequester = remember { FocusRequester() }

    Column(modifier = modifier) {
        // Label
        if (label != null) {
            Text(
                text = label,
                style = MaterialTheme.typography.labelMedium,
                color = if (isFocused) OpenFlixColors.Primary else OpenFlixColors.TextSecondary,
                modifier = Modifier.padding(bottom = 8.dp)
            )
        }

        // Text Field Container - clickable for touch devices
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clickable(
                    interactionSource = remember { MutableInteractionSource() },
                    indication = null
                ) {
                    innerFocusRequester.requestFocus()
                }
                .background(
                    color = if (isFocused) OpenFlixColors.FocusBackground else OpenFlixColors.SurfaceVariant,
                    shape = MaterialTheme.shapes.medium
                )
                .border(
                    width = if (isFocused) 2.dp else 1.dp,
                    color = if (isFocused) OpenFlixColors.Primary else OpenFlixColors.Divider,
                    shape = MaterialTheme.shapes.medium
                )
                .padding(horizontal = 16.dp, vertical = 14.dp)
        ) {
            BasicTextField(
                value = value,
                onValueChange = onValueChange,
                modifier = Modifier
                    .fillMaxWidth()
                    .focusRequester(innerFocusRequester)
                    .onFocusChanged { focusState ->
                        isFocused = focusState.isFocused
                    },
                enabled = enabled,
                textStyle = TextStyle(
                    color = OpenFlixColors.OnSurface,
                    fontSize = 18.sp
                ),
                singleLine = singleLine,
                maxLines = maxLines,
                visualTransformation = visualTransformation,
                keyboardOptions = keyboardOptions,
                keyboardActions = keyboardActions,
                cursorBrush = SolidColor(OpenFlixColors.Primary),
                decorationBox = { innerTextField ->
                    Box(
                        modifier = Modifier.fillMaxWidth(),
                        contentAlignment = Alignment.CenterStart
                    ) {
                        if (value.isEmpty() && placeholder != null) {
                            Text(
                                text = placeholder,
                                style = MaterialTheme.typography.bodyLarge,
                                color = OpenFlixColors.TextTertiary
                            )
                        }
                        innerTextField()
                    }
                }
            )
        }
    }
}
