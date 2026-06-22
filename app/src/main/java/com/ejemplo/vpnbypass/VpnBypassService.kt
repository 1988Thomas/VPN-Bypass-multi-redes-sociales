package com.ejemplo.vpnbypass

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import io.nekohasekai.sagernet.tun2socks.Tun2socks
import java.util.concurrent.atomic.AtomicBoolean

class VpnBypassService : VpnService() {

    private var vpnInterface: ParcelFileDescriptor? = null
    private val isRunning = AtomicBoolean(false)
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
        builder.setSession("Bypass VPN (SOCKS5)")
            .addAddress("192.168.1.1", 24)
            .addDnsServer("8.8.8.8")
            .addDnsServer("1.1.1.1")
            .addRoute("0.0.0.0", 0)

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
            val fdInt = fd.fileDescriptor

            // Iniciar tun2socks con el proxy SOCKS5
            // ParÃ¡metros: fileDescriptor, socks5Server, mtu, dns, timeout
            val result = Tun2socks.start(
                fdInt,
                "$proxyHost:$proxyPort",  // Servidor SOCKS5
                1500,                      // MTU
                "8.8.8.8,1.1.1.1",        // DNS
                10000                      // Timeout ms
            )

            if (result != 0) {
                Log.e(TAG, "Error al iniciar tun2socks: $result")
                stopSelf()
                return
            }

            Log.i(TAG, "tun2socks iniciado correctamente con proxy $proxyHost:$proxyPort")

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
        try {
            Tun2socks.stop()
        } catch (e: Exception) {
            Log.e(TAG, "Error deteniendo tun2socks", e)
        }
        try {
            vpnInterface?.close()
        } catch (e: Exception) {}
        vpnInterface = null
        stopForeground(true)
        stopSelf()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(CHANNEL_ID, "VPN Bypass", NotificationManager.IMPORTANCE_LOW)
            channel.description = "Redirige trÃ¡fico a travÃ©s de proxy SOCKS5"
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("VPN Bypass activa")
            .setContentText("SOCKS5: ${proxyHost}:${proxyPort}")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}