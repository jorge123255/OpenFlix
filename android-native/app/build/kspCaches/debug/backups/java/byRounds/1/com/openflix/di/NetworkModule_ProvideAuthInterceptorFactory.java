package com.openflix.di;

import com.openflix.data.local.PreferencesManager;
import com.openflix.data.remote.api.AuthInterceptor;
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
public final class NetworkModule_ProvideAuthInterceptorFactory implements Factory<AuthInterceptor> {
  private final Provider<PreferencesManager> preferencesManagerProvider;

  public NetworkModule_ProvideAuthInterceptorFactory(
      Provider<PreferencesManager> preferencesManagerProvider) {
    this.preferencesManagerProvider = preferencesManagerProvider;
  }

  @Override
  public AuthInterceptor get() {
    return provideAuthInterceptor(preferencesManagerProvider.get());
  }

  public static NetworkModule_ProvideAuthInterceptorFactory create(
      Provider<PreferencesManager> preferencesManagerProvider) {
    return new NetworkModule_ProvideAuthInterceptorFactory(preferencesManagerProvider);
  }

  public static AuthInterceptor provideAuthInterceptor(PreferencesManager preferencesManager) {
    return Preconditions.checkNotNullFromProvides(NetworkModule.INSTANCE.provideAuthInterceptor(preferencesManager));
  }
}
