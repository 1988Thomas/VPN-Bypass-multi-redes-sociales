package com.ejemplo.vpnbypass

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.ProxyInfo
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import java.io.FileInputStream
import java.io.FileOutputStream
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean

class VpnBypassService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null
    private val isRunning = AtomicBoolean(false)
    private var forwarderThread: Thread? = null
    private val connections = ConcurrentHashMap<Int, Any>()
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
        builder.setSession("Bypass VPN")
            .addAddress("192.168.1.1", 24)
            .addDnsServer("8.8.8.8")
            .addDnsServer("1.1.1.1")
            .addRoute("0.0.0.0", 0)
        val proxyInfo = ProxyInfo.buildDirectProxy(proxyHost, proxyPort)
        builder.setHttpProxy(proxyInfo)
        Log.i(TAG, "Proxy configurado: ${proxyHost}:${proxyPort}")
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
            forwarderThread = Thread(PacketForwarder(fd)).apply { start() }
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
        forwarderThread?.interrupt()
        forwarderThread = null
        try { vpnInterface?.close() } catch (e: Exception) {}
        vpnInterface = null
        connections.values.forEach { if (it is java.net.Socket) it.close() }
        connections.clear()
        stopForeground(true)
        stopSelf()
    }
    inner class PacketForwarder(private val fd: ParcelFileDescriptor) : Runnable {
        override fun run() {
            val input = FileInputStream(fd.fileDescriptor)
            val output = FileOutputStream(fd.fileDescriptor)
            val buffer = ByteArray(32767)
            while (isRunning.get() && !Thread.currentThread().isInterrupted) {
                try {
                    val length = input.read(buffer)
                    if (length > 0) { output.write(buffer, 0, length); output.flush() }
                } catch (e: InterruptedException) { break }
                catch (e: Exception) { Log.e(TAG, "Error en PacketForwarder", e) }
            }
            try { input.close() } catch (_: Exception) {}
            try { output.close() } catch (_: Exception) {}
        }
    }
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(CHANNEL_ID, "VPN Bypass", NotificationManager.IMPORTANCE_LOW)
            channel.description = "Redirige trÃ¡fico a travÃ©s de proxy"
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("VPN Bypass activa")
            .setContentText("Usando proxy ${proxyHost}:${proxyPort}")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}