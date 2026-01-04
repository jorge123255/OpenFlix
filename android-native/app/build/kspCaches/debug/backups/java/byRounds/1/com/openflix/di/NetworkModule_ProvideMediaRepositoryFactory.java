package com.openflix.di;

import com.openflix.data.local.PreferencesManager;
import com.openflix.data.remote.api.OpenFlixApi;
import com.openflix.data.repository.MediaRepository;
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
public final class NetworkModule_ProvideMediaRepositoryFactory implements Factory<MediaRepository> {
  private final Provider<OpenFlixApi> apiProvider;

  private final Provider<PreferencesManager> preferencesManagerProvider;

  public NetworkModule_ProvideMediaRepositoryFactory(Provider<OpenFlixApi> apiProvider,
      Provider<PreferencesManager> preferencesManagerProvider) {
    this.apiProvider = apiProvider;
    this.preferencesManagerProvider = preferencesManagerProvider;
  }

  @Override
  public MediaRepository get() {
    return provideMediaRepository(apiProvider.get(), preferencesManagerProvider.get());
  }

  public static NetworkModule_ProvideMediaRepositoryFactory create(
      Provider<OpenFlixApi> apiProvider, Provider<PreferencesManager> preferencesManagerProvider) {
    return new NetworkModule_ProvideMediaRepositoryFactory(apiProvider, preferencesManagerProvider);
  }

  public static MediaRepository provideMediaRepository(OpenFlixApi api,
      PreferencesManager preferencesManager) {
    return Preconditions.checkNotNullFromProvides(NetworkModule.INSTANCE.provideMediaRepository(api, preferencesManager));
  }
}
