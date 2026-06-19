# ============================================================
# Script: CrearProyectoProxy.ps1
# Crea proyecto Android con detección automática de proxies
# ============================================================
$ErrorActionPreference = "Stop"
$basePath = "C:\Thomas\VIP"
if (-not (Test-Path $basePath)) { New-Item -Path $basePath -ItemType Directory -Force | Out-Null }
Set-Location $basePath
Write-Host "Creando proyecto en: $basePath" -ForegroundColor Cyan

function Write-FileWithoutBOM {
    param([string]$path, [string]$content)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
    Write-Host "Archivo creado: $path" -ForegroundColor Green
}

# Carpetas
$folders = @(
    "$basePath\app\src\main\java\com\ejemplo\vpnbypass",
    "$basePath\app\src\main\res\layout",
    "$basePath\app\src\main\res\values",
    "$basePath\app\src\main\res\drawable",
    "$basePath\app\src\main\res\mipmap-anydpi-v26",
    "$basePath\.github\workflows"
)
foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) {
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
        Write-Host "Carpeta creada: $folder" -ForegroundColor Yellow
    }
}

# gradle.properties
Write-FileWithoutBOM "$basePath\gradle.properties" @'
# AndroidX
android.useAndroidX=true
android.enableJetifier=true
android.suppressUnsupportedCompileSdk=34
'@

# build.gradle (proyecto)
Write-FileWithoutBOM "$basePath\build.gradle" @'
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

# settings.gradle
Write-FileWithoutBOM "$basePath\settings.gradle" @'
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

# .gitignore
Write-FileWithoutBOM "$basePath\.gitignore" @'
*.iml
.gradle
/local.properties
/.idea
.DS_Store
/build
/captures
.externalNativeBuild
.cxx
local.properties
'@

# README.md
Write-FileWithoutBOM "$basePath\README.md" @'
# VPN Bypass con Proxy Automático

Aplicación Android que elude bloqueos de red usando proxies gratuitos obtenidos automáticamente.

## Características
- Busca proxies desde múltiples fuentes (ProxyScrape, IPLocate, Thordata)
- Prueba automáticamente cada proxy hasta encontrar uno funcional
- Redirige el tráfico de Facebook, Instagram, TikTok y LinkedIn
- No requiere root ni servidores externos configurados por el usuario

## Uso
1. Abre la app
2. Espera a que encuentre un proxy (puedes pulsar "Buscar proxy" manualmente)
3. Pulsa "Activar Bypass"
4. Abre las redes sociales bloqueadas
5. Pulsa "Detener Bypass" para volver al estado normal

## Nota
Los proxies gratuitos son volátiles. Si deja de funcionar, busca otro.
'@

# Workflow GitHub Actions
Write-FileWithoutBOM "$basePath\.github\workflows\build.yml" @'
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

# app/build.gradle
Write-FileWithoutBOM "$basePath\app\build.gradle" @'
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
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3'
}
'@

# AndroidManifest.xml
Write-FileWithoutBOM "$basePath\app\src\main\AndroidManifest.xml" @'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:theme="@style/Theme.AppCompat.Light"
        tools:targetApi="31">
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        <service
            android:name=".VpnBypassService"
            android:permission="android.permission.BIND_VPN_SERVICE"
            android:foregroundServiceType="dataSync"
            android:exported="false">
            <intent-filter>
                <action android:name="android.net.VpnService" />
            </intent-filter>
        </service>
    </application>
</manifest>
'@

# ProxyManager.kt (con ampersands escapados)
Write-FileWithoutBOM "$basePath\app\src\main\java\com\ejemplo\vpnbypass\ProxyManager.kt" @'
package com.ejemplo.vpnbypass

import android.util.Log
import org.json.JSONArray
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL

