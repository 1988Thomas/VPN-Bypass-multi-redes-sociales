# ============================================================
# Script: ActualizarWorkflowFinal.ps1
# Actualiza build.yml a gradle/actions/setup-gradle@v4
# ============================================================

$workflowPath = "C:\Thomas\VIP\.github\workflows\build.yml"

$newContent = @'
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
          gradle-version: '8.5'
          cache-disabled: true

      - name: Build debug APK
        run: gradle assembleDebug

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: app-debug
          path: app/build/outputs/apk/debug/app-debug.apk
'@

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($workflowPath, $newContent, $utf8NoBom)

Write-Host "✅ Archivo actualizado: $workflowPath" -ForegroundColor Green
Write-Host "`nAhora haz commit y push:" -ForegroundColor Yellow
Write-Host "  git add .github/workflows/build.yml" -ForegroundColor Cyan
Write-Host "  git commit -m 'fix: use setup-gradle@v4 and disable cache'" -ForegroundColor Cyan
Write-Host "  git push origin main" -ForegroundColor Cyan