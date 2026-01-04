package com.openflix.data.discovery;

import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;

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
public final class ServerDiscoveryService_Factory implements Factory<ServerDiscoveryService> {
  @Override
  public ServerDiscoveryService get() {
    return newInstance();
  }

  public static ServerDiscoveryService_Factory create() {
    return InstanceHolder.INSTANCE;
  }

  public static ServerDiscoveryService newInstance() {
    return new ServerDiscoveryService();
  }

  private static final class InstanceHolder {
    private static final ServerDiscoveryService_Factory INSTANCE = new ServerDiscoveryService_Factory();
  }
}
