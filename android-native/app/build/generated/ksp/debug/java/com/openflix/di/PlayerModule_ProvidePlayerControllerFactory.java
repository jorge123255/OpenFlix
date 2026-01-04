package com.openflix.di;

import com.openflix.player.MpvPlayer;
import com.openflix.player.PlayerController;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.Preconditions;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;

@ScopeMetadata("javax.inject.Singleton")
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
public final class PlayerModule_ProvidePlayerControllerFactory implements Factory<PlayerController> {
  private final Provider<MpvPlayer> mpvPlayerProvider;

  public PlayerModule_ProvidePlayerControllerFactory(Provider<MpvPlayer> mpvPlayerProvider) {
    this.mpvPlayerProvider = mpvPlayerProvider;
  }

  @Override
  public PlayerController get() {
    return providePlayerController(mpvPlayerProvider.get());
  }

  public static PlayerModule_ProvidePlayerControllerFactory create(
      Provider<MpvPlayer> mpvPlayerProvider) {
    return new PlayerModule_ProvidePlayerControllerFactory(mpvPlayerProvider);
  }

  public static PlayerController providePlayerController(MpvPlayer mpvPlayer) {
    return Preconditions.checkNotNullFromProvides(PlayerModule.INSTANCE.providePlayerController(mpvPlayer));
  }
}
