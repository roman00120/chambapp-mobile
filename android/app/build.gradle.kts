import java.net.URI
import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeystorePath = providers.environmentVariable("CHAMBAPP_KEYSTORE_PATH")
val releaseKeyAlias = providers.environmentVariable("CHAMBAPP_KEY_ALIAS")
val releaseStorePassword = providers.environmentVariable("CHAMBAPP_STORE_PASSWORD")
val releaseKeyPassword = providers.environmentVariable("CHAMBAPP_KEY_PASSWORD")
val releaseSigningReady = listOf(
    releaseKeystorePath,
    releaseKeyAlias,
    releaseStorePassword,
    releaseKeyPassword,
).all { it.orNull?.isNotBlank() == true }
val releaseDartDefines = providers.gradleProperty("dart-defines").orNull
    ?.split(',')
    ?.mapNotNull { encoded ->
        runCatching {
            String(Base64.getDecoder().decode(encoded), Charsets.UTF_8)
        }.getOrNull()
    }
    ?.mapNotNull { value ->
        val separator = value.indexOf('=')
        if (separator <= 0) null else value.substring(0, separator) to value.substring(separator + 1)
    }
    ?.toMap()
    .orEmpty()

android {
    namespace = "com.chambapp.mobile"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.chambapp.mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseSigningReady) {
            create("release") {
                storeFile = file(releaseKeystorePath.get())
                storePassword = releaseStorePassword.get()
                keyAlias = releaseKeyAlias.get()
                keyPassword = releaseKeyPassword.get()
            }
        }
    }

    buildTypes {
        release {
            if (releaseSigningReady) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

val validateReleaseSigning by tasks.registering {
    doLast {
        if (releaseDartDefines["APP_ENV"] != "production") {
            throw GradleException("Release requires --dart-define=APP_ENV=production.")
        }
        val apiBaseUrl = releaseDartDefines["API_BASE_URL"]
        if (apiBaseUrl.isNullOrBlank()) {
            throw GradleException("Release requires --dart-define=API_BASE_URL=https://DOMINIO-REAL/api/v1.")
        }
        val apiUri = runCatching { URI(apiBaseUrl) }.getOrNull()
        if (apiUri?.scheme?.lowercase() != "https" || apiUri.host.isNullOrBlank()) {
            throw GradleException("Release API_BASE_URL must be an absolute HTTPS URL.")
        }
        if (!releaseSigningReady) {
            throw GradleException(
                "Release signing requires CHAMBAPP_KEYSTORE_PATH, CHAMBAPP_KEY_ALIAS, " +
                    "CHAMBAPP_STORE_PASSWORD and CHAMBAPP_KEY_PASSWORD.",
            )
        }
        val keystore = file(releaseKeystorePath.get())
        if (!keystore.isFile) {
            throw GradleException("Release keystore was not found at the configured path.")
        }
    }
}

tasks.configureEach {
    if (name == "preReleaseBuild") {
        dependsOn(validateReleaseSigning)
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
