package com.openflix.presentation.screens.livetv;

import com.openflix.data.local.PreferencesManager;
import com.openflix.data.repository.LiveTVRepository;
import com.openflix.player.MpvPlayer;
import com.openflix.player.PlayerController;
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

  private final Provider<PlayerController> playerControllerProvider;

  private final Provider<MpvPlayer> mpvPlayerProvider;

  private final Provider<PreferencesManager> preferencesManagerProvider;

  public LiveTVPlayerViewModel_Factory(Provider<LiveTVRepository> repositoryProvider,
      Provider<PlayerController> playerControllerProvider, Provider<MpvPlayer> mpvPlayerProvider,
      Provider<PreferencesManager> preferencesManagerProvider) {
    this.repositoryProvider = repositoryProvider;
    this.playerControllerProvider = playerControllerProvider;
    this.mpvPlayerProvider = mpvPlayerProvider;
    this.preferencesManagerProvider = preferencesManagerProvider;
  }

  @Override
  public LiveTVPlayerViewModel get() {
    return newInstance(repositoryProvider.get(), playerControllerProvider.get(), mpvPlayerProvider.get(), preferencesManagerProvider.get());
  }

  public static LiveTVPlayerViewModel_Factory create(Provider<LiveTVRepository> repositoryProvider,
      Provider<PlayerController> playerControllerProvider, Provider<MpvPlayer> mpvPlayerProvider,
      Provider<PreferencesManager> preferencesManagerProvider) {
    return new LiveTVPlayerViewModel_Factory(repositoryProvider, playerControllerProvider, mpvPlayerProvider, preferencesManagerProvider);
  }

  public static LiveTVPlayerViewModel newInstance(LiveTVRepository repository,
      PlayerController playerController, MpvPlayer mpvPlayer,
      PreferencesManager preferencesManager) {
    return new LiveTVPlayerViewModel(repository, playerController, mpvPlayer, preferencesManager);
  }
}
