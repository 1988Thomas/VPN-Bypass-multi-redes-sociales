# ============================================================
# Script: CorregirUIyProxies.ps1
# Corrige caracteres extraños y mejora búsqueda de proxies
# ============================================================

$basePath = "C:\Thomas\VIP"

function Write-FileWithoutBOM {
    param([string]$path, [string]$content)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
    Write-Host "✅ Archivo actualizado: $path" -ForegroundColor Green
}

# ----- 1. Actualizar activity_main.xml (sin emojis) -----
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
        android:text="Buscar proxy"
        android:layout_marginBottom="16dp"/>
    <Button
        android:id="@+id/btnStart"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Activar Bypass"
        android:layout_marginBottom="16dp"/>
    <Button
        android:id="@+id/btnStop"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Detener Bypass"
        android:enabled="false"/>
</LinearLayout>
'@

# ----- 2. Actualizar strings.xml -----
Write-FileWithoutBOM "$basePath\app\src\main\res\values\strings.xml" @'
<resources>
    <string name="app_name">VPN Bypass</string>
</resources>
'@

# ----- 3. Actualizar ProxyManager.kt (mejores timeouts y más fuentes) -----
Write-FileWithoutBOM "$basePath\app\src\main\java\com\ejemplo\vpnbypass\ProxyManager.kt" @'
package com.ejemplo.vpnbypass

import android.util.Log
import org.json.JSONArray
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.InetSocketAddress
import java.net.URL

class ProxyManager {
    companion object {
        private const val TAG = "ProxyManager"
        private val PROXY_SOURCES = listOf(
            // Fuentes principales (con ampersands escapados para PowerShell)
            "https://api.proxyscrape.com/v4/free-proxy-list/get?request=display_proxies`&proxy_format=protocolipport`&format=json",
            "https://api.proxyscrape.com/v4/free-proxy-list/get?request=display_proxies`&proxy_format=protocolipport`&format=text",
            "https://raw.githubusercontent.com/iplocate/free-proxy-list/main/protocols/http.txt",
            "https://raw.githubusercontent.com/iplocate/free-proxy-list/main/protocols/https.txt",
            "https://raw.githubusercontent.com/Thordata/awesome-free-proxy-list/main/proxies/all.txt",
            // Fuentes adicionales
            "https://raw.githubusercontent.com/prxchk/proxy-list/main/http.txt",
            "https://raw.githubusercontent.com/prxchk/proxy-list/main/https.txt"
        )
    }
    data class Proxy(val ip: String, val port: Int, val protocol: String = "http")
    
    suspend fun fetchProxies(limit: Int = 30, timeoutMs: Int = 8000): List<Proxy> {
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
    
    suspend fun testProxy(proxy: Proxy, testUrl: String = "https://httpbin.org/ip", timeoutMs: Int = 8000): Boolean {
        return try {
            val javaProxy = java.net.Proxy(java.net.Proxy.Type.HTTP, java.net.InetSocketAddress(proxy.ip, proxy.port))
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

# ----- 4. Actualizar MainActivity.kt para mensajes más claros -----
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
                Toast.makeText(this, "Primero busca un proxy valido", Toast.LENGTH_SHORT).show()
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
                    txtStatus.text = "No se encontraron proxies. Intenta de nuevo."
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
                    txtStatus.text = "Proxy activo: ${workingProxy.ip}:${workingProxy.port}"
                    Toast.makeText(this@MainActivity, "Proxy encontrado: ${workingProxy.ip}:${workingProxy.port}", Toast.LENGTH_SHORT).show()
                } else {
                    txtStatus.text = "Ningun proxy funciono. Intenta refrescar."
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

Write-Host ""
Write-Host "✅ Archivos actualizados correctamente." -ForegroundColor Green
Write-Host ""
Write-Host "Ahora ejecuta estos comandos para subir los cambios a GitHub:" -ForegroundColor Yellow
Write-Host "  git add app/src/main/res/layout/activity_main.xml" -ForegroundColor Cyan
Write-Host "  git add app/src/main/res/values/strings.xml" -ForegroundColor Cyan
Write-Host "  git add app/src/main/java/com/ejemplo/vpnbypass/ProxyManager.kt" -ForegroundColor Cyan
Write-Host "  git add app/src/main/java/com/ejemplo/vpnbypass/MainActivity.kt" -ForegroundColor Cyan
Write-Host "  git commit -m 'fix: remove emojis, improve proxy discovery and timeouts'" -ForegroundColor Cyan
Write-Host "  git push origin main" -ForegroundColor Cyan