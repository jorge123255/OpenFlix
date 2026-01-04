package com.openflix.di;

import com.openflix.data.local.PreferencesManager;
import com.openflix.data.remote.api.OpenFlixApi;
import com.openflix.data.repository.LiveTVRepository;
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
public final class NetworkModule_ProvideLiveTVRepositoryFactory implements Factory<LiveTVRepository> {
  private final Provider<OpenFlixApi> apiProvider;

  private final Provider<PreferencesManager> preferencesManagerProvider;

  public NetworkModule_ProvideLiveTVRepositoryFactory(Provider<OpenFlixApi> apiProvider,
      Provider<PreferencesManager> preferencesManagerProvider) {
    this.apiProvider = apiProvider;
    this.preferencesManagerProvider = preferencesManagerProvider;
  }

  @Override
  public LiveTVRepository get() {
    return provideLiveTVRepository(apiProvider.get(), preferencesManagerProvider.get());
  }

  public static NetworkModule_ProvideLiveTVRepositoryFactory create(
      Provider<OpenFlixApi> apiProvider, Provider<PreferencesManager> preferencesManagerProvider) {
    return new NetworkModule_ProvideLiveTVRepositoryFactory(apiProvider, preferencesManagerProvider);
  }

  public static LiveTVRepository provideLiveTVRepository(OpenFlixApi api,
      PreferencesManager preferencesManager) {
    return Preconditions.checkNotNullFromProvides(NetworkModule.INSTANCE.provideLiveTVRepository(api, preferencesManager));
  }
}
