package com.openflix.domain.model

data class TrailerInfo(
    val youtubeKey: String,
    val name: String,
    val backdropPath: String? = null
) {
    val id: String get() = youtubeKey

    val tmdbBackdropURL: String? get() {
        val path = backdropPath ?: return null
        return "https://image.tmdb.org/t/p/original$path"
    }

    val tmdbBackdropURLMedium: String? get() {
        val path = backdropPath ?: return null
        return "https://image.tmdb.org/t/p/w1280$path"
    }

    val embedURL: String get() =
        "https://www.youtube.com/embed/$youtubeKey?autoplay=1&mute=1&controls=0&showinfo=0&rel=0&modestbranding=1&playsinline=1&loop=1&playlist=$youtubeKey&enablejsapi=1"

    val watchURL: String get() = "https://www.youtube.com/watch?v=$youtubeKey"

    val thumbnailURL: String get() = "https://img.youtube.com/vi/$youtubeKey/maxresdefault.jpg"

    val thumbnailURLMedium: String get() = "https://img.youtube.com/vi/$youtubeKey/hqdefault.jpg"
}
