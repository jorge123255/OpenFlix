package com.openflix.di;

import android.content.Context;
import com.openflix.data.repository.SettingsRepository;
import com.openflix.player.MpvPlayer;
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
public final class PlayerModule_ProvideMpvPlayerFactory implements Factory<MpvPlayer> {
  private final Provider<Context> contextProvider;

  private final Provider<SettingsRepository> settingsRepositoryProvider;

  public PlayerModule_ProvideMpvPlayerFactory(Provider<Context> contextProvider,
      Provider<SettingsRepository> settingsRepositoryProvider) {
    this.contextProvider = contextProvider;
    this.settingsRepositoryProvider = settingsRepositoryProvider;
  }

  @Override
  public MpvPlayer get() {
    return provideMpvPlayer(contextProvider.get(), settingsRepositoryProvider.get());
  }

  public static PlayerModule_ProvideMpvPlayerFactory create(Provider<Context> contextProvider,
      Provider<SettingsRepository> settingsRepositoryProvider) {
    return new PlayerModule_ProvideMpvPlayerFactory(contextProvider, settingsRepositoryProvider);
  }

  public static MpvPlayer provideMpvPlayer(Context context, SettingsRepository settingsRepository) {
    return Preconditions.checkNotNullFromProvides(PlayerModule.INSTANCE.provideMpvPlayer(context, settingsRepository));
  }
}
