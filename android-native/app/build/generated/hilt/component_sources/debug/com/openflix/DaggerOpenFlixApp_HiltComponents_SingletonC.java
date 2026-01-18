package com.openflix;

import android.app.Activity;
import android.app.Service;
import android.view.View;
import androidx.datastore.core.DataStore;
import androidx.datastore.preferences.core.Preferences;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.SavedStateHandle;
import androidx.lifecycle.ViewModel;
import com.google.common.collect.ImmutableMap;
import com.google.common.collect.ImmutableSet;
import com.openflix.data.discovery.ServerDiscoveryService;
import com.openflix.data.local.LastWatchedService;
import com.openflix.data.local.PreferencesManager;
import com.openflix.data.local.WatchStatsService;
import com.openflix.data.remote.api.AuthInterceptor;
import com.openflix.data.remote.api.OpenFlixApi;
import com.openflix.data.repository.AuthRepository;
import com.openflix.data.repository.DVRRepository;
import com.openflix.data.repository.LiveTVRepository;
import com.openflix.data.repository.MediaRepository;
import com.openflix.data.repository.SettingsRepository;
import com.openflix.di.AppModule_ProvideDataStoreFactory;
import com.openflix.di.AppModule_ProvidePreferencesManagerFactory;
import com.openflix.di.AppModule_ProvideSettingsRepositoryFactory;
import com.openflix.di.NetworkModule_ProvideAuthInterceptorFactory;
import com.openflix.di.NetworkModule_ProvideAuthRepositoryFactory;
import com.openflix.di.NetworkModule_ProvideDVRRepositoryFactory;
import com.openflix.di.NetworkModule_ProvideLiveTVRepositoryFactory;
import com.openflix.di.NetworkModule_ProvideLoggingInterceptorFactory;
import com.openflix.di.NetworkModule_ProvideMediaRepositoryFactory;
import com.openflix.di.NetworkModule_ProvideOkHttpClientFactory;
import com.openflix.di.NetworkModule_ProvideOpenFlixApiFactory;
import com.openflix.di.NetworkModule_ProvideRetrofitFactory;
import com.openflix.di.PlayerModule_ProvideLiveTVPlayerFactory;
import com.openflix.di.PlayerModule_ProvideMpvPlayerFactory;
import com.openflix.player.InstantSwitchManager;
import com.openflix.player.LiveTVPlayer;
import com.openflix.player.MpvPlayer;
import com.openflix.presentation.screens.allmedia.AllMediaViewModel;
import com.openflix.presentation.screens.allmedia.AllMediaViewModel_HiltModules_KeyModule_ProvideFactory;
import com.openflix.presentation.screens.auth.AuthViewModel;
import com.openflix.presentation.screens.auth.AuthViewModel_HiltModules_KeyModule_ProvideFactory;
import com.openflix.presentation.screens.catchup.CatchupViewModel;
import com.openflix.presentation.screens.catchup.CatchupViewModel_HiltModules_KeyModule_ProvideFactory;
import com.openflix.presentation.screens.dvr.DVRPlayerViewModel;
import com.openflix.presentation.screens.dvr.DVRPlayerViewModel_HiltModules_KeyModule_ProvideFactory;
import com.openflix.presentation.screens.dvr.DVRViewModel;
import com.openflix.presentation.screens.dvr.DVRViewModel_HiltModules_KeyModule_ProvideFactory;
import com.openflix.presentation.screens.epg.EPGGuideViewModel;
import com.openflix.presentation.screens.epg.EPGGuideViewModel_HiltModules_KeyModule_ProvideFactory;
import com.openflix.presentation.screens.home.DiscoverViewModel;
import com.openflix.presentation.screens.home.DiscoverViewModel_HiltModules_KeyModule_ProvideFactory;
import com.openflix.presentation.screens.livetv.ArchivePlayerViewModel;
import com.openflix.presentation.screens.livetv.ArchivePlayerViewModel_HiltModules_KeyModule_ProvideFactory;
import com.openflix.presentation.screens.livetv.ChannelLogoEditorViewModel;
import com.openflix.presentation.screens.livetv.ChannelLogoEditorViewModel_HiltModules_KeyModule_ProvideFactory;
import com.openflix.presentation.screens.livetv.ChannelSurfingViewModel;
import com.openflix.presentation.screens.livetv.ChannelSurfingViewModel_HiltModules_KeyModule_ProvideFactory;
import com.openflix.presentation.screens.livetv.LiveTVGuideViewModel;
import com.openflix.presentation.screens.livetv.LiveTVGuideViewModel_HiltModules_KeyModule_ProvideFactory;
import com.openflix.presentation.screens.livetv.LiveTVPlayerViewModel;
import com.openflix.presentation.screens.livetv.LiveTVPlayerViewModel_HiltModules_KeyModule_ProvideFactory;
import com.openflix.presentation.screens.livetv.LiveTVViewModel;
import com.openflix.presentation.screens.livetv.LiveTVViewModel_HiltModules_KeyModule_ProvideFactory;
import com.openflix.presentation.screens.livetv.MultiviewViewModel;
import com.openflix.presentation.screens.livetv.MultiviewViewModel_HiltModules_KeyModule_ProvideFactory;
import com.openflix.presentation.screens.media.MediaDetailViewModel;
import com.openflix.presentation.screens.media.MediaDetailViewModel_HiltModules_KeyModule_ProvideFactory;
import com.openflix.presentation.screens.movies.MoviesViewModel;
import com.openflix.presentation.screens.movies.MoviesViewModel_HiltModules_KeyModule_ProvideFactory;
import com.openflix.presentation.screens.onlater.OnLaterViewModel;
import com.openflix.presentation.screens.onlater.OnLaterViewModel_HiltModules_KeyModule_ProvideFactory;
import com.openflix.presentation.screens.player.VideoPlayerViewModel;
import com.openflix.presentation.screens.player.VideoPlayerViewModel_HiltModules_KeyModule_ProvideFactory;
import com.openflix.presentation.screens.search.SearchViewModel;
import com.openflix.presentation.screens.search.SearchViewModel_HiltModules_KeyModule_ProvideFactory;
import com.openflix.presentation.screens.settings.RemoteMappingViewModel;
import com.openflix.presentation.screens.settings.RemoteMappingViewModel_HiltModules_KeyModule_ProvideFactory;
import com.openflix.presentation.screens.settings.SettingsViewModel;
import com.openflix.presentation.screens.settings.SettingsViewModel_HiltModules_KeyModule_ProvideFactory;
import com.openflix.presentation.screens.teampass.TeamPassViewModel;
import com.openflix.presentation.screens.teampass.TeamPassViewModel_HiltModules_KeyModule_ProvideFactory;
import com.openflix.presentation.screens.tvshows.TVShowsViewModel;
import com.openflix.presentation.screens.tvshows.TVShowsViewModel_HiltModules_KeyModule_ProvideFactory;
import com.openflix.presentation.screens.watchstats.WatchStatsViewModel;
import com.openflix.presentation.screens.watchstats.WatchStatsViewModel_HiltModules_KeyModule_ProvideFactory;
import dagger.hilt.android.ActivityRetainedLifecycle;
import dagger.hilt.android.ViewModelLifecycle;
import dagger.hilt.android.internal.builders.ActivityComponentBuilder;
import dagger.hilt.android.internal.builders.ActivityRetainedComponentBuilder;
import dagger.hilt.android.internal.builders.FragmentComponentBuilder;
import dagger.hilt.android.internal.builders.ServiceComponentBuilder;
import dagger.hilt.android.internal.builders.ViewComponentBuilder;
import dagger.hilt.android.internal.builders.ViewModelComponentBuilder;
import dagger.hilt.android.internal.builders.ViewWithFragmentComponentBuilder;
import dagger.hilt.android.internal.lifecycle.DefaultViewModelFactories;
import dagger.hilt.android.internal.lifecycle.DefaultViewModelFactories_InternalFactoryFactory_Factory;
import dagger.hilt.android.internal.managers.ActivityRetainedComponentManager_LifecycleModule_ProvideActivityRetainedLifecycleFactory;
import dagger.hilt.android.internal.managers.SavedStateHandleHolder;
import dagger.hilt.android.internal.modules.ApplicationContextModule;
import dagger.hilt.android.internal.modules.ApplicationContextModule_ProvideContextFactory;
import dagger.internal.DaggerGenerated;
import dagger.internal.DoubleCheck;
import dagger.internal.Preconditions;
import dagger.internal.Provider;
import java.util.Map;
import java.util.Set;
import javax.annotation.processing.Generated;
import okhttp3.OkHttpClient;
import okhttp3.logging.HttpLoggingInterceptor;
import retrofit2.Retrofit;

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
public final class DaggerOpenFlixApp_HiltComponents_SingletonC {
  private DaggerOpenFlixApp_HiltComponents_SingletonC() {
  }

