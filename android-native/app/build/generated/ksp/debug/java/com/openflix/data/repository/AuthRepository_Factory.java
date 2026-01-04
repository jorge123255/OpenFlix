package com.openflix.data.repository;

import com.openflix.data.local.PreferencesManager;
import com.openflix.data.remote.api.OpenFlixApi;
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
public final class AuthRepository_Factory implements Factory<AuthRepository> {
  private final Provider<OpenFlixApi> apiProvider;

  private final Provider<PreferencesManager> preferencesManagerProvider;

  public AuthRepository_Factory(Provider<OpenFlixApi> apiProvider,
      Provider<PreferencesManager> preferencesManagerProvider) {
    this.apiProvider = apiProvider;
    this.preferencesManagerProvider = preferencesManagerProvider;
  }

  @Override
  public AuthRepository get() {
    return newInstance(apiProvider.get(), preferencesManagerProvider.get());
  }

  public static AuthRepository_Factory create(Provider<OpenFlixApi> apiProvider,
      Provider<PreferencesManager> preferencesManagerProvider) {
    return new AuthRepository_Factory(apiProvider, preferencesManagerProvider);
  }

  public static AuthRepository newInstance(OpenFlixApi api, PreferencesManager preferencesManager) {
    return new AuthRepository(api, preferencesManager);
  }
}
