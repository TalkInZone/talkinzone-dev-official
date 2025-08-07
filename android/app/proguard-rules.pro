# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Play Core
-keep class com.google.android.play.** { *; }
-dontwarn com.google.android.play.**

# Xiaomi
-keep class com.xiaomi.** { *; }
-dontwarn com.xiaomi.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Support Libraries
-keep class androidx.** { *; }
-dontwarn androidx.**

# WorkManager
-keep class androidx.work.** { *; }

# Coroutines
-keep class kotlinx.coroutines.** { *; }