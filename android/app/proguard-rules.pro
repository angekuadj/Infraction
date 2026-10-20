# ML Kit Text Recognition references optional language models.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# ML Kit : les registraires sont instanciés par réflexion (constructeur
# sans argument) au démarrage via MlKitInitProvider.
-keep class com.google.mlkit.**.*Registrar { <init>(); }
-keep class com.google.mlkit.common.internal.MlKitInitProvider { *; }

# TensorFlow Lite / LiteRT
-keep class org.tensorflow.lite.** { *; }
-keep class com.google.ai.edge.litert.** { *; }
-dontwarn org.tensorflow.lite.**
-dontwarn com.google.ai.edge.litert.**

# Flutter local notifications
-keep class com.dexterous.** { *; }

# Video thumbnail plugin
-keep class xyz.justsoft.video_thumbnail.** { *; }

# shared_preferences_android 2.5+ (Pigeon JNI) : Dart résout les méthodes
# Kotlin par descripteur exact (package:jni). R8 ne doit rien renommer dans
# ces classes ni dans les types des paramètres référencés depuis Dart.
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keepnames class io.flutter.plugins.sharedpreferences.**
-keep interface kotlin.coroutines.Continuation { *; }
-keep interface kotlin.enums.EnumEntries { *; }
-keep class kotlin.Unit { *; }
-keepnames class kotlin.jvm.internal.DefaultConstructorMarker
