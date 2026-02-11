package com.openflix.di

import com.openflix.data.local.PreferencesManager
import com.openflix.data.remote.api.OpenFlixApi
import com.openflix.data.remote.api.AuthInterceptor
import com.openflix.data.repository.AuthRepository
import com.openflix.data.repository.DVRRepository
import com.openflix.data.repository.LiveTVRepository
import com.openflix.data.repository.MediaRepository
import com.openflix.data.repository.RemoteAccessRepository
import android.content.Context
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    @Provides
    @Singleton
    fun provideLoggingInterceptor(): HttpLoggingInterceptor {
        return HttpLoggingInterceptor().apply {
            // Use HEADERS instead of BODY to avoid logging large channel responses
            level = HttpLoggingInterceptor.Level.HEADERS
        }
    }

    @Provides
    @Singleton
    fun provideAuthInterceptor(preferencesManager: PreferencesManager): AuthInterceptor {
        return AuthInterceptor(preferencesManager)
    }

    @Provides
    @Singleton
    fun provideOkHttpClient(
        loggingInterceptor: HttpLoggingInterceptor,
        authInterceptor: AuthInterceptor
    ): OkHttpClient {
        return OkHttpClient.Builder()
            .addInterceptor(authInterceptor)
            .addInterceptor(loggingInterceptor)
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(120, TimeUnit.SECONDS)
            .writeTimeout(60, TimeUnit.SECONDS)
            .build()
    }

    @Provides
    @Singleton
    fun provideRetrofit(
        okHttpClient: OkHttpClient,
        preferencesManager: PreferencesManager
    ): Retrofit {
        // Note: baseUrl will be updated dynamically based on server selection
        return Retrofit.Builder()
            .baseUrl("http://127.0.0.1:32400/") // Placeholder, will be overridden by AuthInterceptor
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
    }

    @Provides
    @Singleton
    fun provideOpenFlixApi(retrofit: Retrofit): OpenFlixApi {
        return retrofit.create(OpenFlixApi::class.java)
    }

    @Provides
    @Singleton
    fun provideAuthRepository(
        api: OpenFlixApi,
        preferencesManager: PreferencesManager
    ): AuthRepository {
        return AuthRepository(api, preferencesManager)
    }

    @Provides
    @Singleton
    fun provideMediaRepository(
        api: OpenFlixApi,
        preferencesManager: PreferencesManager
    ): MediaRepository {
        return MediaRepository(api, preferencesManager)
    }

    @Provides
    @Singleton
    fun provideLiveTVRepository(
        api: OpenFlixApi,
        preferencesManager: PreferencesManager
    ): LiveTVRepository {
        return LiveTVRepository(api, preferencesManager)
    }

    @Provides
    @Singleton
    fun provideDVRRepository(
        api: OpenFlixApi,
        preferencesManager: PreferencesManager
    ): DVRRepository {
        return DVRRepository(api, preferencesManager)
    }

    @Provides
    @Singleton
    fun provideRemoteAccessRepository(
        @ApplicationContext context: Context,
        api: OpenFlixApi,
        preferencesManager: PreferencesManager
    ): RemoteAccessRepository {
        return RemoteAccessRepository(context, api, preferencesManager)
    }
}
