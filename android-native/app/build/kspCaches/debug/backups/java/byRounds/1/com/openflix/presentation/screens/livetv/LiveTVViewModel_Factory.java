package com.openflix.presentation.screens.livetv;

import com.openflix.data.repository.LiveTVRepository;
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
public final class LiveTVViewModel_Factory implements Factory<LiveTVViewModel> {
  private final Provider<LiveTVRepository> liveTVRepositoryProvider;

  public LiveTVViewModel_Factory(Provider<LiveTVRepository> liveTVRepositoryProvider) {
    this.liveTVRepositoryProvider = liveTVRepositoryProvider;
  }

  @Override
  public LiveTVViewModel get() {
    return newInstance(liveTVRepositoryProvider.get());
  }

  public static LiveTVViewModel_Factory create(
      Provider<LiveTVRepository> liveTVRepositoryProvider) {
    return new LiveTVViewModel_Factory(liveTVRepositoryProvider);
  }

  public static LiveTVViewModel newInstance(LiveTVRepository liveTVRepository) {
    return new LiveTVViewModel(liveTVRepository);
  }
}
