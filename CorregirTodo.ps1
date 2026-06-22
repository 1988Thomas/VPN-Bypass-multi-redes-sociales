# ============================================================
# Script: CorregirTodo.ps1
# Corrige icono, UI, y añade proxies fijos con renovación
# ============================================================

$basePath = "C:\Thomas\VIP"

function Write-FileWithoutBOM {
    param([string]$path, [string]$content)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
    Write-Host "✅ Archivo actualizado: $path" -ForegroundColor Green
}

# ------------------------------
# 1. Icono vectorial corregido
# ------------------------------
Write-FileWithoutBOM "$basePath\app\src\main\res\drawable\ic_launcher.xml" @'
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <!-- Fondo azul -->
    <path
        android:fillColor="#2196F3"
        android:pathData="M0,0h108v108h-108z"/>
    <!-- Círculo blanco interior -->
    <path
        android:fillColor="#FFFFFF"
        android:pathData="M54,27 C40,27 30,37 30,51 C30,65 40,75 54,75 C68,75 78,65 78,51 C78,37 68,27 54,27 Z"/>
    <!-- Letra V (blanca) -->
    <path
        android:fillColor="#2196F3"
        android:pathData="M35,42 L54,72 L73,42 L65,42 L54,60 L43,42 Z"/>
    <!-- Letra B (blanca) -->
    <path
        android:fillColor="#2196F3"
        android:pathData="M58,38 L58,70 L72,70 C78,70 78,62 78,58 C78,54 75,52 72,51 C76,50 78,47 78,43 C78,39 74,38 68,38 Z M63,46 L68,46 C72,46 72,48 72,50 C72,52 70,53 66,53 L63,53 Z M63,58 L70,58 C74,58 74,60 74,62 C74,64 72,65 68,65 L63,65 Z"/>
</vector>
'@

# ------------------------------
# 2. Layout mejorado (con colores)
# ------------------------------
Write-FileWithoutBOM "$basePath\app\src\main\res\layout\activity_main.xml" @'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:gravity="center"
    android:padding="24dp"
    android:background="@color/background">

    <androidx.cardview.widget.CardView
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        app:cardCornerRadius="12dp"
        app:cardElevation="8dp"
        android:layout_marginBottom="24dp">

        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:orientation="vertical"
            android:padding="24dp"
            android:background="@color/white">

            <TextView
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="VPN Bypass"
                android:textSize="28sp"
                android:textStyle="bold"
                android:textColor="@color/primary"
                android:layout_gravity="center"
                android:layout_marginBottom="8dp"/>

            <TextView
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="Facebook · Instagram · TikTok · LinkedIn"
                android:textSize="14sp"
                android:textColor="@color/secondary"
                android:layout_gravity="center"
                android:layout_marginBottom="24dp"/>

            <TextView
                android:id="@+id/txtStatus"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:text="Iniciando..."
                android:textSize="14sp"
                android:textColor="@color/primary"
                android:gravity="center"
                android:layout_marginBottom="16dp"/>

            <ProgressBar
                android:id="@+id/progressBar"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:layout_gravity="center"
                android:layout_marginBottom="16dp"
                android:visibility="gone"/>

            <Button
                android:id="@+id/btnRefresh"
                style="@style/Widget.AppCompat.Button.Colored"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:text="Buscar proxy"
                android:layout_marginBottom="12dp"
                android:backgroundTint="@color/primary"/>

            <Button
                android:id="@+id/btnStart"
                style="@style/Widget.AppCompat.Button.Colored"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:text="Activar Bypass"
                android:layout_marginBottom="12dp"
                android:backgroundTint="@color/primary"/>

            <Button
                android:id="@+id/btnStop"
                style="@style/Widget.AppCompat.Button.Colored"
                android:layout_width="match_parent"
                android:layout_height="wrap_content"
                android:text="Detener Bypass"
                android:enabled="false"
                android:backgroundTint="@color/red"/>
        </LinearLayout>
    </androidx.cardview.widget.CardView>
</LinearLayout>
'@

# ------------------------------
# 3. Colores y temas (añadir cardview)
# ------------------------------
Write-FileWithoutBOM "$basePath\app\src\main\res\values\colors.xml" @'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="primary">#2196F3</color>
    <color name="secondary">#666666</color>
    <color name="background">#F5F5F5</color>
    <color name="white">#FFFFFF</color>
    <color name="red">#F44336</color>
    <color name="ic_launcher_background">#2196F3</color>
</resources>
'@

# ------------------------------
# 4. strings.xml (sin caracteres especiales)
# ------------------------------
Write-FileWithoutBOM "$basePath\app\src\main\res\values\strings.xml" @'
<resources>
    <string name="app_name">VPN Bypass</string>
</resources>
'@

