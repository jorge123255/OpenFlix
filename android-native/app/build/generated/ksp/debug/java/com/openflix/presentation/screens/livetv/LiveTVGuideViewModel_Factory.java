package com.openflix.presentation.screens.livetv;

import com.openflix.data.local.LastWatchedService;
import com.openflix.data.repository.DVRRepository;
import com.openflix.data.repository.LiveTVRepository;
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
public final class LiveTVGuideViewModel_Factory implements Factory<LiveTVGuideViewModel> {
  private final Provider<LiveTVRepository> repositoryProvider;

  private final Provider<DVRRepository> dvrRepositoryProvider;

  private final Provider<LastWatchedService> lastWatchedServiceProvider;

  public LiveTVGuideViewModel_Factory(Provider<LiveTVRepository> repositoryProvider,
      Provider<DVRRepository> dvrRepositoryProvider,
      Provider<LastWatchedService> lastWatchedServiceProvider) {
    this.repositoryProvider = repositoryProvider;
    this.dvrRepositoryProvider = dvrRepositoryProvider;
    this.lastWatchedServiceProvider = lastWatchedServiceProvider;
  }

  @Override
  public LiveTVGuideViewModel get() {
    return newInstance(repositoryProvider.get(), dvrRepositoryProvider.get(), lastWatchedServiceProvider.get());
  }

  public static LiveTVGuideViewModel_Factory create(Provider<LiveTVRepository> repositoryProvider,
      Provider<DVRRepository> dvrRepositoryProvider,
      Provider<LastWatchedService> lastWatchedServiceProvider) {
    return new LiveTVGuideViewModel_Factory(repositoryProvider, dvrRepositoryProvider, lastWatchedServiceProvider);
  }

  public static LiveTVGuideViewModel newInstance(LiveTVRepository repository,
      DVRRepository dvrRepository, LastWatchedService lastWatchedService) {
    return new LiveTVGuideViewModel(repository, dvrRepository, lastWatchedService);
  }
}
