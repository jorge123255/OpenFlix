package com.openflix.presentation.screens.media;

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
public final class MediaDetailViewModel_Factory implements Factory<MediaDetailViewModel> {
  private final Provider<MediaRepository> mediaRepositoryProvider;

  public MediaDetailViewModel_Factory(Provider<MediaRepository> mediaRepositoryProvider) {
    this.mediaRepositoryProvider = mediaRepositoryProvider;
  }

  @Override
  public MediaDetailViewModel get() {
    return newInstance(mediaRepositoryProvider.get());
  }

  public static MediaDetailViewModel_Factory create(
      Provider<MediaRepository> mediaRepositoryProvider) {
    return new MediaDetailViewModel_Factory(mediaRepositoryProvider);
  }

  public static MediaDetailViewModel newInstance(MediaRepository mediaRepository) {
    return new MediaDetailViewModel(mediaRepository);
  }
}
