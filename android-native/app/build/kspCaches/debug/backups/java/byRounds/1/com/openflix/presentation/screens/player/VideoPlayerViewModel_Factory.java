package com.openflix.presentation.screens.player;

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
public final class VideoPlayerViewModel_Factory implements Factory<VideoPlayerViewModel> {
  private final Provider<MediaRepository> repositoryProvider;

  public VideoPlayerViewModel_Factory(Provider<MediaRepository> repositoryProvider) {
    this.repositoryProvider = repositoryProvider;
  }

  @Override
  public VideoPlayerViewModel get() {
    return newInstance(repositoryProvider.get());
  }

  public static VideoPlayerViewModel_Factory create(Provider<MediaRepository> repositoryProvider) {
    return new VideoPlayerViewModel_Factory(repositoryProvider);
  }

  public static VideoPlayerViewModel newInstance(MediaRepository repository) {
    return new VideoPlayerViewModel(repository);
  }
}
