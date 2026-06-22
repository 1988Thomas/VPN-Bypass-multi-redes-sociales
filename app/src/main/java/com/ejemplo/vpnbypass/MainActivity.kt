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

        // Iniciar bÃºsqueda al abrir
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