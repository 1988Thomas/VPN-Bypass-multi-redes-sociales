# ============================================================
# Script: CorregirAndroidX.ps1
# Soluciona errores de AndroidX y actualiza el plugin
# ============================================================

$basePath = "C:\Thomas\VIP"

# 1. Crear/actualizar gradle.properties
$gradlePropertiesPath = "$basePath\gradle.properties"
$gradlePropertiesContent = @"
# AndroidX
android.useAndroidX=true
android.enableJetifier=true

# Suprimir advertencia de compileSdk
android.suppressUnsupportedCompileSdk=34
"@
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($gradlePropertiesPath, $gradlePropertiesContent, $utf8NoBom)
Write-Host "✅ Creado/actualizado: gradle.properties" -ForegroundColor Green

# 2. Actualizar build.gradle (proyecto) para usar plugin más reciente
$buildGradlePath = "$basePath\build.gradle"
$buildGradleContent = @"
buildscript {
    ext.kotlin_version = '1.9.0'
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.5.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }
    }
}

task clean(type: Delete) {
    delete rootProject.buildDir
}
"@
[System.IO.File]::WriteAllText($buildGradlePath, $buildGradleContent, $utf8NoBom)
Write-Host "✅ Actualizado: build.gradle (proyecto)" -ForegroundColor Green

# 3. Actualizar app/build.gradle para usar compileSdk 34 y targetSdk 34
$appBuildGradlePath = "$basePath\app\build.gradle"
$appBuildGradleContent = @"
plugins {
    id 'com.android.application'
    id 'org.jetbrains.kotlin.android'
}

android {
    namespace 'com.ejemplo.vpnbypass'
    compileSdk 34

    defaultConfig {
        applicationId "com.ejemplo.vpnbypass"
        minSdk 26
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }

    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = '17'
    }
}

dependencies {
    implementation 'androidx.core:core-ktx:1.12.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.11.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'com.github.ssrlive:tun2socks:1.0.0'
}
"@
[System.IO.File]::WriteAllText($appBuildGradlePath, $appBuildGradleContent, $utf8NoBom)
Write-Host "✅ Actualizado: app/build.gradle" -ForegroundColor Green

Write-Host "`n📌 Archivos modificados:" -ForegroundColor Yellow
Write-Host "  - gradle.properties (nuevo)" -ForegroundColor Cyan
Write-Host "  - build.gradle (proyecto) -> plugin 8.5.0" -ForegroundColor Cyan
Write-Host "  - app/build.gradle -> compileSdk 34, targetSdk 34" -ForegroundColor Cyan

Write-Host "`nAhora haz commit y push:" -ForegroundColor Yellow
Write-Host "  git add gradle.properties build.gradle app/build.gradle" -ForegroundColor Cyan
Write-Host "  git commit -m 'fix: enable AndroidX, update Gradle plugin to 8.5.0'" -ForegroundColor Cyan
Write-Host "  git push origin main" -ForegroundColor Cyan