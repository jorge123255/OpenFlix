package com.openflix.presentation.screens.livetv;

import com.openflix.data.repository.LiveTVRepository;
import com.openflix.player.MpvPlayer;
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
public final class ArchivePlayerViewModel_Factory implements Factory<ArchivePlayerViewModel> {
  private final Provider<LiveTVRepository> liveTVRepositoryProvider;

  private final Provider<MpvPlayer> mpvPlayerProvider;

  public ArchivePlayerViewModel_Factory(Provider<LiveTVRepository> liveTVRepositoryProvider,
      Provider<MpvPlayer> mpvPlayerProvider) {
    this.liveTVRepositoryProvider = liveTVRepositoryProvider;
    this.mpvPlayerProvider = mpvPlayerProvider;
  }

  @Override
  public ArchivePlayerViewModel get() {
    return newInstance(liveTVRepositoryProvider.get(), mpvPlayerProvider.get());
  }

  public static ArchivePlayerViewModel_Factory create(
      Provider<LiveTVRepository> liveTVRepositoryProvider, Provider<MpvPlayer> mpvPlayerProvider) {
    return new ArchivePlayerViewModel_Factory(liveTVRepositoryProvider, mpvPlayerProvider);
  }

  public static ArchivePlayerViewModel newInstance(LiveTVRepository liveTVRepository,
      MpvPlayer mpvPlayer) {
    return new ArchivePlayerViewModel(liveTVRepository, mpvPlayer);
  }
}
