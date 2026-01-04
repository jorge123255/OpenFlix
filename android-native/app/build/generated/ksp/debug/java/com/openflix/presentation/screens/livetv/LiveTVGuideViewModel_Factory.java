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
public final class LiveTVGuideViewModel_Factory implements Factory<LiveTVGuideViewModel> {
  private final Provider<LiveTVRepository> repositoryProvider;

  public LiveTVGuideViewModel_Factory(Provider<LiveTVRepository> repositoryProvider) {
    this.repositoryProvider = repositoryProvider;
  }

  @Override
  public LiveTVGuideViewModel get() {
    return newInstance(repositoryProvider.get());
  }

  public static LiveTVGuideViewModel_Factory create(Provider<LiveTVRepository> repositoryProvider) {
    return new LiveTVGuideViewModel_Factory(repositoryProvider);
  }

  public static LiveTVGuideViewModel newInstance(LiveTVRepository repository) {
    return new LiveTVGuideViewModel(repository);
  }
}
