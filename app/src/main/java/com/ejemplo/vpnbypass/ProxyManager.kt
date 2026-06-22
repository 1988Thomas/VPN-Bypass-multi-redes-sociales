package com.ejemplo.vpnbypass

import android.util.Log
import org.json.JSONArray
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.Proxy
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
            val javaProxy = Proxy(Proxy.Type.HTTP, java.net.InetSocketAddress(proxy.ip, proxy.port))
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