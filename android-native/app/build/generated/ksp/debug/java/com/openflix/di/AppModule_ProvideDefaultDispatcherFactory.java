package com.openflix.di;

import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.Preconditions;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import kotlinx.coroutines.CoroutineDispatcher;

@ScopeMetadata
@QualifierMetadata("com.openflix.di.DefaultDispatcher")
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
public final class AppModule_ProvideDefaultDispatcherFactory implements Factory<CoroutineDispatcher> {
  @Override
  public CoroutineDispatcher get() {
    return provideDefaultDispatcher();
  }

  public static AppModule_ProvideDefaultDispatcherFactory create() {
    return InstanceHolder.INSTANCE;
  }

  public static CoroutineDispatcher provideDefaultDispatcher() {
    return Preconditions.checkNotNullFromProvides(AppModule.INSTANCE.provideDefaultDispatcher());
  }

  private static final class InstanceHolder {
    private static final AppModule_ProvideDefaultDispatcherFactory INSTANCE = new AppModule_ProvideDefaultDispatcherFactory();
  }
}
