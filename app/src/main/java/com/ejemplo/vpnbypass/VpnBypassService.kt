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
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetSocketAddress
import java.net.Socket
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.ConcurrentHashMap

class VpnBypassService : VpnService() {

    private var vpnInterface: ParcelFileDescriptor? = null
    private var isRunning = false
    private val connections = ConcurrentHashMap<Int, Socket>()

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

        // Filtrar apps de redes sociales
        val socialApps = listOf(
            "com.facebook.katana",
            "com.instagram.android",
            "com.zhiliaoapp.musically",
            "com.linkedin.android"
        )
        socialApps.forEach { pkg ->
            try { builder.addAllowedApplication(pkg) }
            catch (e: Exception) { /* app no instalada */ }
        }

        try {
            vpnInterface = builder.establish()
            isRunning = true
            startForeground(NOTIFICATION_ID, createNotification())

            val fd = vpnInterface ?: return
            Thread(PacketForwarder(fd)).start()
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
        connections.values.forEach { it.close() }
        connections.clear()
        vpnInterface?.close()
        vpnInterface = null
        stopForeground(true)
    }

    // -------------------------------------------------------------------------
    // Clase que lee paquetes de la interfaz virtual y los reenvÃ­a
    // -------------------------------------------------------------------------
    inner class PacketForwarder(private val fd: ParcelFileDescriptor) : Runnable {
        override fun run() {
            // Usamos fd.fileDescriptor para crear flujos
            val input = FileInputStream(fd.fileDescriptor)
            val output = FileOutputStream(fd.fileDescriptor)
            val buffer = ByteArray(32767)

            while (isRunning) {
                val length = input.read(buffer)
                if (length > 0) {
                    try {
                        handlePacket(buffer, length, output)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error manejando paquete", e)
                    }
                }
            }
        }

        private fun handlePacket(buffer: ByteArray, len: Int, output: FileOutputStream) {
            // Analizar cabecera IP (versiÃ³n 4)
            val version = buffer[0].toInt() shr 4
            if (version != 4) return

            // Determinar protocolo (TCP = 6, UDP = 17)
            val protocol = buffer[9].toInt() and 0xFF
            val ipHeaderLen = (buffer[0].toInt() and 0x0F) * 4

            if (protocol == 6) {
                // TCP: extraer puertos y reenviar
                val srcPort = ((buffer[ipHeaderLen].toInt() and 0xFF) shl 8) or (buffer[ipHeaderLen + 1].toInt() and 0xFF)
                val dstPort = ((buffer[ipHeaderLen + 2].toInt() and 0xFF) shl 8) or (buffer[ipHeaderLen + 3].toInt() and 0xFF)
                val tcpDataLen = len - ipHeaderLen - 20 // cabecera TCP mÃ­nima 20 bytes

                if (tcpDataLen > 0) {
                    // Para demostraciÃ³n, reenviamos el paquete tal cual
                    output.write(buffer, 0, len)
                } else {
                    // ACK/SYN, lo enviamos de vuelta sin modificar
                    output.write(buffer, 0, len)
                }
            } else if (protocol == 17) {
                // UDP: extraer puertos y reenviar
                val srcPort = ((buffer[ipHeaderLen].toInt() and 0xFF) shl 8) or (buffer[ipHeaderLen + 1].toInt() and 0xFF)
                val dstPort = ((buffer[ipHeaderLen + 2].toInt() and 0xFF) shl 8) or (buffer[ipHeaderLen + 3].toInt() and 0xFF)
                // Simplemente reenviamos el paquete UDP
                output.write(buffer, 0, len)
            } else {
                // Otros protocolos (ICMP, etc.) los reenviamos sin modificar
                output.write(buffer, 0, len)
            }
        }
    }

    // -------------------------------------------------------------------------
    // Notificaciones
    // -------------------------------------------------------------------------
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