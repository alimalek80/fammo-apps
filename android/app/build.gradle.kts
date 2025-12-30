import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "ai.fammo.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    signingConfigs {
        getByName("debug") // keep debug config available

        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = (keystoreProperties["keyAlias"] as? String)
                    ?: error("Missing keyAlias in key.properties")
                keyPassword = (keystoreProperties["keyPassword"] as? String)
                    ?: error("Missing keyPassword in key.properties")
                storeFile = file((keystoreProperties["storeFile"] as? String)
                    ?: error("Missing storeFile in key.properties"))
                storePassword = (keystoreProperties["storePassword"] as? String)
                    ?: error("Missing storePassword in key.properties")
            }
        } else {
            create("release") {
                initWith(getByName("debug"))
            }
        }
    }

    defaultConfig {
        // Unique Application ID for FAMMO app
        applicationId = "ai.fammo.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