  public static Builder builder() {
    return new Builder();
  }

  public static final class Builder {
    private ApplicationContextModule applicationContextModule;

    private Builder() {
    }

    public Builder applicationContextModule(ApplicationContextModule applicationContextModule) {
      this.applicationContextModule = Preconditions.checkNotNull(applicationContextModule);
      return this;
    }

    public OpenFlixApp_HiltComponents.SingletonC build() {
      Preconditions.checkBuilderRequirement(applicationContextModule, ApplicationContextModule.class);
      return new SingletonCImpl(applicationContextModule);
    }
  }

  private static final class ActivityRetainedCBuilder implements OpenFlixApp_HiltComponents.ActivityRetainedC.Builder {
    private final SingletonCImpl singletonCImpl;

    private SavedStateHandleHolder savedStateHandleHolder;

    private ActivityRetainedCBuilder(SingletonCImpl singletonCImpl) {
      this.singletonCImpl = singletonCImpl;
    }

    @Override
    public ActivityRetainedCBuilder savedStateHandleHolder(
        SavedStateHandleHolder savedStateHandleHolder) {
      this.savedStateHandleHolder = Preconditions.checkNotNull(savedStateHandleHolder);
      return this;
    }

    @Override
    public OpenFlixApp_HiltComponents.ActivityRetainedC build() {
      Preconditions.checkBuilderRequirement(savedStateHandleHolder, SavedStateHandleHolder.class);
      return new ActivityRetainedCImpl(singletonCImpl, savedStateHandleHolder);
    }
  }

  private static final class ActivityCBuilder implements OpenFlixApp_HiltComponents.ActivityC.Builder {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private Activity activity;

    private ActivityCBuilder(SingletonCImpl singletonCImpl,
        ActivityRetainedCImpl activityRetainedCImpl) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;
    }

    @Override
    public ActivityCBuilder activity(Activity activity) {
      this.activity = Preconditions.checkNotNull(activity);
      return this;
    }

