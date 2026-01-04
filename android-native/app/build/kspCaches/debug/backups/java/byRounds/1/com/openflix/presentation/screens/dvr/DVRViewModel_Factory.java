package com.openflix.presentation.screens.dvr;

import com.openflix.data.repository.DVRRepository;
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
public final class DVRViewModel_Factory implements Factory<DVRViewModel> {
  private final Provider<DVRRepository> dvrRepositoryProvider;

  public DVRViewModel_Factory(Provider<DVRRepository> dvrRepositoryProvider) {
    this.dvrRepositoryProvider = dvrRepositoryProvider;
  }

  @Override
  public DVRViewModel get() {
    return newInstance(dvrRepositoryProvider.get());
  }

  public static DVRViewModel_Factory create(Provider<DVRRepository> dvrRepositoryProvider) {
    return new DVRViewModel_Factory(dvrRepositoryProvider);
  }

  public static DVRViewModel newInstance(DVRRepository dvrRepository) {
    return new DVRViewModel(dvrRepository);
  }
}
