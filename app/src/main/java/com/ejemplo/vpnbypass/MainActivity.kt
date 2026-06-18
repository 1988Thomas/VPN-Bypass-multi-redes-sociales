package com.ejemplo.vpnbypass

import android.content.Intent
import android.net.VpnService
import android.os.Bundle
import android.widget.Button
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {

    private lateinit var btnStart: Button
    private lateinit var btnStop: Button

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        btnStart = findViewById(R.id.btnStart)
        btnStop = findViewById(R.id.btnStop)

        btnStart.setOnClickListener {
            val intent = VpnService.prepare(this)
            if (intent == null) {
                startVpnService()
            } else {
                startActivityForResult(intent, 100)
            }
        }

        btnStop.setOnClickListener {
            stopVpnService()
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 100 && resultCode == RESULT_OK) {
            startVpnService()
        } else {
            Toast.makeText(this, "Permiso VPN denegado", Toast.LENGTH_SHORT).show()
        }
    }

    private fun startVpnService() {
        val intent = Intent(this, VpnBypassService::class.java)
        startForegroundService(intent)
        Toast.makeText(this, "VPN activada - Redes sociales liberadas", Toast.LENGTH_SHORT).show()
        btnStart.isEnabled = false
        btnStop.isEnabled = true
    }

    private fun stopVpnService() {
        val intent = Intent(this, VpnBypassService::class.java)
        stopService(intent)
        Toast.makeText(this, "VPN detenida - Bloqueo restaurado", Toast.LENGTH_SHORT).show()
        btnStart.isEnabled = true
        btnStop.isEnabled = false
    }
}