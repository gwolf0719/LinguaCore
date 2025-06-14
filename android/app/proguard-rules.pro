# Flutter and Dart optimizations
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_** { *; }

# Speech to Text
-keep class com.google.android.gms.** { *; }

# TTS
-keep class android.speech.tts.** { *; }

# Audio recording
-keep class android.media.** { *; }

# General Android optimizations
-dontwarn com.google.android.gms.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**