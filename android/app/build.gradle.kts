import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: create android/key.properties (gitignored) with
// storeFile, storePassword, keyAlias, keyPassword. Without it, release
// builds fall back to the debug key (fine for internal App Distribution,
// NOT accepted by Google Play).
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

android {
    namespace = "ro.viamioritica.via_mioritica"
    // compileSdk 37 required by `permission_handler_android` (declares compileSdk 37).
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "ro.viamioritica.via_mioritica"
        // Faza 12 — decizie explicită (nu mai lăsăm valorile implicite din Flutter):
        // minSdk 24 (Android 7.0) este cerut de `permission_handler_android` și
        // `url_launcher_android` (ambele declară minSdk 24); coincide și cu
        // valoarea implicită curentă din Flutter, dar o fixăm explicit ca să nu
        // regreseze silențios la un upgrade viitor de Flutter. Acoperă >98% din
        // device-urile Android active (2026) — acceptabil pentru un public general.
        minSdk = 24
        // targetSdk 36 — ultima versiune stabilă Android suportată de Flutter la
        // data acestei decizii; cerință Google Play pentru aplicații noi/update-uri.
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystoreProperties.containsKey("storeFile")) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