class ProxyManager {
    companion object {
        private const val TAG = "ProxyManager"
        private val PROXY_SOURCES = listOf(
            "https://api.proxyscrape.com/v4/free-proxy-list/get?request=display_proxies`&proxy_format=protocolipport`&format=json",
            "https://api.proxyscrape.com/v4/free-proxy-list/get?request=display_proxies`&proxy_format=protocolipport`&format=text",
            "https://raw.githubusercontent.com/iplocate/free-proxy-list/main/protocols/http.txt",
            "https://raw.githubusercontent.com/iplocate/free-proxy-list/main/protocols/https.txt",
            "https://raw.githubusercontent.com/Thordata/awesome-free-proxy-list/main/proxies/all.txt"
        )
    }
    data class Proxy(val ip: String, val port: Int, val protocol: String = "http")
    suspend fun fetchProxies(limit: Int = 20, timeoutMs: Int = 5000): List<Proxy> {
        val allProxies = mutableListOf<Proxy>()
        for (source in PROXY_SOURCES) {
            try {
                val proxies = fetchFromSource(source, timeoutMs)
                allProxies.addAll(proxies)
                Log.d(TAG, "Obtenidos ${proxies.size} proxies desde $source")
                if (allProxies.size >= limit * 2) break
            } catch (e: Exception) {
                Log.e(TAG, "Error al obtener desde ${source}: ${e.message}")
            }
        }
        return allProxies.distinctBy { "${it.ip}:${it.port}" }.take(limit)
    }
    private fun fetchFromSource(source: String, timeoutMs: Int): List<Proxy> {
        val url = URL(source)
        val connection = url.openConnection() as HttpURLConnection
        connection.connectTimeout = timeoutMs
        connection.readTimeout = timeoutMs
        connection.requestMethod = "GET"
        return try {
            val responseCode = connection.responseCode
            if (responseCode == HttpURLConnection.HTTP_OK) {
                val reader = BufferedReader(InputStreamReader(connection.inputStream))
                val response = reader.readText()
                reader.close()
                parseProxies(response, source)
            } else { emptyList() }
        } finally { connection.disconnect() }
    }
    private fun parseProxies(response: String, source: String): List<Proxy> {
        return if (response.trim().startsWith("[")) parseJsonProxies(response)
        else parseTextProxies(response)
    }
    private fun parseJsonProxies(json: String): List<Proxy> {
        val proxies = mutableListOf<Proxy>()
        try {
            val jsonArray = JSONArray(json)
            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                val protocol = obj.optString("protocol", "http").lowercase()
                val ip = obj.optString("ip", "")
                val port = obj.optInt("port", 0)
                if (ip.isNotEmpty() && port > 0) proxies.add(Proxy(ip, port, protocol))
            }
        } catch (e: Exception) { Log.e(TAG, "Error parseando JSON: ${e.message}") }
        return proxies
    }
    private fun parseTextProxies(text: String): List<Proxy> {
        val proxies = mutableListOf<Proxy>()
        val lines = text.split("\n")
        for (line in lines) {
            val trimmed = line.trim()
            if (trimmed.isEmpty() || trimmed.startsWith("#")) continue
            val parts = trimmed.split(":")
            if (parts.size >= 2) {
                val ip = parts[0].trim()
                val port = parts[1].trim().toIntOrNull()
                if (ip.isNotEmpty() && port != null && port > 0) proxies.add(Proxy(ip, port, "http"))
            }
        }
        return proxies
    }
    suspend fun testProxy(proxy: Proxy, testUrl: String = "https://httpbin.org/ip", timeoutMs: Int = 5000): Boolean {
        return try {
            val url = URL(testUrl)
            val connection = url.openConnection() as java.net.HttpURLConnection
            connection.connectTimeout = timeoutMs
            connection.readTimeout = timeoutMs
            connection.setProxy(java.net.Proxy(java.net.Proxy.Type.HTTP, java.net.InetSocketAddress(proxy.ip, proxy.port)))
            connection.connect()
            val responseCode = connection.responseCode
            connection.disconnect()
            responseCode in 200..299
        } catch (e: Exception) { false }
    }
}
'@

