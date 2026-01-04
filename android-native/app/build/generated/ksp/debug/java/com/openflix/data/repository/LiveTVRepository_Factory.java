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
public final class LiveTVRepository_Factory implements Factory<LiveTVRepository> {
  private final Provider<OpenFlixApi> apiProvider;

  private final Provider<PreferencesManager> preferencesManagerProvider;

  public LiveTVRepository_Factory(Provider<OpenFlixApi> apiProvider,
      Provider<PreferencesManager> preferencesManagerProvider) {
    this.apiProvider = apiProvider;
    this.preferencesManagerProvider = preferencesManagerProvider;
  }

  @Override
  public LiveTVRepository get() {
    return newInstance(apiProvider.get(), preferencesManagerProvider.get());
  }

  public static LiveTVRepository_Factory create(Provider<OpenFlixApi> apiProvider,
      Provider<PreferencesManager> preferencesManagerProvider) {
    return new LiveTVRepository_Factory(apiProvider, preferencesManagerProvider);
  }

  public static LiveTVRepository newInstance(OpenFlixApi api,
      PreferencesManager preferencesManager) {
    return new LiveTVRepository(api, preferencesManager);
  }
}
