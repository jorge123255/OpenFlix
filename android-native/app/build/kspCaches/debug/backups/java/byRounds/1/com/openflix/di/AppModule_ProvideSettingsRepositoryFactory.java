package com.openflix.di;

import com.openflix.data.local.PreferencesManager;
import com.openflix.data.repository.SettingsRepository;
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
public final class AppModule_ProvideSettingsRepositoryFactory implements Factory<SettingsRepository> {
  private final Provider<PreferencesManager> preferencesManagerProvider;

  public AppModule_ProvideSettingsRepositoryFactory(
      Provider<PreferencesManager> preferencesManagerProvider) {
    this.preferencesManagerProvider = preferencesManagerProvider;
  }

  @Override
  public SettingsRepository get() {
    return provideSettingsRepository(preferencesManagerProvider.get());
  }

  public static AppModule_ProvideSettingsRepositoryFactory create(
      Provider<PreferencesManager> preferencesManagerProvider) {
    return new AppModule_ProvideSettingsRepositoryFactory(preferencesManagerProvider);
  }

  public static SettingsRepository provideSettingsRepository(
      PreferencesManager preferencesManager) {
    return Preconditions.checkNotNullFromProvides(AppModule.INSTANCE.provideSettingsRepository(preferencesManager));
  }
}
