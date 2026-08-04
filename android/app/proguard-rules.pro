# Flutter Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# Drift / SQLite Rules
-keep class * extends net.simonvt.schematic.annotation.Database { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-dontwarn sqlite3.**
-dontwarn com.simonvt.schematic.**

# Google ML Kit Text Recognition Rules
-keep class com.google.mlkit.vision.text.** { *; }
-dontwarn com.google.mlkit.vision.text.**

# Firebase Rules
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Keep models & entities
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
