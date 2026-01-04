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
public final class ChannelLogoEditorViewModel_Factory implements Factory<ChannelLogoEditorViewModel> {
  private final Provider<LiveTVRepository> liveTVRepositoryProvider;

  public ChannelLogoEditorViewModel_Factory(Provider<LiveTVRepository> liveTVRepositoryProvider) {
    this.liveTVRepositoryProvider = liveTVRepositoryProvider;
  }

  @Override
  public ChannelLogoEditorViewModel get() {
    return newInstance(liveTVRepositoryProvider.get());
  }

  public static ChannelLogoEditorViewModel_Factory create(
      Provider<LiveTVRepository> liveTVRepositoryProvider) {
    return new ChannelLogoEditorViewModel_Factory(liveTVRepositoryProvider);
  }

  public static ChannelLogoEditorViewModel newInstance(LiveTVRepository liveTVRepository) {
    return new ChannelLogoEditorViewModel(liveTVRepository);
  }
}