# ------------------------------
# 5. Agregar dependencia de CardView en app/build.gradle
# ------------------------------
$appGradle = Get-Content "$basePath\app\build.gradle" -Raw
if ($appGradle -notmatch "cardview") {
    $newAppGradle = $appGradle -replace '(implementation .*androidx.constraintlayout.*)', '$1' + "`n    implementation 'androidx.cardview:cardview:1.0.0'"
    Write-FileWithoutBOM "$basePath\app\build.gradle" $newAppGradle
}

# ------------------------------
# 6. ProxyManager.kt con lógica de proxies fijos + renovación
# ------------------------------
Write-FileWithoutBOM "$basePath\app\src\main\java\com\ejemplo\vpnbypass\ProxyManager.kt" @'
package com.ejemplo.vpnbypass

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import org.json.JSONArray
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.InetSocketAddress
import java.net.URL
import java.util.Calendar

class ProxyManager(context: Context) {
    companion object {
        private const val TAG = "ProxyManager"
        private const val PREFS_NAME = "proxy_prefs"
        private const val KEY_FIXED_PROXIES = "fixed_proxies"
        private const val KEY_LAST_UPDATE = "last_update"
        private const val VALIDITY_DAYS = 30

        // Lista inicial de 5 proxies gratuitos conocidos
        private val DEFAULT_PROXIES = listOf(
            "104.248.57.207:3128",
            "72.10.160.170:46155",
            "188.166.242.57:3128",
            "51.79.94.200:8080",
            "80.78.23.49:8080"
        )

        private val PROXY_SOURCES = listOf(
            "https://api.proxyscrape.com/v4/free-proxy-list/get?request=display_proxies`&proxy_format=protocolipport`&format=json",
            "https://api.proxyscrape.com/v4/free-proxy-list/get?request=display_proxies`&proxy_format=protocolipport`&format=text",
            "https://raw.githubusercontent.com/iplocate/free-proxy-list/main/protocols/http.txt",
            "https://raw.githubusercontent.com/iplocate/free-proxy-list/main/protocols/https.txt",
            "https://raw.githubusercontent.com/Thordata/awesome-free-proxy-list/main/proxies/all.txt"
        )
    }

    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    data class Proxy(val ip: String, val port: Int, val protocol: String = "http")

    // ----- Obtener proxy funcional (primero fijos, luego buscar) -----
    suspend fun getWorkingProxy(): Proxy? {
        val fixed = getFixedProxies()
        // Probar proxies fijos en orden
        for (proxy in fixed) {
            if (testProxy(proxy)) {
                Log.i(TAG, "Proxy fijo funciona: ${proxy.ip}:${proxy.port}")
                return proxy
            }
        }
        // Si todos fallan, buscar proxies automáticamente
        Log.i(TAG, "Ningún proxy fijo funciona, buscando automáticamente...")
        val proxies = fetchProxies(limit = 30)
        for (proxy in proxies) {
            if (testProxy(proxy)) {
                // Guardar como nuevo proxy fijo (renovar lista)
                saveBestProxies(proxies)
                return proxy
            }
        }
        return null
    }

    // ----- Obtener lista de proxies fijos desde SharedPreferences -----
    fun getFixedProxies(): List<Proxy> {
        val raw = prefs.getString(KEY_FIXED_PROXIES, null)
        if (raw != null) {
            val list = raw.split(",").mapNotNull {
                val parts = it.split(":")
                if (parts.size == 2) {
                    val ip = parts[0].trim()
                    val port = parts[1].trim().toIntOrNull()
                    if (ip.isNotEmpty() && port != null) Proxy(ip, port) else null
                } else null
            }
            if (list.isNotEmpty()) return list
        }
        // Si no hay guardados, usar defaults
        return DEFAULT_PROXIES.mapNotNull {
            val parts = it.split(":")
            if (parts.size == 2) {
                val ip = parts[0].trim()
                val port = parts[1].trim().toIntOrNull()
                if (ip.isNotEmpty() && port != null) Proxy(ip, port) else null
            } else null
        }
    }

    // ----- Guardar los mejores proxies como fijos -----
    private fun saveBestProxies(proxies: List<Proxy>) {
        // Tomar los primeros 5 que funcionen (se asume que ya fueron probados)
        val best = proxies.take(5).map { "${it.ip}:${it.port}" }.joinToString(",")
        prefs.edit().putString(KEY_FIXED_PROXIES, best).apply()
        prefs.edit().putLong(KEY_LAST_UPDATE, System.currentTimeMillis()).apply()
        Log.i(TAG, "Proxies fijos actualizados: $best")
    }

    // ----- Verificar si han pasado 30 días desde la última renovación -----
    fun shouldRenewProxies(): Boolean {
        val lastUpdate = prefs.getLong(KEY_LAST_UPDATE, 0)
        if (lastUpdate == 0L) return true
        val cal = Calendar.getInstance()
        cal.timeInMillis = lastUpdate
        cal.add(Calendar.DAY_OF_YEAR, VALIDITY_DAYS)
        return System.currentTimeMillis() > cal.timeInMillis
    }

