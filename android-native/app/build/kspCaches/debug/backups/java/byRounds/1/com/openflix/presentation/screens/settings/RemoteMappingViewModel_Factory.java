package com.openflix.presentation.screens.settings;

import com.openflix.data.local.PreferencesManager;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;

@ScopeMetadata
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
public final class RemoteMappingViewModel_Factory implements Factory<RemoteMappingViewModel> {
  private final Provider<PreferencesManager> preferencesManagerProvider;

  public RemoteMappingViewModel_Factory(Provider<PreferencesManager> preferencesManagerProvider) {
    this.preferencesManagerProvider = preferencesManagerProvider;
  }

  @Override
  public RemoteMappingViewModel get() {
    return newInstance(preferencesManagerProvider.get());
  }

  public static RemoteMappingViewModel_Factory create(
      Provider<PreferencesManager> preferencesManagerProvider) {
    return new RemoteMappingViewModel_Factory(preferencesManagerProvider);
  }

  public static RemoteMappingViewModel newInstance(PreferencesManager preferencesManager) {
    return new RemoteMappingViewModel(preferencesManager);
  }
}
