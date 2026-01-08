plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.mindsync"
    compileSdk = flutter.compileSdkVersion
    // FIX 1: Use = for assignment in Kotlin Script
    ndkVersion = "27.0.12077973"

    compileOptions {
        // FIX 2: Correct syntax for enabling desugaring
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.mindsync"
        // FIX 3: Use = true
        multiDexEnabled = true

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // FIX 4: Use parentheses and quotes for dependencies
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}