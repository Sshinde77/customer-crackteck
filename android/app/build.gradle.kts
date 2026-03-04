import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

fun hasText(value: String?): Boolean = !value.isNullOrBlank()

val storeFilePath = keystoreProperties.getProperty("storeFile")
val storePasswordValue = keystoreProperties.getProperty("storePassword")
val keyAliasValue = keystoreProperties.getProperty("keyAlias")
val keyPasswordValue = keystoreProperties.getProperty("keyPassword")
val resolvedStoreFile = if (hasText(storeFilePath)) rootProject.file(storeFilePath!!) else null

val hasReleaseKeystore = hasText(storeFilePath) &&
    hasText(storePasswordValue) &&
    hasText(keyAliasValue) &&
    hasText(keyPasswordValue) &&
    resolvedStoreFile?.exists() == true

val isReleaseTask = gradle.startParameter.taskNames.any { task ->
    task.contains("Release", ignoreCase = true)
}

android {
    namespace = "com.example.customer_cracktreck"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.customer_cracktreck"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        multiDexEnabled = true
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                storeFile = resolvedStoreFile
                storePassword = storePasswordValue
                keyAlias = keyAliasValue
                keyPassword = keyPasswordValue
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            if (!hasReleaseKeystore && isReleaseTask) {
                throw GradleException(
                    "Missing release signing config. Ensure android/key.properties exists and storeFile points to android/app/upload-keystore.jks.",
                )
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("com.google.android.play:core:1.10.3")
}

flutter {
    source = "../.."
}