# VpnBypassService.kt
Write-FileWithoutBOM "$basePath\app\src\main\java\com\ejemplo\vpnbypass\VpnBypassService.kt" @'
package com.ejemplo.vpnbypass

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.ProxyInfo
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import java.io.FileInputStream
import java.io.FileOutputStream
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean

class VpnBypassService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null
    private val isRunning = AtomicBoolean(false)
    private var forwarderThread: Thread? = null
    private val connections = ConcurrentHashMap<Int, Any>()
    private var proxyHost: String = ""
    private var proxyPort: Int = 0
    companion object {
        private const val TAG = "VpnBypassService"
        private const val NOTIFICATION_ID = 1
        private const val CHANNEL_ID = "vpn_channel"
    }
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.let {
            proxyHost = it.getStringExtra("PROXY_HOST") ?: ""
            proxyPort = it.getIntExtra("PROXY_PORT", 0)
        }
        if (proxyHost.isBlank() || proxyPort == 0) {
            Log.e(TAG, "Proxy no configurado")
            stopSelf()
            return START_NOT_STICKY
        }
        startVpn()
        return START_STICKY
    }
    private fun startVpn() {
        if (isRunning.get()) return
        val builder = Builder()
        builder.setSession("Bypass VPN")
            .addAddress("192.168.1.1", 24)
            .addDnsServer("8.8.8.8")
            .addDnsServer("1.1.1.1")
            .addRoute("0.0.0.0", 0)
        val proxyInfo = ProxyInfo.buildDirectProxy(proxyHost, proxyPort)
        builder.setHttpProxy(proxyInfo)
        Log.i(TAG, "Proxy configurado: ${proxyHost}:${proxyPort}")
        val socialApps = listOf(
            "com.facebook.katana",
            "com.instagram.android",
            "com.zhiliaoapp.musically",
            "com.linkedin.android"
        )
        socialApps.forEach { pkg ->
            try { builder.addAllowedApplication(pkg) } catch (e: Exception) { /* app no instalada */ }
        }
        try {
            vpnInterface = builder.establish()
            isRunning.set(true)
            startForeground(NOTIFICATION_ID, createNotification())
            val fd = vpnInterface ?: return
            forwarderThread = Thread(PacketForwarder(fd)).apply { start() }
        } catch (e: Exception) {
            Log.e(TAG, "Error iniciando VPN", e)
            stopSelf()
        }
    }
    override fun onDestroy() {
        super.onDestroy()
        stopVpn()
    }
    private fun stopVpn() {
        isRunning.set(false)
        forwarderThread?.interrupt()
        forwarderThread = null
        try { vpnInterface?.close() } catch (e: Exception) {}
        vpnInterface = null
        connections.values.forEach { if (it is java.net.Socket) it.close() }
        connections.clear()
        stopForeground(true)
        stopSelf()
    }
    inner class PacketForwarder(private val fd: ParcelFileDescriptor) : Runnable {
        override fun run() {
            val input = FileInputStream(fd.fileDescriptor)
            val output = FileOutputStream(fd.fileDescriptor)
            val buffer = ByteArray(32767)
            while (isRunning.get() && !Thread.currentThread().isInterrupted) {
                try {
                    val length = input.read(buffer)
                    if (length > 0) { output.write(buffer, 0, length); output.flush() }
                } catch (e: InterruptedException) { break }
                catch (e: Exception) { Log.e(TAG, "Error en PacketForwarder", e) }
            }
            try { input.close() } catch (_: Exception) {}
            try { output.close() } catch (_: Exception) {}
        }
    }
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(CHANNEL_ID, "VPN Bypass", NotificationManager.IMPORTANCE_LOW)
            channel.description = "Redirige tráfico a través de proxy"
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("VPN Bypass activa")
            .setContentText("Usando proxy ${proxyHost}:${proxyPort}")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}
'@

# MainActivity.kt
Write-FileWithoutBOM "$basePath\app\src\main\java\com\ejemplo\vpnbypass\MainActivity.kt" @'
package com.ejemplo.vpnbypass

import android.content.Intent
import android.net.VpnService
import android.os.Bundle
import android.widget.Button
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import kotlinx.coroutines.*

