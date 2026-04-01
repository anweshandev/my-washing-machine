# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in /usr/local/Cellar/android-sdk/24.3.3/tools/proguard/proguard-android.txt
# You can edit the include path and order by changing the proguardFiles
# directive in build.gradle.

# For more details, see
# http://developer.android.com/guide/developing/tools/proguard.html

# Flutter-related
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**
-keep class io.flutter.plugin.** { *; }


# Required for Firebase Auth + Google Sign-In added on 07/05/25
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.common.api.** { *; }
-keep class com.google.firebase.auth.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.api.** { *; }
-dontwarn com.google.**