    // ----- Forzar renovación de proxies fijos -----
    suspend fun renewFixedProxies() {
        val proxies = fetchProxies(limit = 30)
        val working = mutableListOf<Proxy>()
        for (p in proxies) {
            if (testProxy(p)) {
                working.add(p)
                if (working.size >= 5) break
            }
        }
        if (working.isNotEmpty()) {
            saveBestProxies(working)
        }
    }

    // ----- Obtener proxies desde fuentes -----
    suspend fun fetchProxies(limit: Int = 30, timeoutMs: Int = 8000): List<Proxy> {
        val allProxies = mutableListOf<Proxy>()
        for (source in PROXY_SOURCES) {
            try {
                val proxies = fetchFromSource(source, timeoutMs)
                allProxies.addAll(proxies)
                Log.d(TAG, "Obtenidos ${proxies.size} proxies desde $source")
                if (allProxies.size >= limit * 2) break
            } catch (e: Exception) {
                Log.e(TAG, "Error al obtener desde $source: ${e.message}")
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

    // ----- Probar proxy -----
    suspend fun testProxy(proxy: Proxy, testUrl: String = "https://httpbin.org/ip", timeoutMs: Int = 8000): Boolean {
        return try {
            val javaProxy = java.net.Proxy(java.net.Proxy.Type.HTTP, InetSocketAddress(proxy.ip, proxy.port))
            val url = URL(testUrl)
            val connection = url.openConnection(javaProxy) as HttpURLConnection
            connection.connectTimeout = timeoutMs
            connection.readTimeout = timeoutMs
            connection.connect()
            val responseCode = connection.responseCode
            connection.disconnect()
            responseCode in 200..299
        } catch (e: Exception) {
            false
        }
    }
}
'@

# ------------------------------
# 7. MainActivity.kt (con lógica de renovación y mejoras)
# ------------------------------
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
    private lateinit var proxyManager: ProxyManager
    private val scope = CoroutineScope(Dispatchers.Main + Job())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        proxyManager = ProxyManager(this)

        btnStart = findViewById(R.id.btnStart)
        btnStop = findViewById(R.id.btnStop)
        btnRefresh = findViewById(R.id.btnRefresh)
        txtStatus = findViewById(R.id.txtStatus)
        progressBar = findViewById(R.id.progressBar)

        btnRefresh.setOnClickListener { buscarProxy() }

        btnStart.setOnClickListener {
            if (currentProxy == null) {
                Toast.makeText(this, "Primero busca un proxy valido", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            val intent = VpnService.prepare(this)
            if (intent == null) startVpnService()
            else startActivityForResult(intent, 100)
        }

        btnStop.setOnClickListener { stopVpnService() }

        // Iniciar búsqueda al abrir
        buscarProxy()
    }

    private fun buscarProxy() {
        progressBar.visibility = android.view.View.VISIBLE
        txtStatus.text = "Buscando proxy..."
        btnRefresh.isEnabled = false

        scope.launch {
            // Verificar si toca renovar la lista fija
            if (proxyManager.shouldRenewProxies()) {
                txtStatus.text = "Renovando lista de proxies fijos..."
                proxyManager.renewFixedProxies()
            }

            // Obtener proxy funcional (usa fijos primero)
            val proxy = proxyManager.getWorkingProxy()

            withContext(Dispatchers.Main) {
                progressBar.visibility = android.view.View.GONE
                btnRefresh.isEnabled = true

                if (proxy != null) {
                    currentProxy = proxy
                    txtStatus.text = "Proxy activo: ${proxy.ip}:${proxy.port}"
                    Toast.makeText(
                        this@MainActivity,
                        "Proxy encontrado: ${proxy.ip}:${proxy.port}",
                        Toast.LENGTH_SHORT
                    ).show()
                } else {
                    txtStatus.text = "No se encontraron proxies funcionales"
                    Toast.makeText(
                        this@MainActivity,
                        "Intenta de nuevo mas tarde",
                        Toast.LENGTH_SHORT
                    ).show()
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

# ------------------------------
# 8. VpnBypassService.kt (sin cambios, pero lo reescribimos por si acaso)
# ------------------------------
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

# ------------------------------
# 9. Mensaje final
# ------------------------------
Write-Host ""
Write-Host "✅ TODOS LOS ARCHIVOS HAN SIDO ACTUALIZADOS." -ForegroundColor Green
Write-Host ""
Write-Host "Ahora ejecuta estos comandos para subir los cambios a GitHub:" -ForegroundColor Yellow
Write-Host "  git add ." -ForegroundColor Cyan
Write-Host "  git commit -m 'feat: fixed icon, UI, and proxy logic with fixed proxies + renewal'" -ForegroundColor Cyan
Write-Host "  git push origin main" -ForegroundColor Cyan
Write-Host ""
Write-Host "Luego ve a GitHub Actions y genera un nuevo APK." -ForegroundColor Yellow