package com.openflix;

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

  public MainActivity_MembersInjector(Provider<MpvPlayer> mpvPlayerProvider,
      Provider<LiveTVPlayer> liveTVPlayerProvider) {
    this.mpvPlayerProvider = mpvPlayerProvider;
    this.liveTVPlayerProvider = liveTVPlayerProvider;
  }

  public static MembersInjector<MainActivity> create(Provider<MpvPlayer> mpvPlayerProvider,
      Provider<LiveTVPlayer> liveTVPlayerProvider) {
    return new MainActivity_MembersInjector(mpvPlayerProvider, liveTVPlayerProvider);
  }

  @Override
  public void injectMembers(MainActivity instance) {
    injectMpvPlayer(instance, mpvPlayerProvider.get());
    injectLiveTVPlayer(instance, liveTVPlayerProvider.get());
  }

  @InjectedFieldSignature("com.openflix.MainActivity.mpvPlayer")
  public static void injectMpvPlayer(MainActivity instance, MpvPlayer mpvPlayer) {
    instance.mpvPlayer = mpvPlayer;
  }

  @InjectedFieldSignature("com.openflix.MainActivity.liveTVPlayer")
  public static void injectLiveTVPlayer(MainActivity instance, LiveTVPlayer liveTVPlayer) {
    instance.liveTVPlayer = liveTVPlayer;
  }
}
