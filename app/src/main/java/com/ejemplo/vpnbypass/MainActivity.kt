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
                Toast.makeText(this, "Primero busca un proxy vÃ¡lido", Toast.LENGTH_SHORT).show()
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
                    txtStatus.text = "âŒ No se encontraron proxies"
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
                    txtStatus.text = "âœ… Proxy activo: ${workingProxy.ip}:${workingProxy.port}"
                    Toast.makeText(this@MainActivity, "Proxy encontrado: ${workingProxy.ip}:${workingProxy.port}", Toast.LENGTH_SHORT).show()
                } else {
                    txtStatus.text = "âŒ NingÃºn proxy funcionÃ³. Intenta refrescar."
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