class MainActivity : AppCompatActivity() {
    private lateinit var btnStart: Button
    private lateinit var btnStop: Button
    private lateinit var btnRefresh: Button
    private lateinit var txtStatus: TextView
    private lateinit var progressBar: ProgressBar
    private var currentProxy: ProxyManager.Proxy? = null
    private val proxyManager = ProxyManager()
    private val scope = CoroutineScope(Dispatchers.Main + Job())
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        btnStart = findViewById(R.id.btnStart)
        btnStop = findViewById(R.id.btnStop)
        btnRefresh = findViewById(R.id.btnRefresh)
        txtStatus = findViewById(R.id.txtStatus)
        progressBar = findViewById(R.id.progressBar)
        btnRefresh.setOnClickListener { buscarProxy() }
        btnStart.setOnClickListener {
            if (currentProxy == null) {
                Toast.makeText(this, "Primero busca un proxy válido", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            val intent = VpnService.prepare(this)
            if (intent == null) startVpnService()
            else startActivityForResult(intent, 100)
        }
        btnStop.setOnClickListener { stopVpnService() }
        buscarProxy()
    }
    private fun buscarProxy() {
        progressBar.visibility = android.view.View.VISIBLE
        txtStatus.text = "Buscando proxies disponibles..."
        btnRefresh.isEnabled = false
        scope.launch {
            val proxies = proxyManager.fetchProxies(limit = 30)
            if (proxies.isEmpty()) {
                withContext(Dispatchers.Main) {
                    txtStatus.text = "❌ No se encontraron proxies"
                    progressBar.visibility = android.view.View.GONE
                    btnRefresh.isEnabled = true
                }
                return@launch
            }
            var workingProxy: ProxyManager.Proxy? = null
            txtStatus.text = "Probando ${proxies.size} proxies..."
            for (proxy in proxies) {
                txtStatus.text = "Probando ${proxy.ip}:${proxy.port}..."
                if (proxyManager.testProxy(proxy)) { workingProxy = proxy; break }
            }
            withContext(Dispatchers.Main) {
                progressBar.visibility = android.view.View.GONE
                btnRefresh.isEnabled = true
                if (workingProxy != null) {
                    currentProxy = workingProxy
                    txtStatus.text = "✅ Proxy activo: ${workingProxy.ip}:${workingProxy.port}"
                    Toast.makeText(this@MainActivity, "Proxy encontrado: ${workingProxy.ip}:${workingProxy.port}", Toast.LENGTH_SHORT).show()
                } else {
                    txtStatus.text = "❌ Ningún proxy funcionó. Intenta refrescar."
                    Toast.makeText(this@MainActivity, "No se encontraron proxies funcionales", Toast.LENGTH_SHORT).show()
                }
            }
        }
    }
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 100 && resultCode == RESULT_OK) startVpnService()
        else Toast.makeText(this, "Permiso VPN denegado", Toast.LENGTH_SHORT).show()
    }
    private fun startVpnService() {
        val proxy = currentProxy ?: return
        val intent = Intent(this, VpnBypassService::class.java).apply {
            putExtra("PROXY_HOST", proxy.ip)
            putExtra("PROXY_PORT", proxy.port)
        }
        startForegroundService(intent)
        Toast.makeText(this, "VPN activada con proxy ${proxy.ip}:${proxy.port}", Toast.LENGTH_SHORT).show()
        btnStart.isEnabled = false
        btnStop.isEnabled = true
    }
    private fun stopVpnService() {
        val intent = Intent(this, VpnBypassService::class.java)
        stopService(intent)
        Toast.makeText(this, "VPN detenida", Toast.LENGTH_SHORT).show()
        btnStart.isEnabled = true
        btnStop.isEnabled = false
    }
    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
        if (btnStop.isEnabled) stopVpnService()
    }
}
'@

