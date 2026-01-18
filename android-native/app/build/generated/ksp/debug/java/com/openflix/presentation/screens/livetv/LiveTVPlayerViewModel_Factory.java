package com.openflix.presentation.screens.livetv;

import com.openflix.data.local.LastWatchedService;
import com.openflix.data.local.PreferencesManager;
import com.openflix.data.local.WatchStatsService;
import com.openflix.data.repository.DVRRepository;
import com.openflix.data.repository.LiveTVRepository;
import com.openflix.player.InstantSwitchManager;
import com.openflix.player.LiveTVPlayer;
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
public final class LiveTVPlayerViewModel_Factory implements Factory<LiveTVPlayerViewModel> {
  private final Provider<LiveTVRepository> repositoryProvider;

  private final Provider<DVRRepository> dvrRepositoryProvider;

  private final Provider<LiveTVPlayer> liveTVPlayerProvider;

  private final Provider<InstantSwitchManager> instantSwitchManagerProvider;

  private final Provider<PreferencesManager> preferencesManagerProvider;

  private final Provider<LastWatchedService> lastWatchedServiceProvider;

  private final Provider<WatchStatsService> watchStatsServiceProvider;

  public LiveTVPlayerViewModel_Factory(Provider<LiveTVRepository> repositoryProvider,
      Provider<DVRRepository> dvrRepositoryProvider, Provider<LiveTVPlayer> liveTVPlayerProvider,
      Provider<InstantSwitchManager> instantSwitchManagerProvider,
      Provider<PreferencesManager> preferencesManagerProvider,
      Provider<LastWatchedService> lastWatchedServiceProvider,
      Provider<WatchStatsService> watchStatsServiceProvider) {
    this.repositoryProvider = repositoryProvider;
    this.dvrRepositoryProvider = dvrRepositoryProvider;
    this.liveTVPlayerProvider = liveTVPlayerProvider;
    this.instantSwitchManagerProvider = instantSwitchManagerProvider;
    this.preferencesManagerProvider = preferencesManagerProvider;
    this.lastWatchedServiceProvider = lastWatchedServiceProvider;
    this.watchStatsServiceProvider = watchStatsServiceProvider;
  }

  @Override
  public LiveTVPlayerViewModel get() {
    return newInstance(repositoryProvider.get(), dvrRepositoryProvider.get(), liveTVPlayerProvider.get(), instantSwitchManagerProvider.get(), preferencesManagerProvider.get(), lastWatchedServiceProvider.get(), watchStatsServiceProvider.get());
  }

  public static LiveTVPlayerViewModel_Factory create(Provider<LiveTVRepository> repositoryProvider,
      Provider<DVRRepository> dvrRepositoryProvider, Provider<LiveTVPlayer> liveTVPlayerProvider,
      Provider<InstantSwitchManager> instantSwitchManagerProvider,
      Provider<PreferencesManager> preferencesManagerProvider,
      Provider<LastWatchedService> lastWatchedServiceProvider,
      Provider<WatchStatsService> watchStatsServiceProvider) {
    return new LiveTVPlayerViewModel_Factory(repositoryProvider, dvrRepositoryProvider, liveTVPlayerProvider, instantSwitchManagerProvider, preferencesManagerProvider, lastWatchedServiceProvider, watchStatsServiceProvider);
  }

  public static LiveTVPlayerViewModel newInstance(LiveTVRepository repository,
      DVRRepository dvrRepository, LiveTVPlayer liveTVPlayer,
      InstantSwitchManager instantSwitchManager, PreferencesManager preferencesManager,
      LastWatchedService lastWatchedService, WatchStatsService watchStatsService) {
    return new LiveTVPlayerViewModel(repository, dvrRepository, liveTVPlayer, instantSwitchManager, preferencesManager, lastWatchedService, watchStatsService);
  }
}
