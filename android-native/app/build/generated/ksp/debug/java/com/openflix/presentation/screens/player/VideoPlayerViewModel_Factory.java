package com.openflix.presentation.screens.player;

import com.openflix.data.local.WatchStatsService;
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

  private final Provider<WatchStatsService> watchStatsServiceProvider;

  public VideoPlayerViewModel_Factory(Provider<MediaRepository> repositoryProvider,
      Provider<WatchStatsService> watchStatsServiceProvider) {
    this.repositoryProvider = repositoryProvider;
    this.watchStatsServiceProvider = watchStatsServiceProvider;
  }

  @Override
  public VideoPlayerViewModel get() {
    return newInstance(repositoryProvider.get(), watchStatsServiceProvider.get());
  }

  public static VideoPlayerViewModel_Factory create(Provider<MediaRepository> repositoryProvider,
      Provider<WatchStatsService> watchStatsServiceProvider) {
    return new VideoPlayerViewModel_Factory(repositoryProvider, watchStatsServiceProvider);
  }

  public static VideoPlayerViewModel newInstance(MediaRepository repository,
      WatchStatsService watchStatsService) {
    return new VideoPlayerViewModel(repository, watchStatsService);
  }
}
