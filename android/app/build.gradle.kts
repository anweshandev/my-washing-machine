import java.util.Properties
import java.io.FileInputStream
import com.google.firebase.crashlytics.buildtools.gradle.CrashlyticsExtension


plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}


// --- load properties (global project props take precedence, fallback to key.properties) ---
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    println("Loading keystore.properties file...")
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun prop(name: String): String? =
    (project.findProperty(name) as String?).takeIf { !it.isNullOrEmpty() }
        ?: keystoreProperties.getProperty(name)

android {
    namespace = "dev.anweshan.apps.laundryiq"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "dev.anweshan.apps.laundryiq"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storePassword = keystoreProperties["storePassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            configure<CrashlyticsExtension> {
                // Enable processing and uploading of native symbols to Firebase servers.
                // By default, this is disabled to improve build speeds.
                // This flag must be enabled to see properly-symbolicated native
                // stack traces in the Crashlytics dashboard.
                nativeSymbolUploadEnabled = true
            }
        }

        getByName("debug") {
            // Default
        }
    }
}

flutter {
    source = "../.."
}

// --- Configure Crashlytics plugin extension safely after evaluation ---
// Use method-name lookup to avoid java.lang parsing issues in the Kotlin script.
afterEvaluate {
    try {
        val ext = project.extensions.findByName("firebaseCrashlytics")
        if (ext != null) {
            val clazz = Class.forName("com.google.firebase.crashlytics.buildtools.gradle.CrashlyticsExtension")
            if (clazz.isInstance(ext)) {
                // Find and call setter by name (avoid referencing java.lang.Boolean::class.java)
                fun callBooleanSetter(methodName: String) {
                    val method = clazz.methods.firstOrNull { it.name == methodName && it.parameterCount == 1 }
                    if (method != null) {
                        try {
                            method.invoke(ext, true)
                            println("Crashlytics: set $methodName = true")
                        } catch (invokeEx: Throwable) {
                            println("Crashlytics: failed invoking $methodName: ${invokeEx.message}")
                        }
                    } else {
                        println("Crashlytics: method $methodName() not found on extension (plugin version may differ).")
                    }
                }

                callBooleanSetter("setMappingFileUploadEnabled")
                callBooleanSetter("setNativeSymbolUploadEnabled")
            }
        } else {
            println("Crashlytics extension not present; skipping configuration.")
        }
    } catch (e: Exception) {
        println("Warning: Crashlytics extension not configured programmatically: ${e.message}")
    }
}
