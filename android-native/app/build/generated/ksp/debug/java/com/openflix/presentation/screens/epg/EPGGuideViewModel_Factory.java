package com.openflix.presentation.screens.epg;

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
public final class EPGGuideViewModel_Factory implements Factory<EPGGuideViewModel> {
  private final Provider<LiveTVRepository> liveTVRepositoryProvider;

  public EPGGuideViewModel_Factory(Provider<LiveTVRepository> liveTVRepositoryProvider) {
    this.liveTVRepositoryProvider = liveTVRepositoryProvider;
  }

  @Override
  public EPGGuideViewModel get() {
    return newInstance(liveTVRepositoryProvider.get());
  }

  public static EPGGuideViewModel_Factory create(
      Provider<LiveTVRepository> liveTVRepositoryProvider) {
    return new EPGGuideViewModel_Factory(liveTVRepositoryProvider);
  }

  public static EPGGuideViewModel newInstance(LiveTVRepository liveTVRepository) {
    return new EPGGuideViewModel(liveTVRepository);
  }
}
