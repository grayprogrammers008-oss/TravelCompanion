# Keep Flutter internal classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.plugin.editing.** { *; }

# Firebase / FCM
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**

# Google Play Core (referenced by some plugins; OK to skip if unused)
-dontwarn com.google.android.play.core.**

# Supabase / Realtime
-keep class io.supabase.** { *; }

# Hive
-keep class * extends hive_flutter.HiveObject { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# ML Kit (bill scanner)
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Speech to Text
-keep class com.csdcorp.speech_to_text.** { *; }

# WiFi Direct / P2P plugin
-keep class com.example.flutter_p2p_connection.** { *; }

# Keep model classes used in JSON serialization (heuristic).
# If you have *.g.dart generated code, those rely on reflection.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
