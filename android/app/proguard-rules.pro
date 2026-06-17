# ── Growth OS ProGuard Rules ──────────────────────────────────────────────────

# ── Flutter / Dart ────────────────────────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ── Drift / SQLite ───────────────────────────────────────────────────────────
# Keep all Drift-generated database classes, tables, and companions
-keep class com.growthos.growth_os.** { *; }
-keep class drift.** { *; }
-keep class **.database.** { *; }
# Keep generated Drift code (app_database.g.dart, etc.)
-keep class ** extends drift.GeneratedDatabase { *; }
-keep class ** implements drift.DatabaseConnectionUser { *; }

# ── Freezed / JSON Serializable ──────────────────────────────────────────────
-keep class **.g.dart { *; }
-keep class **.freezed.dart { *; }
# Keep all model classes used for JSON serialization
-keep @com.google.gson.annotations.SerializedName class * { *; }

# ── just_audio / audio_service ───────────────────────────────────────────────
-keep class com.google.android.exoplayer2.** { *; }
-keep class com.ryanheise.audio_service.** { *; }
-keep class com.ryanheise.audioservice.** { *; }

# ── flutter_local_notifications ──────────────────────────────────────────────
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# ── shared_preferences ───────────────────────────────────────────────────────
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# ── url_launcher ─────────────────────────────────────────────────────────────
-keep class io.flutter.plugins.urllauncher.** { *; }

# ── file_picker ──────────────────────────────────────────────────────────────
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# ── share_plus ───────────────────────────────────────────────────────────────
-keep class dev.fluttercommunity.plus.share.** { *; }

# ── image_picker ─────────────────────────────────────────────────────────────
-keep class io.flutter.plugins.imagepicker.** { *; }

# ── geolocator ───────────────────────────────────────────────────────────────
-keep class com.baseflow.geolocator.** { *; }

# ── crypto / encrypt ─────────────────────────────────────────────────────────
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# ── General ──────────────────────────────────────────────────────────────────
# Keep annotations
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes Exceptions

# Remove debug logs in release
-assumenosideeffects class android.util.Log {
    public static int d(...);
    public static int v(...);
}
# ── Google Play Core (Flutter deferred components) ───────────────────────────
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task