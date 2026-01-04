package com.openflix.presentation.screens.livetv;

import android.content.Context;
import com.openflix.data.repository.LiveTVRepository;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;

@ScopeMetadata
@QualifierMetadata("dagger.hilt.android.qualifiers.ApplicationContext")
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
public final class MultiviewViewModel_Factory implements Factory<MultiviewViewModel> {
  private final Provider<Context> contextProvider;

  private final Provider<LiveTVRepository> liveTVRepositoryProvider;

  public MultiviewViewModel_Factory(Provider<Context> contextProvider,
      Provider<LiveTVRepository> liveTVRepositoryProvider) {
    this.contextProvider = contextProvider;
    this.liveTVRepositoryProvider = liveTVRepositoryProvider;
  }

  @Override
  public MultiviewViewModel get() {
    return newInstance(contextProvider.get(), liveTVRepositoryProvider.get());
  }

  public static MultiviewViewModel_Factory create(Provider<Context> contextProvider,
      Provider<LiveTVRepository> liveTVRepositoryProvider) {
    return new MultiviewViewModel_Factory(contextProvider, liveTVRepositoryProvider);
  }

  public static MultiviewViewModel newInstance(Context context, LiveTVRepository liveTVRepository) {
    return new MultiviewViewModel(context, liveTVRepository);
  }
}
