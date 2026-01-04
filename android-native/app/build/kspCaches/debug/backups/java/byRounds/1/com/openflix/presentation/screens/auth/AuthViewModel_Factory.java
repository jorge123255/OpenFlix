package com.openflix.presentation.screens.auth;

import com.openflix.data.discovery.ServerDiscoveryService;
import com.openflix.data.repository.AuthRepository;
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
public final class AuthViewModel_Factory implements Factory<AuthViewModel> {
  private final Provider<AuthRepository> authRepositoryProvider;

  private final Provider<ServerDiscoveryService> discoveryServiceProvider;

  public AuthViewModel_Factory(Provider<AuthRepository> authRepositoryProvider,
      Provider<ServerDiscoveryService> discoveryServiceProvider) {
    this.authRepositoryProvider = authRepositoryProvider;
    this.discoveryServiceProvider = discoveryServiceProvider;
  }

  @Override
  public AuthViewModel get() {
    return newInstance(authRepositoryProvider.get(), discoveryServiceProvider.get());
  }

  public static AuthViewModel_Factory create(Provider<AuthRepository> authRepositoryProvider,
      Provider<ServerDiscoveryService> discoveryServiceProvider) {
    return new AuthViewModel_Factory(authRepositoryProvider, discoveryServiceProvider);
  }

  public static AuthViewModel newInstance(AuthRepository authRepository,
      ServerDiscoveryService discoveryService) {
    return new AuthViewModel(authRepository, discoveryService);
  }
}
