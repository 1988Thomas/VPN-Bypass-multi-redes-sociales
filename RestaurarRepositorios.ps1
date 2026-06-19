# ============================================================
# Script: RestaurarRepositorios.ps1
# Restaura repositorios en build.gradle (proyecto)
# ============================================================

$basePath = "C:\Thomas\VIP"

function Write-FileWithoutBOM {
    param([string]$path, [string]$content)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
    Write-Host "✅ Escrito: $path" -ForegroundColor Green
}

# Construir el contenido de build.gradle con repositorios
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

Write-Host "`n✅ Archivo build.gradle restaurado con repositorios." -ForegroundColor Green
Write-Host "`nAhora haz commit y push:" -ForegroundColor Yellow
Write-Host "  git add build.gradle" -ForegroundColor Cyan
Write-Host "  git commit -m 'fix: restore repositories in build.gradle'" -ForegroundColor Cyan
Write-Host "  git push origin main" -ForegroundColor Cyan