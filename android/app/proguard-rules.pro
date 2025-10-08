# Keep Hive generated adapters and model classes (avoid reflection stripping issues)
-keep class ** extends io.flutter.app.FlutterApplication { *; }
-keep class io.flutter.** { *; }
-keep class com.example.notes_app.** { *; }

# Hive classes often accessed via generated code; keep model and generated adapters
-keep class ** extends org.hivedb.** { *; }
-keep class ** implements org.hivedb.** { *; }
-keep class **$$Adapter { *; }
-keep class **Adapter { *; }
-keep class ** extends hive_flutter.** { *; }

# Keep annotations and Kotlin metadata
-keepattributes *Annotation*, InnerClasses, EnclosingMethod, Signature
-dontwarn kotlin.**
-dontwarn javax.annotation.**
-dontwarn org.jetbrains.annotations.**
