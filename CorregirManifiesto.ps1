# ============================================================
# Script: CorregirManifiesto.ps1
# Elimina referencia a ic_launcher faltante
# ============================================================

$basePath = "C:\Thomas\VIP"

function Write-FileWithoutBOM {
    param([string]$path, [string]$content)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
    Write-Host "✅ Escrito: $path" -ForegroundColor Green
}

$manifestPath = "$basePath\app\src\main\AndroidManifest.xml"
$content = Get-Content $manifestPath -Raw

# Elimina android:icon="@mipmap/ic_launcher" (y espacios extra)
$newContent = $content -replace 'android:icon="@mipmap/ic_launcher"\s*', ''

Write-FileWithoutBOM $manifestPath $newContent

Write-Host "`n✅ Manifiesto actualizado (icono eliminado)." -ForegroundColor Green
Write-Host "`nAhora haz commit y push:" -ForegroundColor Yellow
Write-Host "  git add app/src/main/AndroidManifest.xml" -ForegroundColor Cyan
Write-Host "  git commit -m 'fix: remove missing ic_launcher reference'" -ForegroundColor Cyan
Write-Host "  git push origin main" -ForegroundColor Cyan