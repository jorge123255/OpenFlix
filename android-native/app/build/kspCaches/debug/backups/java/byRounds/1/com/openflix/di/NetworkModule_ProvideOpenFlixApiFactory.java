package com.openflix.di;

import com.openflix.data.remote.api.OpenFlixApi;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.Preconditions;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;
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
public final class NetworkModule_ProvideOpenFlixApiFactory implements Factory<OpenFlixApi> {
  private final Provider<Retrofit> retrofitProvider;

  public NetworkModule_ProvideOpenFlixApiFactory(Provider<Retrofit> retrofitProvider) {
    this.retrofitProvider = retrofitProvider;
  }

  @Override
  public OpenFlixApi get() {
    return provideOpenFlixApi(retrofitProvider.get());
  }

  public static NetworkModule_ProvideOpenFlixApiFactory create(
      Provider<Retrofit> retrofitProvider) {
    return new NetworkModule_ProvideOpenFlixApiFactory(retrofitProvider);
  }

  public static OpenFlixApi provideOpenFlixApi(Retrofit retrofit) {
    return Preconditions.checkNotNullFromProvides(NetworkModule.INSTANCE.provideOpenFlixApi(retrofit));
  }
}
