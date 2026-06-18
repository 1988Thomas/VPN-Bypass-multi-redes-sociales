package com.ejemplo.vpnbypass

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import androidx.core.app.NotificationCompat
import com.ssrlive.tun2socks.Tun2socks

class VpnBypassService : VpnService() {

    private var vpnInterface: ParcelFileDescriptor? = null
    private var isRunning = false

    companion object {
        private const val NOTIFICATION_ID = 1
        private const val CHANNEL_ID = "vpn_channel"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startVpn()
        return START_STICKY
    }

    private fun startVpn() {
        if (isRunning) return

        val builder = Builder()
        builder.setSession("Bypass VPN")
            .addAddress("192.168.1.1", 24)
            .addDnsServer("8.8.8.8")
            .addDnsServer("1.1.1.1")
            .addRoute("0.0.0.0", 0)

        // 📌 LISTA DE REDES SOCIALES SOPORTADAS
        val socialApps = listOf(
            "com.facebook.katana",       // Facebook
            "com.instagram.android",     // Instagram
            "com.zhiliaoapp.musically",  // TikTok
            "com.linkedin.android"       // LinkedIn
        )

        // Añadir cada una a la VPN (si no está instalada, la ignoramos)
        socialApps.forEach { packageName ->
            try {
                builder.addAllowedApplication(packageName)
            } catch (e: Exception) {
                // La app no está instalada en el dispositivo, la omitimos
            }
        }

        try {
            vpnInterface = builder.establish()
            isRunning = true

            val fd = vpnInterface?.fileDescriptor ?: return
            val result = Tun2socks.start(
                fd,
                "8.8.8.8",
                "1.1.1.1",
                false
            )

            if (result != 0) {
                stopSelf()
                return
            }

            startForeground(NOTIFICATION_ID, createNotification())

        } catch (e: Exception) {
            e.printStackTrace()
            stopSelf()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        stopVpn()
    }

    private fun stopVpn() {
        isRunning = false
        Tun2socks.stop()
        vpnInterface?.close()
        vpnInterface = null
        stopForeground(true)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "VPN Bypass",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Mantiene la VPN activa para redes sociales"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("VPN Bypass activa")
            .setContentText("Facebook, IG, TikTok y LinkedIn liberados")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}