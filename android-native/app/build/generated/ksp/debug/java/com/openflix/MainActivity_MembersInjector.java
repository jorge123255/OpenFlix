package com.openflix;

import com.openflix.data.local.LastWatchedService;
import com.openflix.player.LiveTVPlayer;
import com.openflix.player.MpvPlayer;
import dagger.MembersInjector;
import dagger.internal.DaggerGenerated;
import dagger.internal.InjectedFieldSignature;
import dagger.internal.QualifierMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;

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
public final class MainActivity_MembersInjector implements MembersInjector<MainActivity> {
  private final Provider<MpvPlayer> mpvPlayerProvider;

  private final Provider<LiveTVPlayer> liveTVPlayerProvider;

  private final Provider<LastWatchedService> lastWatchedServiceProvider;

  public MainActivity_MembersInjector(Provider<MpvPlayer> mpvPlayerProvider,
      Provider<LiveTVPlayer> liveTVPlayerProvider,
      Provider<LastWatchedService> lastWatchedServiceProvider) {
    this.mpvPlayerProvider = mpvPlayerProvider;
    this.liveTVPlayerProvider = liveTVPlayerProvider;
    this.lastWatchedServiceProvider = lastWatchedServiceProvider;
  }

  public static MembersInjector<MainActivity> create(Provider<MpvPlayer> mpvPlayerProvider,
      Provider<LiveTVPlayer> liveTVPlayerProvider,
      Provider<LastWatchedService> lastWatchedServiceProvider) {
    return new MainActivity_MembersInjector(mpvPlayerProvider, liveTVPlayerProvider, lastWatchedServiceProvider);
  }

  @Override
  public void injectMembers(MainActivity instance) {
    injectMpvPlayer(instance, mpvPlayerProvider.get());
    injectLiveTVPlayer(instance, liveTVPlayerProvider.get());
    injectLastWatchedService(instance, lastWatchedServiceProvider.get());
  }

  @InjectedFieldSignature("com.openflix.MainActivity.mpvPlayer")
  public static void injectMpvPlayer(MainActivity instance, MpvPlayer mpvPlayer) {
    instance.mpvPlayer = mpvPlayer;
  }

  @InjectedFieldSignature("com.openflix.MainActivity.liveTVPlayer")
  public static void injectLiveTVPlayer(MainActivity instance, LiveTVPlayer liveTVPlayer) {
    instance.liveTVPlayer = liveTVPlayer;
  }

  @InjectedFieldSignature("com.openflix.MainActivity.lastWatchedService")
  public static void injectLastWatchedService(MainActivity instance,
      LastWatchedService lastWatchedService) {
    instance.lastWatchedService = lastWatchedService;
  }
}
