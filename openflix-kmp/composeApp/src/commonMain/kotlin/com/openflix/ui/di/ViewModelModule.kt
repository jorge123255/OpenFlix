package com.openflix.ui.di

import com.openflix.ui.viewmodel.HomeViewModel
import com.openflix.ui.viewmodel.LibraryViewModel
import com.openflix.ui.viewmodel.LiveTVViewModel
import com.openflix.ui.viewmodel.SearchViewModel
import org.koin.core.module.dsl.viewModel
import org.koin.dsl.module

val viewModelModule = module {
    viewModel { HomeViewModel(get(), get(), get()) }
    viewModel { LiveTVViewModel(get()) }
    viewModel { SearchViewModel(get()) }
    viewModel { LibraryViewModel(get(), get()) }
}
