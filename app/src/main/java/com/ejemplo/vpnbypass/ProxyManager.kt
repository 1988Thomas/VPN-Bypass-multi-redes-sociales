package com.ejemplo.vpnbypass

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import org.json.JSONArray
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.InetSocketAddress
import java.net.Proxy
import java.net.URL
import java.util.Calendar

class ProxyManager(context: Context) {
    companion object {
        private const val TAG = "ProxyManager"
        private const val PREFS_NAME = "proxy_prefs"
        private const val KEY_FIXED_PROXIES = "fixed_proxies"
        private const val KEY_LAST_UPDATE = "last_update"
        private const val KEY_MANUAL_PROXY = "manual_proxy"
        private const val VALIDITY_DAYS = 30

        // Lista de proxies SOCKS5 gratuitos conocidos (actualizados manualmente con fuentes pÃºblicas)
        private val DEFAULT_PROXIES = listOf(
            "51.79.94.200:1080",    // SOCKS5
            "80.78.23.49:1080",     // SOCKS5
            "139.59.1.14:1080",     // SOCKS5
            "45.76.222.8:1080",     // SOCKS5
            "159.89.129.14:1080",   // SOCKS5
            "178.128.147.73:1080",  // SOCKS5
            "159.65.8.36:1080",     // SOCKS5
            "134.209.98.171:1080",  // SOCKS5
            "157.230.249.82:1080",  // SOCKS5
            "165.227.86.40:1080"    // SOCKS5
        )

        // Fuentes de listas de proxies SOCKS5 gratuitos
        private val PROXY_SOURCES = listOf(
            "https://raw.githubusercontent.com/iptv-org/epg/master/sites/socks5.txt",
            "https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/socks5.txt",
            "https://raw.githubusercontent.com/ShiftyTR/Proxy-List/master/socks5.txt"
        )
    }

    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    data class Proxy(val ip: String, val port: Int, val protocol: String = "socks5")

    // ----- Obtener proxy funcional -----
    suspend fun getWorkingProxy(): Proxy? {
        // 1. Probar proxy manual si existe
        getManualProxy()?.let { manual ->
            if (testProxy(manual)) {
                Log.i(TAG, "Proxy manual funciona: ${manual.ip}:${manual.port}")
                return manual
            }
        }

        // 2. Probar proxies fijos guardados o por defecto
        val fixed = getFixedProxies()
        for (proxy in fixed) {
            if (testProxy(proxy)) {
                Log.i(TAG, "Proxy fijo funciona: ${proxy.ip}:${proxy.port}")
                return proxy
            }
        }

        // 3. Buscar automÃ¡ticamente
        Log.i(TAG, "Buscando proxies SOCKS5 automÃ¡ticamente...")
        val proxies = fetchProxies(limit = 20)
        for (proxy in proxies) {
            if (testProxy(proxy)) {
                saveBestProxies(proxies)
                return proxy
            }
        }
        return null
    }

    // ----- Obtener lista de proxies fijos -----
    fun getFixedProxies(): List<Proxy> {
        val raw = prefs.getString(KEY_FIXED_PROXIES, null)
        if (raw != null) {
            val list = raw.split(",").mapNotNull {
                val parts = it.split(":")
                if (parts.size == 2) {
                    val ip = parts[0].trim()
                    val port = parts[1].trim().toIntOrNull()
                    if (ip.isNotEmpty() && port != null) Proxy(ip, port)
                    else null
                } else null
            }
            if (list.isNotEmpty()) return list
        }
        return DEFAULT_PROXIES.mapNotNull {
            val parts = it.split(":")
            if (parts.size == 2) {
                val ip = parts[0].trim()
                val port = parts[1].trim().toIntOrNull()
                if (ip.isNotEmpty() && port != null) Proxy(ip, port) else null
            } else null
        }
    }

    // ----- Guardar proxy manual -----
    fun saveManualProxy(proxy: Proxy) {
        val value = "${proxy.ip}:${proxy.port}"
        prefs.edit().putString(KEY_MANUAL_PROXY, value).apply()
    }

    fun getManualProxy(): Proxy? {
        val raw = prefs.getString(KEY_MANUAL_PROXY, null)
        if (raw != null) {
            val parts = raw.split(":")
            if (parts.size == 2) {
                val ip = parts[0].trim()
                val port = parts[1].trim().toIntOrNull()
                if (ip.isNotEmpty() && port != null) return Proxy(ip, port)
            }
        }
        return null
    }

    private fun saveBestProxies(proxies: List<Proxy>) {
        val best = proxies.take(5).map { "${it.ip}:${it.port}" }.joinToString(",")
        prefs.edit().putString(KEY_FIXED_PROXIES, best).apply()
        prefs.edit().putLong(KEY_LAST_UPDATE, System.currentTimeMillis()).apply()
        Log.i(TAG, "Proxies fijos actualizados: $best")
    }

    fun shouldRenewProxies(): Boolean {
        val lastUpdate = prefs.getLong(KEY_LAST_UPDATE, 0)
        if (lastUpdate == 0L) return true
        val cal = Calendar.getInstance()
        cal.timeInMillis = lastUpdate
        cal.add(Calendar.DAY_OF_YEAR, VALIDITY_DAYS)
        return System.currentTimeMillis() > cal.timeInMillis
    }

    suspend fun renewFixedProxies() {
        val proxies = fetchProxies(limit = 20)
        val working = mutableListOf<Proxy>()
        for (p in proxies) {
            if (testProxy(p)) {
                working.add(p)
                if (working.size >= 5) break
            }
        }
        if (working.isNotEmpty()) saveBestProxies(working)
    }

    // ----- Obtener proxies SOCKS5 desde fuentes -----
    suspend fun fetchProxies(limit: Int = 20, timeoutMs: Int = 8000): List<Proxy> {
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
                parseTextProxies(response)
            } else { emptyList() }
        } finally { connection.disconnect() }
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
                if (ip.isNotEmpty() && port != null && port > 0) {
                    proxies.add(Proxy(ip, port, "socks5"))
                }
            }
        }
        return proxies
    }

    // ----- Probar proxy SOCKS5 -----
    suspend fun testProxy(proxy: Proxy, testUrl: String = "https://httpbin.org/ip", timeoutMs: Int = 5000): Boolean {
        return try {
            val socksProxy = Proxy(Proxy.Type.SOCKS, InetSocketAddress(proxy.ip, proxy.port))
            val url = URL(testUrl)
            val connection = url.openConnection(socksProxy) as HttpURLConnection
            connection.connectTimeout = timeoutMs
            connection.readTimeout = timeoutMs
            connection.connect()
            val responseCode = connection.responseCode
            connection.disconnect()
            responseCode in 200..299
        } catch (e: Exception) {
            Log.d(TAG, "Proxy SOCKS5 ${proxy.ip}:${proxy.port} fallÃ³: ${e.message}")
            false
        }
    }
}