# activity_main.xml
Write-FileWithoutBOM "$basePath\app\src\main\res\layout\activity_main.xml" @'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:gravity="center"
    android:padding="32dp">
    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="VPN Bypass"
        android:textSize="24sp"
        android:textStyle="bold"
        android:layout_marginBottom="8dp"/>
    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Facebook · Instagram · TikTok · LinkedIn"
        android:textSize="14sp"
        android:layout_marginBottom="24dp"/>
    <TextView
        android:id="@+id/txtStatus"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Buscando proxy..."
        android:textSize="14sp"
        android:gravity="center"
        android:layout_marginBottom="16dp"/>
    <ProgressBar
        android:id="@+id/progressBar"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginBottom="16dp"
        android:visibility="gone"/>
    <Button
        android:id="@+id/btnRefresh"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="🔄 Buscar proxy"
        android:layout_marginBottom="16dp"/>
    <Button
        android:id="@+id/btnStart"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="▶ Activar Bypass"
        android:layout_marginBottom="16dp"/>
    <Button
        android:id="@+id/btnStop"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="⏹ Detener Bypass"
        android:enabled="false"/>
</LinearLayout>
'@

# strings.xml
Write-FileWithoutBOM "$basePath\app\src\main\res\values\strings.xml" @'
<resources>
    <string name="app_name">VPN Bypass</string>
</resources>
'@

# colors.xml
Write-FileWithoutBOM "$basePath\app\src\main\res\values\colors.xml" @'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#2196F3</color>
</resources>
'@

# ic_launcher.xml (drawable)
Write-FileWithoutBOM "$basePath\app\src\main\res\drawable\ic_launcher.xml" @'
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path android:fillColor="#2196F3" android:pathData="M0,0h108v108h-108z"/>
    <path android:fillColor="#FFFFFF" android:pathData="M54,27 C40,27 30,37 30,51 C30,65 40,75 54,75 C68,75 78,65 78,51 C78,37 68,27 54,27 Z M54,33 C64,33 72,41 72,51 C72,61 64,69 54,69 C44,69 36,61 36,51 C36,41 44,33 54,33 Z"/>
    <path android:fillColor="#FFFFFF" android:pathData="M40,66 L46,66 L46,84 L40,84 Z M62,66 L68,66 L68,84 L62,84 Z"/>
    <text android:fontFamily="sans-serif-medium" android:fontSize="32" android:fillColor="#FFFFFF" android:text="VB" android:textStyle="bold" android:x="36" android:y="70"/>
</vector>
'@

# ic_launcher.xml (mipmap-anydpi-v26)
Write-FileWithoutBOM "$basePath\app\src\main\res\mipmap-anydpi-v26\ic_launcher.xml" @'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher"/>
</adaptive-icon>
'@

# ============================================================
# Mensaje final (sin caracteres problemáticos)
# ============================================================
Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "PROYECTO CREADO CON EXITO" -ForegroundColor Green
Write-Host "Ruta: $basePath" -ForegroundColor Yellow
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ahora sigue estos pasos para subir a GitHub:" -ForegroundColor White
Write-Host ""
Write-Host "1. cd $basePath" -ForegroundColor Cyan
Write-Host "2. git init" -ForegroundColor Cyan
Write-Host "3. git add ." -ForegroundColor Cyan
Write-Host "4. git commit -m 'feat: VPN with automatic free proxy detection'" -ForegroundColor Cyan
Write-Host "5. git remote add origin https://github.com/tu-usuario/tu-repo.git" -ForegroundColor Cyan
Write-Host "6. git branch -M main" -ForegroundColor Cyan
Write-Host "7. git push -u origin main" -ForegroundColor Cyan
Write-Host ""
Write-Host "Luego ve a GitHub -> Actions y ejecuta el workflow 'Build APK'." -ForegroundColor Gray
Write-Host "Descarga el APK desde los artefactos." -ForegroundColor Gray
Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "La app buscará automáticamente proxies gratuitos al abrirse." -ForegroundColor Yellow
Write-Host "Si un proxy no funciona, pulsa 'Buscar proxy' para obtener otro." -ForegroundColor Yellow
Write-Host "====================================================" -ForegroundColor Cyan