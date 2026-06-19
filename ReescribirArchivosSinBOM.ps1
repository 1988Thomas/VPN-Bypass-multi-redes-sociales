# ============================================================
# Script: ReescribirArchivosSinBOM.ps1
# Reescribe build.gradle, app/build.gradle, settings.gradle,
# y gradle.properties sin BOM.
# ============================================================

$basePath = "C:\Thomas\VIP"

# Función para escribir archivo sin BOM
function Write-FileWithoutBOM {
    param([string]$path, [string]$content)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
    Write-Host "✅ Escrito (sin BOM): $path" -ForegroundColor Green
}

# 1. gradle.properties
$content = @"
# AndroidX
android.useAndroidX=true
android.enableJetifier=true

# Suprimir advertencia de compileSdk
android.suppressUnsupportedCompileSdk=34
"@
Write-FileWithoutBOM "$basePath\gradle.properties" $content

# 2. build.gradle (proyecto)
$content = @'
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
'@
Write-FileWithoutBOM "$basePath\build.gradle" $content

# 3. app/build.gradle
$content = @'
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
'@
Write-FileWithoutBOM "$basePath\app\build.gradle" $content

# 4. settings.gradle (asegurar que no tenga BOM)
$content = @'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        maven { url 'https://jitpack.io' }
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
        maven { url 'https://jitpack.io' }
    }
}
rootProject.name = "VpnBypass"
include ':app'
'@
Write-FileWithoutBOM "$basePath\settings.gradle" $content

Write-Host "`n✅ Todos los archivos reescritos sin BOM." -ForegroundColor Green
Write-Host "Ahora haz commit y push a GitHub:" -ForegroundColor Yellow
Write-Host "  git add build.gradle app/build.gradle settings.gradle gradle.properties" -ForegroundColor Cyan
Write-Host "  git commit -m 'fix: remove BOM from gradle files'" -ForegroundColor Cyan
Write-Host "  git push origin main" -ForegroundColor Cyan