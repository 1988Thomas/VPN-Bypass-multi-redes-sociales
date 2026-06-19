# ============================================================
# Script: ArreglarGradleVersion.ps1
# Actualiza gradle-version a 8.7 y limpia repositorios.
# ============================================================

$basePath = "C:\Thomas\VIP"

function Write-FileWithoutBOM {
    param([string]$path, [string]$content)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
    Write-Host "✅ Escrito: $path" -ForegroundColor Green
}

# 1. Modificar .github/workflows/build.yml para usar Gradle 8.7
$workflowPath = "$basePath\.github\workflows\build.yml"
$workflowContent = @'
name: Build APK

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v5

      - name: Set up JDK 17
        uses: actions/setup-java@v5
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Setup Gradle
        uses: gradle/actions/setup-gradle@v4
        with:
          gradle-version: '8.7'
          cache-disabled: true

      - name: Build debug APK
        run: gradle assembleDebug

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: app-debug
          path: app/build/outputs/apk/debug/app-debug.apk
'@
Write-FileWithoutBOM $workflowPath $workflowContent

# 2. Limpiar build.gradle (proyecto) eliminando repositorios redundantes
$buildGradleContent = @'
buildscript {
    ext.kotlin_version = '1.9.0'
    dependencies {
        classpath 'com.android.tools.build:gradle:8.5.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}

task clean(type: Delete) {
    delete rootProject.buildDir
}
'@
Write-FileWithoutBOM "$basePath\build.gradle" $buildGradleContent

Write-Host "`n✅ Archivos actualizados:" -ForegroundColor Green
Write-Host "  - workflow: gradle-version -> 8.7" -ForegroundColor Cyan
Write-Host "  - build.gradle (proyecto): repositorios eliminados (usamos settings.gradle)" -ForegroundColor Cyan
Write-Host "`nAhora haz commit y push:" -ForegroundColor Yellow
Write-Host "  git add .github/workflows/build.yml build.gradle" -ForegroundColor Cyan
Write-Host "  git commit -m 'fix: use Gradle 8.7 and clean project repositories'" -ForegroundColor Cyan
Write-Host "  git push origin main" -ForegroundColor Cyan