package com.openflix.presentation.screens.home;

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
public final class DiscoverViewModel_Factory implements Factory<DiscoverViewModel> {
  private final Provider<MediaRepository> mediaRepositoryProvider;

  public DiscoverViewModel_Factory(Provider<MediaRepository> mediaRepositoryProvider) {
    this.mediaRepositoryProvider = mediaRepositoryProvider;
  }

  @Override
  public DiscoverViewModel get() {
    return newInstance(mediaRepositoryProvider.get());
  }

  public static DiscoverViewModel_Factory create(
      Provider<MediaRepository> mediaRepositoryProvider) {
    return new DiscoverViewModel_Factory(mediaRepositoryProvider);
  }

  public static DiscoverViewModel newInstance(MediaRepository mediaRepository) {
    return new DiscoverViewModel(mediaRepository);
  }
}
