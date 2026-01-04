package com.openflix.player;

import android.content.Context;
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
public final class LiveTVPlayer_Factory implements Factory<LiveTVPlayer> {
  private final Provider<Context> contextProvider;

  public LiveTVPlayer_Factory(Provider<Context> contextProvider) {
    this.contextProvider = contextProvider;
  }

  @Override
  public LiveTVPlayer get() {
    return newInstance(contextProvider.get());
  }

  public static LiveTVPlayer_Factory create(Provider<Context> contextProvider) {
    return new LiveTVPlayer_Factory(contextProvider);
  }

  public static LiveTVPlayer newInstance(Context context) {
    return new LiveTVPlayer(context);
  }
}
