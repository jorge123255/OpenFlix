package com.openflix.data.local;

import androidx.datastore.core.DataStore;
import androidx.datastore.preferences.core.Preferences;
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
public final class PreferencesManager_Factory implements Factory<PreferencesManager> {
  private final Provider<DataStore<Preferences>> dataStoreProvider;

  public PreferencesManager_Factory(Provider<DataStore<Preferences>> dataStoreProvider) {
    this.dataStoreProvider = dataStoreProvider;
  }

  @Override
  public PreferencesManager get() {
    return newInstance(dataStoreProvider.get());
  }

  public static PreferencesManager_Factory create(
      Provider<DataStore<Preferences>> dataStoreProvider) {
    return new PreferencesManager_Factory(dataStoreProvider);
  }

  public static PreferencesManager newInstance(DataStore<Preferences> dataStore) {
    return new PreferencesManager(dataStore);
  }
}
