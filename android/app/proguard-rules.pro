# Add project specific ProGuard rules here.

# Keep camera related classes
-keep class io.flutter.plugins.camera.** { *; }
-keep class com.google.mlkit.** { *; }

# Keep mobile scanner classes
-keep class dev.steenbakker.mobile_scanner.** { *; }

# Keep image picker classes
-keep class io.flutter.plugins.imagepicker.** { *; }

# Keep classes for mobile_scanner
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep MLKit classes
-keep class com.google.mlkit.vision.** { *; }
-keep class com.google.android.gms.vision.** { *; }

# General Android camera
-keep class android.hardware.camera2.** { *; }
-keep class androidx.camera.** { *; }
