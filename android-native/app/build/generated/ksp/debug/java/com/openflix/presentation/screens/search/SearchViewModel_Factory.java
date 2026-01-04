package com.openflix.presentation.screens.search;

import com.openflix.data.repository.MediaRepository;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;

@ScopeMetadata
@QualifierMetadata
@DaggerGenerated
@Generated(
    value = "dagger.internal.codegen.ComponentProcessor",
    comments = "https://dagger.dev"
)
@SuppressWarnings({
    "unchecked",
    "rawtypes",
    "KotlinInternal",
    "KotlinInternalInJava"
})
public final class SearchViewModel_Factory implements Factory<SearchViewModel> {
  private final Provider<MediaRepository> mediaRepositoryProvider;

  public SearchViewModel_Factory(Provider<MediaRepository> mediaRepositoryProvider) {
    this.mediaRepositoryProvider = mediaRepositoryProvider;
  }

  @Override
  public SearchViewModel get() {
    return newInstance(mediaRepositoryProvider.get());
  }

  public static SearchViewModel_Factory create(Provider<MediaRepository> mediaRepositoryProvider) {
    return new SearchViewModel_Factory(mediaRepositoryProvider);
  }

  public static SearchViewModel newInstance(MediaRepository mediaRepository) {
    return new SearchViewModel(mediaRepository);
  }
}
