package com.openflix.di;

import com.openflix.data.local.PreferencesManager;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.Preconditions;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;
import okhttp3.OkHttpClient;
import retrofit2.Retrofit;

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
public final class NetworkModule_ProvideRetrofitFactory implements Factory<Retrofit> {
  private final Provider<OkHttpClient> okHttpClientProvider;

  private final Provider<PreferencesManager> preferencesManagerProvider;

  public NetworkModule_ProvideRetrofitFactory(Provider<OkHttpClient> okHttpClientProvider,
      Provider<PreferencesManager> preferencesManagerProvider) {
    this.okHttpClientProvider = okHttpClientProvider;
    this.preferencesManagerProvider = preferencesManagerProvider;
  }

  @Override
  public Retrofit get() {
    return provideRetrofit(okHttpClientProvider.get(), preferencesManagerProvider.get());
  }

  public static NetworkModule_ProvideRetrofitFactory create(
      Provider<OkHttpClient> okHttpClientProvider,
      Provider<PreferencesManager> preferencesManagerProvider) {
    return new NetworkModule_ProvideRetrofitFactory(okHttpClientProvider, preferencesManagerProvider);
  }

  public static Retrofit provideRetrofit(OkHttpClient okHttpClient,
      PreferencesManager preferencesManager) {
    return Preconditions.checkNotNullFromProvides(NetworkModule.INSTANCE.provideRetrofit(okHttpClient, preferencesManager));
  }
}
