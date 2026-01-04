package com.openflix.player;

import android.content.Context;
import com.openflix.data.repository.SettingsRepository;
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
public final class MpvPlayer_Factory implements Factory<MpvPlayer> {
  private final Provider<Context> contextProvider;

  private final Provider<SettingsRepository> settingsRepositoryProvider;

  public MpvPlayer_Factory(Provider<Context> contextProvider,
      Provider<SettingsRepository> settingsRepositoryProvider) {
    this.contextProvider = contextProvider;
    this.settingsRepositoryProvider = settingsRepositoryProvider;
  }

  @Override
  public MpvPlayer get() {
    return newInstance(contextProvider.get(), settingsRepositoryProvider.get());
  }

  public static MpvPlayer_Factory create(Provider<Context> contextProvider,
      Provider<SettingsRepository> settingsRepositoryProvider) {
    return new MpvPlayer_Factory(contextProvider, settingsRepositoryProvider);
  }

  public static MpvPlayer newInstance(Context context, SettingsRepository settingsRepository) {
    return new MpvPlayer(context, settingsRepository);
  }
}
