# Ktor
-keep class io.ktor.** { *; }
-dontwarn io.ktor.**

# kotlinx.serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt
-keepclassmembers class kotlinx.serialization.json.** {
    *** Companion;
}
-keepclasseswithmembers class kotlinx.serialization.json.** {
    kotlinx.serialization.KSerializer serializer(...);
}
-keep,includedescriptorclasses class com.openflix.**$$serializer { *; }
-keepclassmembers class com.openflix.** {
    *** Companion;
}
-keepclasseswithmembers class com.openflix.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# mpv (libmpv) - GPU video upscaling
-keep class dev.jdtech.mpv.** { *; }
-dontwarn dev.jdtech.mpv.**
