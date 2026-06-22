package com.ejemplo.vpnbypass

import android.content.Intent
import android.net.VpnService
import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import kotlinx.coroutines.*

class MainActivity : AppCompatActivity() {
    private lateinit var btnStart: Button
    private lateinit var btnStop: Button
    private lateinit var btnRefresh: Button
    private lateinit var btnSetManual: Button
    private lateinit var editManualProxy: EditText
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
        btnSetManual = findViewById(R.id.btnSetManual)
        editManualProxy = findViewById(R.id.editManualProxy)
        txtStatus = findViewById(R.id.txtStatus)
        progressBar = findViewById(R.id.progressBar)

        // BotÃ³n para usar proxy manual
        btnSetManual.setOnClickListener {
            val input = editManualProxy.text.toString().trim()
            if (input.isEmpty()) {
                Toast.makeText(this, "Ingresa IP:Puerto", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            val parts = input.split(":")
            if (parts.size != 2) {
                Toast.makeText(this, "Formato incorrecto (usa IP:Puerto)", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            val ip = parts[0].trim()
            val port = parts[1].trim().toIntOrNull()
            if (ip.isEmpty() || port == null || port <= 0) {
                Toast.makeText(this, "IP o puerto invÃ¡lido", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            val proxy = ProxyManager.Proxy(ip, port)
            proxyManager.saveManualProxy(proxy)
            currentProxy = proxy
            txtStatus.text = "Proxy manual guardado: ${ip}:${port}"
            Toast.makeText(this, "Proxy manual guardado", Toast.LENGTH_SHORT).show()
        }

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

        // Iniciar bÃºsqueda automÃ¡tica
        txtStatus.text = "Iniciando..."
        buscarProxy()
    }

    private fun buscarProxy() {
        progressBar.visibility = android.view.View.VISIBLE
        txtStatus.text = "Buscando proxy..."
        btnRefresh.isEnabled = false

        scope.launch {
            try {
                // Verificar renovaciÃ³n
                if (proxyManager.shouldRenewProxies()) {
                    txtStatus.text = "Renovando lista de proxies fijos..."
                    proxyManager.renewFixedProxies()
                }

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
                            "Prueba a ingresar un proxy manualmente",
                            Toast.LENGTH_LONG
                        ).show()
                    }
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    progressBar.visibility = android.view.View.GONE
                    btnRefresh.isEnabled = true
                    txtStatus.text = "Error: ${e.message}"
                    Toast.makeText(this@MainActivity, "Error: ${e.message}", Toast.LENGTH_LONG).show()
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