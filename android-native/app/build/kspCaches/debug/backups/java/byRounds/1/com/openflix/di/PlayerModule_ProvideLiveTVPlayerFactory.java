package com.openflix.di;

import android.content.Context;
import com.openflix.player.LiveTVPlayer;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.Preconditions;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;

@ScopeMetadata("javax.inject.Singleton")
@QualifierMetadata("dagger.hilt.android.qualifiers.ApplicationContext")
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
public final class PlayerModule_ProvideLiveTVPlayerFactory implements Factory<LiveTVPlayer> {
  private final Provider<Context> contextProvider;

  public PlayerModule_ProvideLiveTVPlayerFactory(Provider<Context> contextProvider) {
    this.contextProvider = contextProvider;
  }

  @Override
  public LiveTVPlayer get() {
    return provideLiveTVPlayer(contextProvider.get());
  }

  public static PlayerModule_ProvideLiveTVPlayerFactory create(Provider<Context> contextProvider) {
    return new PlayerModule_ProvideLiveTVPlayerFactory(contextProvider);
  }

  public static LiveTVPlayer provideLiveTVPlayer(Context context) {
    return Preconditions.checkNotNullFromProvides(PlayerModule.INSTANCE.provideLiveTVPlayer(context));
  }
}
