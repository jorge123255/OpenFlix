package com.openflix.player;

import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
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
public final class PlayerController_Factory implements Factory<PlayerController> {
  private final Provider<MpvPlayer> mpvPlayerProvider;

  public PlayerController_Factory(Provider<MpvPlayer> mpvPlayerProvider) {
    this.mpvPlayerProvider = mpvPlayerProvider;
  }

  @Override
  public PlayerController get() {
    return newInstance(mpvPlayerProvider.get());
  }

  public static PlayerController_Factory create(Provider<MpvPlayer> mpvPlayerProvider) {
    return new PlayerController_Factory(mpvPlayerProvider);
  }

  public static PlayerController newInstance(MpvPlayer mpvPlayer) {
    return new PlayerController(mpvPlayer);
  }
}
