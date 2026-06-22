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
        private const val KEY_MANUAL_PROXY = "manual_proxy"
        private const val VALIDITY_DAYS = 30

        // Lista ampliada de 20 proxies fijos (actualizados manualmente)
        private val DEFAULT_PROXIES = listOf(
            "104.248.57.207:3128",
            "72.10.160.170:46155",
            "188.166.242.57:3128",
            "51.79.94.200:8080",
            "80.78.23.49:8080",
            "139.59.1.14:3128",
            "45.76.222.8:8080",
            "159.89.129.14:3128",
            "178.128.147.73:3128",
            "159.65.8.36:8080",
            "138.197.91.166:3128",
            "165.227.86.40:3128",
            "167.172.165.215:3128",
            "134.209.98.171:3128",
            "206.189.144.45:3128",
            "157.230.249.82:3128",
            "159.203.17.180:3128",
            "192.241.149.218:3128",
            "188.166.239.248:3128",
            "159.89.230.232:3128"
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

    // ----- Guardar proxy manual -----
    fun saveManualProxy(proxy: Proxy) {
        val value = "${proxy.ip}:${proxy.port}"
        prefs.edit().putString(KEY_MANUAL_PROXY, value).apply()
    }

    // ----- Obtener proxy manual guardado -----
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

    // ----- Obtener proxy funcional (manual > fijos > bÃºsqueda) -----
    suspend fun getWorkingProxy(): Proxy? {
        // 1. Probar proxy manual si existe
        getManualProxy()?.let { manual ->
            if (testProxy(manual, timeoutMs = 5000)) {
                Log.i(TAG, "Proxy manual funciona: ${manual.ip}:${manual.port}")
                return manual
            }
        }

        // 2. Probar proxies fijos guardados o por defecto
        val fixed = getFixedProxies()
        for (proxy in fixed) {
            if (testProxy(proxy, timeoutMs = 5000)) {
                Log.i(TAG, "Proxy fijo funciona: ${proxy.ip}:${proxy.port}")
                return proxy
            }
        }

        // 3. Buscar automÃ¡ticamente si todo falla
        Log.i(TAG, "Buscando proxies automÃ¡ticamente...")
        val proxies = fetchProxies(limit = 20)
        for (proxy in proxies) {
            if (testProxy(proxy, timeoutMs = 5000)) {
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
                    if (ip.isNotEmpty() && port != null) Proxy(ip, port) else null
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

    // ----- Guardar los mejores proxies -----
    private fun saveBestProxies(proxies: List<Proxy>) {
        val best = proxies.take(5).map { "${it.ip}:${it.port}" }.joinToString(",")
        prefs.edit().putString(KEY_FIXED_PROXIES, best).apply()
        prefs.edit().putLong(KEY_LAST_UPDATE, System.currentTimeMillis()).apply()
        Log.i(TAG, "Proxies fijos actualizados: $best")
    }

    // ----- Verificar renovaciÃ³n (30 dÃ­as) -----
    fun shouldRenewProxies(): Boolean {
        val lastUpdate = prefs.getLong(KEY_LAST_UPDATE, 0)
        if (lastUpdate == 0L) return true
        val cal = Calendar.getInstance()
        cal.timeInMillis = lastUpdate
        cal.add(Calendar.DAY_OF_YEAR, VALIDITY_DAYS)
        return System.currentTimeMillis() > cal.timeInMillis
    }

    // ----- Renovar proxies fijos -----
    suspend fun renewFixedProxies() {
        val proxies = fetchProxies(limit = 20)
        val working = mutableListOf<Proxy>()
        for (p in proxies) {
            if (testProxy(p, timeoutMs = 5000)) {
                working.add(p)
                if (working.size >= 5) break
            }
        }
        if (working.isNotEmpty()) saveBestProxies(working)
    }

    // ----- Obtener proxies desde fuentes (con timeout) -----
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

    // ----- Probar proxy con timeout -----
    suspend fun testProxy(proxy: Proxy, testUrl: String = "https://httpbin.org/ip", timeoutMs: Int = 5000): Boolean {
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
            Log.d(TAG, "Proxy ${proxy.ip}:${proxy.port} fallÃ³: ${e.message}")
            false
        }
    }
}