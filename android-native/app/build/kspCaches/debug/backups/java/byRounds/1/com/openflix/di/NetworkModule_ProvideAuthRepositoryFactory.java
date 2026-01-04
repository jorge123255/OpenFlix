package com.openflix.di;

import com.openflix.data.local.PreferencesManager;
import com.openflix.data.remote.api.OpenFlixApi;
import com.openflix.data.repository.AuthRepository;
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
public final class NetworkModule_ProvideAuthRepositoryFactory implements Factory<AuthRepository> {
  private final Provider<OpenFlixApi> apiProvider;

  private final Provider<PreferencesManager> preferencesManagerProvider;

  public NetworkModule_ProvideAuthRepositoryFactory(Provider<OpenFlixApi> apiProvider,
      Provider<PreferencesManager> preferencesManagerProvider) {
    this.apiProvider = apiProvider;
    this.preferencesManagerProvider = preferencesManagerProvider;
  }

  @Override
  public AuthRepository get() {
    return provideAuthRepository(apiProvider.get(), preferencesManagerProvider.get());
  }

  public static NetworkModule_ProvideAuthRepositoryFactory create(Provider<OpenFlixApi> apiProvider,
      Provider<PreferencesManager> preferencesManagerProvider) {
    return new NetworkModule_ProvideAuthRepositoryFactory(apiProvider, preferencesManagerProvider);
  }

  public static AuthRepository provideAuthRepository(OpenFlixApi api,
      PreferencesManager preferencesManager) {
    return Preconditions.checkNotNullFromProvides(NetworkModule.INSTANCE.provideAuthRepository(api, preferencesManager));
  }
}
