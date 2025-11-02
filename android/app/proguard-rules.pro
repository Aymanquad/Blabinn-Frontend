# Flutter and common plugin safe shrink rules (non-destructive)

# Keep Flutter's embedding and plugin registrant
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep application classes that may be reflected
-keep class com.company.blabinn.** { *; }

# Google Mobile Ads SDK (prevent stripping adapters and mediation)
-keep class com.google.android.gms.ads.** { *; }
-keep interface com.google.android.gms.ads.** { *; }

# Firebase (core/auth/messaging) – most provide consumer rules, but be safe
-keep class com.google.firebase.** { *; }
-keep interface com.google.firebase.** { *; }

# Play Services common
-keep class com.google.android.gms.** { *; }

# Kotlin metadata annotations (avoid reflective issues)
-keep class kotlin.Metadata { *; }

# Keep serialized/deserialized model classes (if using reflection/JSON)
-keepclassmembers class ** {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Okio/OkHttp (often safe; consumer rules exist, but keep minimal)
-dontwarn okhttp3.**
-dontwarn okio.**

# Avoid warnings about missing META-INF
-dontwarn org.codehaus.mojo.animal_sniffer.*

# Google Play Core (for Flutter deferred components) - completely ignore
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**

# Flutter deferred components - completely ignore
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication

# Ignore all Google Play Core related classes
-ignorewarnings