    @Override
    public OpenFlixApp_HiltComponents.ActivityC build() {
      Preconditions.checkBuilderRequirement(activity, Activity.class);
      return new ActivityCImpl(singletonCImpl, activityRetainedCImpl, activity);
    }
  }

  private static final class FragmentCBuilder implements OpenFlixApp_HiltComponents.FragmentC.Builder {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private final ActivityCImpl activityCImpl;

    private Fragment fragment;

    private FragmentCBuilder(SingletonCImpl singletonCImpl,
        ActivityRetainedCImpl activityRetainedCImpl, ActivityCImpl activityCImpl) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;
      this.activityCImpl = activityCImpl;
    }

    @Override
    public FragmentCBuilder fragment(Fragment fragment) {
      this.fragment = Preconditions.checkNotNull(fragment);
      return this;
    }

    @Override
    public OpenFlixApp_HiltComponents.FragmentC build() {
      Preconditions.checkBuilderRequirement(fragment, Fragment.class);
      return new FragmentCImpl(singletonCImpl, activityRetainedCImpl, activityCImpl, fragment);
    }
  }

  private static final class ViewWithFragmentCBuilder implements OpenFlixApp_HiltComponents.ViewWithFragmentC.Builder {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private final ActivityCImpl activityCImpl;

    private final FragmentCImpl fragmentCImpl;

    private View view;

    private ViewWithFragmentCBuilder(SingletonCImpl singletonCImpl,
        ActivityRetainedCImpl activityRetainedCImpl, ActivityCImpl activityCImpl,
        FragmentCImpl fragmentCImpl) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;
      this.activityCImpl = activityCImpl;
      this.fragmentCImpl = fragmentCImpl;
    }

    @Override
    public ViewWithFragmentCBuilder view(View view) {
      this.view = Preconditions.checkNotNull(view);
      return this;
    }

    @Override
    public OpenFlixApp_HiltComponents.ViewWithFragmentC build() {
      Preconditions.checkBuilderRequirement(view, View.class);
      return new ViewWithFragmentCImpl(singletonCImpl, activityRetainedCImpl, activityCImpl, fragmentCImpl, view);
    }
  }

  private static final class ViewCBuilder implements OpenFlixApp_HiltComponents.ViewC.Builder {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private final ActivityCImpl activityCImpl;

    private View view;

    private ViewCBuilder(SingletonCImpl singletonCImpl, ActivityRetainedCImpl activityRetainedCImpl,
        ActivityCImpl activityCImpl) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;
      this.activityCImpl = activityCImpl;
    }

    @Override
    public ViewCBuilder view(View view) {
      this.view = Preconditions.checkNotNull(view);
      return this;
    }

    @Override
    public OpenFlixApp_HiltComponents.ViewC build() {
      Preconditions.checkBuilderRequirement(view, View.class);
      return new ViewCImpl(singletonCImpl, activityRetainedCImpl, activityCImpl, view);
    }
  }

  private static final class ViewModelCBuilder implements OpenFlixApp_HiltComponents.ViewModelC.Builder {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private SavedStateHandle savedStateHandle;

    private ViewModelLifecycle viewModelLifecycle;

    private ViewModelCBuilder(SingletonCImpl singletonCImpl,
        ActivityRetainedCImpl activityRetainedCImpl) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;
    }

    @Override
    public ViewModelCBuilder savedStateHandle(SavedStateHandle handle) {
      this.savedStateHandle = Preconditions.checkNotNull(handle);
      return this;
    }

    @Override
    public ViewModelCBuilder viewModelLifecycle(ViewModelLifecycle viewModelLifecycle) {
      this.viewModelLifecycle = Preconditions.checkNotNull(viewModelLifecycle);
      return this;
    }

    @Override
    public OpenFlixApp_HiltComponents.ViewModelC build() {
      Preconditions.checkBuilderRequirement(savedStateHandle, SavedStateHandle.class);
      Preconditions.checkBuilderRequirement(viewModelLifecycle, ViewModelLifecycle.class);
      return new ViewModelCImpl(singletonCImpl, activityRetainedCImpl, savedStateHandle, viewModelLifecycle);
    }
  }

  private static final class ServiceCBuilder implements OpenFlixApp_HiltComponents.ServiceC.Builder {
    private final SingletonCImpl singletonCImpl;

    private Service service;

    private ServiceCBuilder(SingletonCImpl singletonCImpl) {
      this.singletonCImpl = singletonCImpl;
    }

    @Override
    public ServiceCBuilder service(Service service) {
      this.service = Preconditions.checkNotNull(service);
      return this;
    }

    @Override
    public OpenFlixApp_HiltComponents.ServiceC build() {
      Preconditions.checkBuilderRequirement(service, Service.class);
      return new ServiceCImpl(singletonCImpl, service);
    }
  }

  private static final class ViewWithFragmentCImpl extends OpenFlixApp_HiltComponents.ViewWithFragmentC {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private final ActivityCImpl activityCImpl;

    private final FragmentCImpl fragmentCImpl;

    private final ViewWithFragmentCImpl viewWithFragmentCImpl = this;

    private ViewWithFragmentCImpl(SingletonCImpl singletonCImpl,
        ActivityRetainedCImpl activityRetainedCImpl, ActivityCImpl activityCImpl,
        FragmentCImpl fragmentCImpl, View viewParam) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;
      this.activityCImpl = activityCImpl;
      this.fragmentCImpl = fragmentCImpl;


    }
  }

  private static final class FragmentCImpl extends OpenFlixApp_HiltComponents.FragmentC {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private final ActivityCImpl activityCImpl;

    private final FragmentCImpl fragmentCImpl = this;

    private FragmentCImpl(SingletonCImpl singletonCImpl,
        ActivityRetainedCImpl activityRetainedCImpl, ActivityCImpl activityCImpl,
        Fragment fragmentParam) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;
      this.activityCImpl = activityCImpl;


    }

    @Override
    public DefaultViewModelFactories.InternalFactoryFactory getHiltInternalFactoryFactory() {
      return activityCImpl.getHiltInternalFactoryFactory();
    }

    @Override
    public ViewWithFragmentComponentBuilder viewWithFragmentComponentBuilder() {
      return new ViewWithFragmentCBuilder(singletonCImpl, activityRetainedCImpl, activityCImpl, fragmentCImpl);
    }
  }

  private static final class ViewCImpl extends OpenFlixApp_HiltComponents.ViewC {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private final ActivityCImpl activityCImpl;

    private final ViewCImpl viewCImpl = this;

    private ViewCImpl(SingletonCImpl singletonCImpl, ActivityRetainedCImpl activityRetainedCImpl,
        ActivityCImpl activityCImpl, View viewParam) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;
      this.activityCImpl = activityCImpl;


    }
  }

  private static final class ActivityCImpl extends OpenFlixApp_HiltComponents.ActivityC {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private final ActivityCImpl activityCImpl = this;

    private ActivityCImpl(SingletonCImpl singletonCImpl,
        ActivityRetainedCImpl activityRetainedCImpl, Activity activityParam) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;


    }

    @Override
    public void injectMainActivity(MainActivity mainActivity) {
      injectMainActivity2(mainActivity);
    }

    @Override
    public DefaultViewModelFactories.InternalFactoryFactory getHiltInternalFactoryFactory() {
      return DefaultViewModelFactories_InternalFactoryFactory_Factory.newInstance(getViewModelKeys(), new ViewModelCBuilder(singletonCImpl, activityRetainedCImpl));
    }

    @Override
    public Set<String> getViewModelKeys() {
      return ImmutableSet.<String>of(AllMediaViewModel_HiltModules_KeyModule_ProvideFactory.provide(), ArchivePlayerViewModel_HiltModules_KeyModule_ProvideFactory.provide(), AuthViewModel_HiltModules_KeyModule_ProvideFactory.provide(), CatchupViewModel_HiltModules_KeyModule_ProvideFactory.provide(), ChannelLogoEditorViewModel_HiltModules_KeyModule_ProvideFactory.provide(), ChannelSurfingViewModel_HiltModules_KeyModule_ProvideFactory.provide(), DVRPlayerViewModel_HiltModules_KeyModule_ProvideFactory.provide(), DVRViewModel_HiltModules_KeyModule_ProvideFactory.provide(), DiscoverViewModel_HiltModules_KeyModule_ProvideFactory.provide(), EPGGuideViewModel_HiltModules_KeyModule_ProvideFactory.provide(), LiveTVGuideViewModel_HiltModules_KeyModule_ProvideFactory.provide(), LiveTVPlayerViewModel_HiltModules_KeyModule_ProvideFactory.provide(), LiveTVViewModel_HiltModules_KeyModule_ProvideFactory.provide(), MediaDetailViewModel_HiltModules_KeyModule_ProvideFactory.provide(), MoviesViewModel_HiltModules_KeyModule_ProvideFactory.provide(), MultiviewViewModel_HiltModules_KeyModule_ProvideFactory.provide(), OnLaterViewModel_HiltModules_KeyModule_ProvideFactory.provide(), RemoteMappingViewModel_HiltModules_KeyModule_ProvideFactory.provide(), SearchViewModel_HiltModules_KeyModule_ProvideFactory.provide(), SettingsViewModel_HiltModules_KeyModule_ProvideFactory.provide(), TVShowsViewModel_HiltModules_KeyModule_ProvideFactory.provide(), TeamPassViewModel_HiltModules_KeyModule_ProvideFactory.provide(), VideoPlayerViewModel_HiltModules_KeyModule_ProvideFactory.provide(), WatchStatsViewModel_HiltModules_KeyModule_ProvideFactory.provide());
    }

    @Override
    public ViewModelComponentBuilder getViewModelComponentBuilder() {
      return new ViewModelCBuilder(singletonCImpl, activityRetainedCImpl);
    }

    @Override
    public FragmentComponentBuilder fragmentComponentBuilder() {
      return new FragmentCBuilder(singletonCImpl, activityRetainedCImpl, activityCImpl);
    }

    @Override
    public ViewComponentBuilder viewComponentBuilder() {
      return new ViewCBuilder(singletonCImpl, activityRetainedCImpl, activityCImpl);
    }

    private MainActivity injectMainActivity2(MainActivity instance) {
      MainActivity_MembersInjector.injectMpvPlayer(instance, singletonCImpl.provideMpvPlayerProvider.get());
      MainActivity_MembersInjector.injectLiveTVPlayer(instance, singletonCImpl.provideLiveTVPlayerProvider.get());
      MainActivity_MembersInjector.injectLastWatchedService(instance, singletonCImpl.lastWatchedServiceProvider.get());
      return instance;
    }
  }

  private static final class ViewModelCImpl extends OpenFlixApp_HiltComponents.ViewModelC {
    private final SavedStateHandle savedStateHandle;

    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private final ViewModelCImpl viewModelCImpl = this;

    private Provider<AllMediaViewModel> allMediaViewModelProvider;

    private Provider<ArchivePlayerViewModel> archivePlayerViewModelProvider;

    private Provider<AuthViewModel> authViewModelProvider;

    private Provider<CatchupViewModel> catchupViewModelProvider;

    private Provider<ChannelLogoEditorViewModel> channelLogoEditorViewModelProvider;

    private Provider<ChannelSurfingViewModel> channelSurfingViewModelProvider;

    private Provider<DVRPlayerViewModel> dVRPlayerViewModelProvider;

    private Provider<DVRViewModel> dVRViewModelProvider;

    private Provider<DiscoverViewModel> discoverViewModelProvider;

    private Provider<EPGGuideViewModel> ePGGuideViewModelProvider;

    private Provider<LiveTVGuideViewModel> liveTVGuideViewModelProvider;

    private Provider<LiveTVPlayerViewModel> liveTVPlayerViewModelProvider;

    private Provider<LiveTVViewModel> liveTVViewModelProvider;

    private Provider<MediaDetailViewModel> mediaDetailViewModelProvider;

    private Provider<MoviesViewModel> moviesViewModelProvider;

    private Provider<MultiviewViewModel> multiviewViewModelProvider;

    private Provider<OnLaterViewModel> onLaterViewModelProvider;

    private Provider<RemoteMappingViewModel> remoteMappingViewModelProvider;

    private Provider<SearchViewModel> searchViewModelProvider;

    private Provider<SettingsViewModel> settingsViewModelProvider;

    private Provider<TVShowsViewModel> tVShowsViewModelProvider;

    private Provider<TeamPassViewModel> teamPassViewModelProvider;

    private Provider<VideoPlayerViewModel> videoPlayerViewModelProvider;

    private Provider<WatchStatsViewModel> watchStatsViewModelProvider;

    private ViewModelCImpl(SingletonCImpl singletonCImpl,
        ActivityRetainedCImpl activityRetainedCImpl, SavedStateHandle savedStateHandleParam,
        ViewModelLifecycle viewModelLifecycleParam) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;
      this.savedStateHandle = savedStateHandleParam;
      initialize(savedStateHandleParam, viewModelLifecycleParam);

    }

    @SuppressWarnings("unchecked")
    private void initialize(final SavedStateHandle savedStateHandleParam,
        final ViewModelLifecycle viewModelLifecycleParam) {
      this.allMediaViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 0);
      this.archivePlayerViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 1);
      this.authViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 2);
      this.catchupViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 3);
      this.channelLogoEditorViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 4);
      this.channelSurfingViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 5);
      this.dVRPlayerViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 6);
      this.dVRViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 7);
      this.discoverViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 8);
      this.ePGGuideViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 9);
      this.liveTVGuideViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 10);
      this.liveTVPlayerViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 11);
      this.liveTVViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 12);
      this.mediaDetailViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 13);
      this.moviesViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 14);
      this.multiviewViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 15);
      this.onLaterViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 16);
      this.remoteMappingViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 17);
      this.searchViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 18);
      this.settingsViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 19);
      this.tVShowsViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 20);
      this.teamPassViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 21);
      this.videoPlayerViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 22);
      this.watchStatsViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 23);
    }

    @Override
    public Map<String, javax.inject.Provider<ViewModel>> getHiltViewModelMap() {
      return ImmutableMap.<String, javax.inject.Provider<ViewModel>>builderWithExpectedSize(24).put("com.openflix.presentation.screens.allmedia.AllMediaViewModel", ((Provider) allMediaViewModelProvider)).put("com.openflix.presentation.screens.livetv.ArchivePlayerViewModel", ((Provider) archivePlayerViewModelProvider)).put("com.openflix.presentation.screens.auth.AuthViewModel", ((Provider) authViewModelProvider)).put("com.openflix.presentation.screens.catchup.CatchupViewModel", ((Provider) catchupViewModelProvider)).put("com.openflix.presentation.screens.livetv.ChannelLogoEditorViewModel", ((Provider) channelLogoEditorViewModelProvider)).put("com.openflix.presentation.screens.livetv.ChannelSurfingViewModel", ((Provider) channelSurfingViewModelProvider)).put("com.openflix.presentation.screens.dvr.DVRPlayerViewModel", ((Provider) dVRPlayerViewModelProvider)).put("com.openflix.presentation.screens.dvr.DVRViewModel", ((Provider) dVRViewModelProvider)).put("com.openflix.presentation.screens.home.DiscoverViewModel", ((Provider) discoverViewModelProvider)).put("com.openflix.presentation.screens.epg.EPGGuideViewModel", ((Provider) ePGGuideViewModelProvider)).put("com.openflix.presentation.screens.livetv.LiveTVGuideViewModel", ((Provider) liveTVGuideViewModelProvider)).put("com.openflix.presentation.screens.livetv.LiveTVPlayerViewModel", ((Provider) liveTVPlayerViewModelProvider)).put("com.openflix.presentation.screens.livetv.LiveTVViewModel", ((Provider) liveTVViewModelProvider)).put("com.openflix.presentation.screens.media.MediaDetailViewModel", ((Provider) mediaDetailViewModelProvider)).put("com.openflix.presentation.screens.movies.MoviesViewModel", ((Provider) moviesViewModelProvider)).put("com.openflix.presentation.screens.livetv.MultiviewViewModel", ((Provider) multiviewViewModelProvider)).put("com.openflix.presentation.screens.onlater.OnLaterViewModel", ((Provider) onLaterViewModelProvider)).put("com.openflix.presentation.screens.settings.RemoteMappingViewModel", ((Provider) remoteMappingViewModelProvider)).put("com.openflix.presentation.screens.search.SearchViewModel", ((Provider) searchViewModelProvider)).put("com.openflix.presentation.screens.settings.SettingsViewModel", ((Provider) settingsViewModelProvider)).put("com.openflix.presentation.screens.tvshows.TVShowsViewModel", ((Provider) tVShowsViewModelProvider)).put("com.openflix.presentation.screens.teampass.TeamPassViewModel", ((Provider) teamPassViewModelProvider)).put("com.openflix.presentation.screens.player.VideoPlayerViewModel", ((Provider) videoPlayerViewModelProvider)).put("com.openflix.presentation.screens.watchstats.WatchStatsViewModel", ((Provider) watchStatsViewModelProvider)).build();
    }

    @Override
    public Map<String, Object> getHiltViewModelAssistedMap() {
      return ImmutableMap.<String, Object>of();
    }

    private static final class SwitchingProvider<T> implements Provider<T> {
      private final SingletonCImpl singletonCImpl;

      private final ActivityRetainedCImpl activityRetainedCImpl;

      private final ViewModelCImpl viewModelCImpl;

      private final int id;

      SwitchingProvider(SingletonCImpl singletonCImpl, ActivityRetainedCImpl activityRetainedCImpl,
          ViewModelCImpl viewModelCImpl, int id) {
        this.singletonCImpl = singletonCImpl;
        this.activityRetainedCImpl = activityRetainedCImpl;
        this.viewModelCImpl = viewModelCImpl;
        this.id = id;
      }

      @SuppressWarnings("unchecked")
      @Override
      public T get() {
        switch (id) {
          case 0: // com.openflix.presentation.screens.allmedia.AllMediaViewModel 
          return (T) new AllMediaViewModel(singletonCImpl.provideMediaRepositoryProvider.get(), viewModelCImpl.savedStateHandle);

          case 1: // com.openflix.presentation.screens.livetv.ArchivePlayerViewModel 
          return (T) new ArchivePlayerViewModel(singletonCImpl.provideLiveTVRepositoryProvider.get(), singletonCImpl.provideMpvPlayerProvider.get());

          case 2: // com.openflix.presentation.screens.auth.AuthViewModel 
          return (T) new AuthViewModel(singletonCImpl.provideAuthRepositoryProvider.get(), singletonCImpl.serverDiscoveryServiceProvider.get());

          case 3: // com.openflix.presentation.screens.catchup.CatchupViewModel 
          return (T) new CatchupViewModel(singletonCImpl.provideLiveTVRepositoryProvider.get());

          case 4: // com.openflix.presentation.screens.livetv.ChannelLogoEditorViewModel 
          return (T) new ChannelLogoEditorViewModel(singletonCImpl.provideLiveTVRepositoryProvider.get());

          case 5: // com.openflix.presentation.screens.livetv.ChannelSurfingViewModel 
          return (T) new ChannelSurfingViewModel(singletonCImpl.provideLiveTVRepositoryProvider.get());

          case 6: // com.openflix.presentation.screens.dvr.DVRPlayerViewModel 
          return (T) new DVRPlayerViewModel(singletonCImpl.provideDVRRepositoryProvider.get(), singletonCImpl.watchStatsServiceProvider.get());

          case 7: // com.openflix.presentation.screens.dvr.DVRViewModel 
          return (T) new DVRViewModel(singletonCImpl.provideDVRRepositoryProvider.get());

          case 8: // com.openflix.presentation.screens.home.DiscoverViewModel 
          return (T) new DiscoverViewModel(singletonCImpl.provideMediaRepositoryProvider.get(), singletonCImpl.provideLiveTVRepositoryProvider.get());

          case 9: // com.openflix.presentation.screens.epg.EPGGuideViewModel 
          return (T) new EPGGuideViewModel(singletonCImpl.provideLiveTVRepositoryProvider.get());

          case 10: // com.openflix.presentation.screens.livetv.LiveTVGuideViewModel 
          return (T) new LiveTVGuideViewModel(singletonCImpl.provideLiveTVRepositoryProvider.get(), singletonCImpl.provideDVRRepositoryProvider.get(), singletonCImpl.lastWatchedServiceProvider.get());

          case 11: // com.openflix.presentation.screens.livetv.LiveTVPlayerViewModel 
          return (T) new LiveTVPlayerViewModel(singletonCImpl.provideLiveTVRepositoryProvider.get(), singletonCImpl.provideDVRRepositoryProvider.get(), singletonCImpl.provideLiveTVPlayerProvider.get(), singletonCImpl.instantSwitchManagerProvider.get(), singletonCImpl.providePreferencesManagerProvider.get(), singletonCImpl.lastWatchedServiceProvider.get(), singletonCImpl.watchStatsServiceProvider.get());

          case 12: // com.openflix.presentation.screens.livetv.LiveTVViewModel 
          return (T) new LiveTVViewModel(singletonCImpl.provideLiveTVRepositoryProvider.get());

          case 13: // com.openflix.presentation.screens.media.MediaDetailViewModel 
          return (T) new MediaDetailViewModel(singletonCImpl.provideMediaRepositoryProvider.get());

          case 14: // com.openflix.presentation.screens.movies.MoviesViewModel 
          return (T) new MoviesViewModel(singletonCImpl.provideMediaRepositoryProvider.get());

          case 15: // com.openflix.presentation.screens.livetv.MultiviewViewModel 
          return (T) new MultiviewViewModel(ApplicationContextModule_ProvideContextFactory.provideContext(singletonCImpl.applicationContextModule), singletonCImpl.provideLiveTVRepositoryProvider.get());

          case 16: // com.openflix.presentation.screens.onlater.OnLaterViewModel 
          return (T) new OnLaterViewModel(singletonCImpl.provideLiveTVRepositoryProvider.get(), singletonCImpl.provideDVRRepositoryProvider.get());

          case 17: // com.openflix.presentation.screens.settings.RemoteMappingViewModel 
          return (T) new RemoteMappingViewModel(singletonCImpl.providePreferencesManagerProvider.get());

          case 18: // com.openflix.presentation.screens.search.SearchViewModel 
          return (T) new SearchViewModel(singletonCImpl.provideMediaRepositoryProvider.get());

          case 19: // com.openflix.presentation.screens.settings.SettingsViewModel 
          return (T) new SettingsViewModel(singletonCImpl.provideSettingsRepositoryProvider.get());

          case 20: // com.openflix.presentation.screens.tvshows.TVShowsViewModel 
          return (T) new TVShowsViewModel(singletonCImpl.provideMediaRepositoryProvider.get());

          case 21: // com.openflix.presentation.screens.teampass.TeamPassViewModel 
          return (T) new TeamPassViewModel(singletonCImpl.provideLiveTVRepositoryProvider.get());

          case 22: // com.openflix.presentation.screens.player.VideoPlayerViewModel 
          return (T) new VideoPlayerViewModel(singletonCImpl.provideMediaRepositoryProvider.get(), singletonCImpl.watchStatsServiceProvider.get());

          case 23: // com.openflix.presentation.screens.watchstats.WatchStatsViewModel 
          return (T) new WatchStatsViewModel(singletonCImpl.watchStatsServiceProvider.get());

          default: throw new AssertionError(id);
        }
      }
    }
  }

  private static final class ActivityRetainedCImpl extends OpenFlixApp_HiltComponents.ActivityRetainedC {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl = this;

    private Provider<ActivityRetainedLifecycle> provideActivityRetainedLifecycleProvider;

    private ActivityRetainedCImpl(SingletonCImpl singletonCImpl,
        SavedStateHandleHolder savedStateHandleHolderParam) {
      this.singletonCImpl = singletonCImpl;

      initialize(savedStateHandleHolderParam);

    }

    @SuppressWarnings("unchecked")
    private void initialize(final SavedStateHandleHolder savedStateHandleHolderParam) {
      this.provideActivityRetainedLifecycleProvider = DoubleCheck.provider(new SwitchingProvider<ActivityRetainedLifecycle>(singletonCImpl, activityRetainedCImpl, 0));
    }

    @Override
    public ActivityComponentBuilder activityComponentBuilder() {
      return new ActivityCBuilder(singletonCImpl, activityRetainedCImpl);
    }

    @Override
    public ActivityRetainedLifecycle getActivityRetainedLifecycle() {
      return provideActivityRetainedLifecycleProvider.get();
    }

    private static final class SwitchingProvider<T> implements Provider<T> {
      private final SingletonCImpl singletonCImpl;

      private final ActivityRetainedCImpl activityRetainedCImpl;

      private final int id;

      SwitchingProvider(SingletonCImpl singletonCImpl, ActivityRetainedCImpl activityRetainedCImpl,
          int id) {
        this.singletonCImpl = singletonCImpl;
        this.activityRetainedCImpl = activityRetainedCImpl;
        this.id = id;
      }

      @SuppressWarnings("unchecked")
      @Override
      public T get() {
        switch (id) {
          case 0: // dagger.hilt.android.ActivityRetainedLifecycle 
          return (T) ActivityRetainedComponentManager_LifecycleModule_ProvideActivityRetainedLifecycleFactory.provideActivityRetainedLifecycle();

          default: throw new AssertionError(id);
        }
      }
    }
  }

  private static final class ServiceCImpl extends OpenFlixApp_HiltComponents.ServiceC {
    private final SingletonCImpl singletonCImpl;

    private final ServiceCImpl serviceCImpl = this;

    private ServiceCImpl(SingletonCImpl singletonCImpl, Service serviceParam) {
      this.singletonCImpl = singletonCImpl;


    }
  }

  private static final class SingletonCImpl extends OpenFlixApp_HiltComponents.SingletonC {
    private final ApplicationContextModule applicationContextModule;

    private final SingletonCImpl singletonCImpl = this;

    private Provider<DataStore<Preferences>> provideDataStoreProvider;

    private Provider<PreferencesManager> providePreferencesManagerProvider;

    private Provider<SettingsRepository> provideSettingsRepositoryProvider;

    private Provider<MpvPlayer> provideMpvPlayerProvider;

    private Provider<LiveTVPlayer> provideLiveTVPlayerProvider;

    private Provider<LastWatchedService> lastWatchedServiceProvider;

    private Provider<HttpLoggingInterceptor> provideLoggingInterceptorProvider;

    private Provider<AuthInterceptor> provideAuthInterceptorProvider;

    private Provider<OkHttpClient> provideOkHttpClientProvider;

    private Provider<Retrofit> provideRetrofitProvider;

    private Provider<OpenFlixApi> provideOpenFlixApiProvider;

    private Provider<MediaRepository> provideMediaRepositoryProvider;

    private Provider<LiveTVRepository> provideLiveTVRepositoryProvider;

    private Provider<AuthRepository> provideAuthRepositoryProvider;

    private Provider<ServerDiscoveryService> serverDiscoveryServiceProvider;

    private Provider<DVRRepository> provideDVRRepositoryProvider;

    private Provider<WatchStatsService> watchStatsServiceProvider;

    private Provider<InstantSwitchManager> instantSwitchManagerProvider;

    private SingletonCImpl(ApplicationContextModule applicationContextModuleParam) {
      this.applicationContextModule = applicationContextModuleParam;
      initialize(applicationContextModuleParam);

    }

    @SuppressWarnings("unchecked")
    private void initialize(final ApplicationContextModule applicationContextModuleParam) {
      this.provideDataStoreProvider = DoubleCheck.provider(new SwitchingProvider<DataStore<Preferences>>(singletonCImpl, 3));
      this.providePreferencesManagerProvider = DoubleCheck.provider(new SwitchingProvider<PreferencesManager>(singletonCImpl, 2));
      this.provideSettingsRepositoryProvider = DoubleCheck.provider(new SwitchingProvider<SettingsRepository>(singletonCImpl, 1));
      this.provideMpvPlayerProvider = DoubleCheck.provider(new SwitchingProvider<MpvPlayer>(singletonCImpl, 0));
      this.provideLiveTVPlayerProvider = DoubleCheck.provider(new SwitchingProvider<LiveTVPlayer>(singletonCImpl, 4));
      this.lastWatchedServiceProvider = DoubleCheck.provider(new SwitchingProvider<LastWatchedService>(singletonCImpl, 5));
      this.provideLoggingInterceptorProvider = DoubleCheck.provider(new SwitchingProvider<HttpLoggingInterceptor>(singletonCImpl, 10));
      this.provideAuthInterceptorProvider = DoubleCheck.provider(new SwitchingProvider<AuthInterceptor>(singletonCImpl, 11));
      this.provideOkHttpClientProvider = DoubleCheck.provider(new SwitchingProvider<OkHttpClient>(singletonCImpl, 9));
      this.provideRetrofitProvider = DoubleCheck.provider(new SwitchingProvider<Retrofit>(singletonCImpl, 8));
      this.provideOpenFlixApiProvider = DoubleCheck.provider(new SwitchingProvider<OpenFlixApi>(singletonCImpl, 7));
      this.provideMediaRepositoryProvider = DoubleCheck.provider(new SwitchingProvider<MediaRepository>(singletonCImpl, 6));
      this.provideLiveTVRepositoryProvider = DoubleCheck.provider(new SwitchingProvider<LiveTVRepository>(singletonCImpl, 12));
      this.provideAuthRepositoryProvider = DoubleCheck.provider(new SwitchingProvider<AuthRepository>(singletonCImpl, 13));
      this.serverDiscoveryServiceProvider = DoubleCheck.provider(new SwitchingProvider<ServerDiscoveryService>(singletonCImpl, 14));
      this.provideDVRRepositoryProvider = DoubleCheck.provider(new SwitchingProvider<DVRRepository>(singletonCImpl, 15));
      this.watchStatsServiceProvider = DoubleCheck.provider(new SwitchingProvider<WatchStatsService>(singletonCImpl, 16));
      this.instantSwitchManagerProvider = DoubleCheck.provider(new SwitchingProvider<InstantSwitchManager>(singletonCImpl, 17));
    }

    @Override
    public void injectOpenFlixApp(OpenFlixApp openFlixApp) {
    }

    @Override
    public Set<Boolean> getDisableFragmentGetContextFix() {
      return ImmutableSet.<Boolean>of();
    }

    @Override
    public ActivityRetainedComponentBuilder retainedComponentBuilder() {
      return new ActivityRetainedCBuilder(singletonCImpl);
    }

    @Override
    public ServiceComponentBuilder serviceComponentBuilder() {
      return new ServiceCBuilder(singletonCImpl);
    }

    private static final class SwitchingProvider<T> implements Provider<T> {
      private final SingletonCImpl singletonCImpl;

      private final int id;

      SwitchingProvider(SingletonCImpl singletonCImpl, int id) {
        this.singletonCImpl = singletonCImpl;
        this.id = id;
      }

      @SuppressWarnings("unchecked")
      @Override
      public T get() {
        switch (id) {
          case 0: // com.openflix.player.MpvPlayer 
          return (T) PlayerModule_ProvideMpvPlayerFactory.provideMpvPlayer(ApplicationContextModule_ProvideContextFactory.provideContext(singletonCImpl.applicationContextModule), singletonCImpl.provideSettingsRepositoryProvider.get());

          case 1: // com.openflix.data.repository.SettingsRepository 
          return (T) AppModule_ProvideSettingsRepositoryFactory.provideSettingsRepository(singletonCImpl.providePreferencesManagerProvider.get());

          case 2: // com.openflix.data.local.PreferencesManager 
          return (T) AppModule_ProvidePreferencesManagerFactory.providePreferencesManager(singletonCImpl.provideDataStoreProvider.get());

          case 3: // androidx.datastore.core.DataStore<androidx.datastore.preferences.core.Preferences> 
          return (T) AppModule_ProvideDataStoreFactory.provideDataStore(ApplicationContextModule_ProvideContextFactory.provideContext(singletonCImpl.applicationContextModule));

          case 4: // com.openflix.player.LiveTVPlayer 
          return (T) PlayerModule_ProvideLiveTVPlayerFactory.provideLiveTVPlayer(ApplicationContextModule_ProvideContextFactory.provideContext(singletonCImpl.applicationContextModule));

          case 5: // com.openflix.data.local.LastWatchedService 
          return (T) new LastWatchedService(ApplicationContextModule_ProvideContextFactory.provideContext(singletonCImpl.applicationContextModule));

          case 6: // com.openflix.data.repository.MediaRepository 
          return (T) NetworkModule_ProvideMediaRepositoryFactory.provideMediaRepository(singletonCImpl.provideOpenFlixApiProvider.get(), singletonCImpl.providePreferencesManagerProvider.get());

          case 7: // com.openflix.data.remote.api.OpenFlixApi 
          return (T) NetworkModule_ProvideOpenFlixApiFactory.provideOpenFlixApi(singletonCImpl.provideRetrofitProvider.get());

          case 8: // retrofit2.Retrofit 
          return (T) NetworkModule_ProvideRetrofitFactory.provideRetrofit(singletonCImpl.provideOkHttpClientProvider.get(), singletonCImpl.providePreferencesManagerProvider.get());

          case 9: // okhttp3.OkHttpClient 
          return (T) NetworkModule_ProvideOkHttpClientFactory.provideOkHttpClient(singletonCImpl.provideLoggingInterceptorProvider.get(), singletonCImpl.provideAuthInterceptorProvider.get());

          case 10: // okhttp3.logging.HttpLoggingInterceptor 
          return (T) NetworkModule_ProvideLoggingInterceptorFactory.provideLoggingInterceptor();

          case 11: // com.openflix.data.remote.api.AuthInterceptor 
          return (T) NetworkModule_ProvideAuthInterceptorFactory.provideAuthInterceptor(singletonCImpl.providePreferencesManagerProvider.get());

          case 12: // com.openflix.data.repository.LiveTVRepository 
          return (T) NetworkModule_ProvideLiveTVRepositoryFactory.provideLiveTVRepository(singletonCImpl.provideOpenFlixApiProvider.get(), singletonCImpl.providePreferencesManagerProvider.get());

          case 13: // com.openflix.data.repository.AuthRepository 
          return (T) NetworkModule_ProvideAuthRepositoryFactory.provideAuthRepository(singletonCImpl.provideOpenFlixApiProvider.get(), singletonCImpl.providePreferencesManagerProvider.get());

          case 14: // com.openflix.data.discovery.ServerDiscoveryService 
          return (T) new ServerDiscoveryService();

          case 15: // com.openflix.data.repository.DVRRepository 
          return (T) NetworkModule_ProvideDVRRepositoryFactory.provideDVRRepository(singletonCImpl.provideOpenFlixApiProvider.get(), singletonCImpl.providePreferencesManagerProvider.get());

          case 16: // com.openflix.data.local.WatchStatsService 
          return (T) new WatchStatsService(ApplicationContextModule_ProvideContextFactory.provideContext(singletonCImpl.applicationContextModule));

          case 17: // com.openflix.player.InstantSwitchManager 
          return (T) new InstantSwitchManager(ApplicationContextModule_ProvideContextFactory.provideContext(singletonCImpl.applicationContextModule));

          default: throw new AssertionError(id);
        }
      }
    }
  }
}
