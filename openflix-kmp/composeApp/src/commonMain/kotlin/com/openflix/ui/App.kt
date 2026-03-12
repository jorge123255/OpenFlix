package com.openflix.ui

import androidx.compose.runtime.Composable
import com.openflix.ui.theme.OpenFlixTheme
import com.openflix.ui.navigation.AppNavigation

@Composable
fun App() {
    OpenFlixTheme {
        AppNavigation()
    }
}
