package com.openflix.data.repository;

import com.openflix.data.local.PreferencesManager;
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
public final class SettingsRepository_Factory implements Factory<SettingsRepository> {
  private final Provider<PreferencesManager> preferencesManagerProvider;

  public SettingsRepository_Factory(Provider<PreferencesManager> preferencesManagerProvider) {
    this.preferencesManagerProvider = preferencesManagerProvider;
  }

  @Override
  public SettingsRepository get() {
    return newInstance(preferencesManagerProvider.get());
  }

  public static SettingsRepository_Factory create(
      Provider<PreferencesManager> preferencesManagerProvider) {
    return new SettingsRepository_Factory(preferencesManagerProvider);
  }

  public static SettingsRepository newInstance(PreferencesManager preferencesManager) {
    return new SettingsRepository(preferencesManager);
  }
}
