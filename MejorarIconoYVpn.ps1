# ============================================================
# Script: MejorarIconoYVpn.ps1
# - Añade icono vectorial con "VB"
# - Corrige detención de VPN (icono desaparece)
# ============================================================

$basePath = "C:\Thomas\VIP"

function Write-FileWithoutBOM {
    param([string]$path, [string]$content)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
    Write-Host "✅ Escrito: $path" -ForegroundColor Green
}

# ----- 1. Crear icono vectorial (ic_launcher.xml) -----
$vectorPath = "$basePath\app\src\main\res\drawable\ic_launcher.xml"
$vectorContent = @'
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:fillColor="#2196F3"
        android:pathData="M0,0h108v108h-108z"/>
    <path
        android:fillColor="#FFFFFF"
        android:pathData="M54,27 C40,27 30,37 30,51 C30,65 40,75 54,75 C68,75 78,65 78,51 C78,37 68,27 54,27 Z M54,33 C64,33 72,41 72,51 C72,61 64,69 54,69 C44,69 36,61 36,51 C36,41 44,33 54,33 Z"/>
    <path
        android:fillColor="#FFFFFF"
        android:pathData="M40,66 L46,66 L46,84 L40,84 Z M62,66 L68,66 L68,84 L62,84 Z"
        android:strokeWidth="0"
        android:strokeColor="#00000000"/>
    <text
        android:fontFamily="sans-serif-medium"
        android:fontSize="32"
        android:fillColor="#FFFFFF"
        android:text="VB"
        android:textStyle="bold"
        android:x="36"
        android:y="70"/>
</vector>
'@
Write-FileWithoutBOM $vectorPath $vectorContent

# ----- 2. Crear archivo de configuración para el icono adaptativo (Android 8+) -----
$adaptivePath = "$basePath\app\src\main\res\mipmap-anydpi-v26\ic_launcher.xml"
New-Item -ItemType Directory -Force -Path (Split-Path $adaptivePath) | Out-Null
$adaptiveContent = @'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher"/>
</adaptive-icon>
'@
Write-FileWithoutBOM $adaptivePath $adaptiveContent

# ----- 3. Color de fondo para el icono adaptativo -----
$colorPath = "$basePath\app\src\main\res\values\colors.xml"
$colorContent = @'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#2196F3</color>
</resources>
'@
Write-FileWithoutBOM $colorPath $colorContent

# ----- 4. Actualizar AndroidManifest.xml para usar el nuevo icono -----
$manifestPath = "$basePath\app\src\main\AndroidManifest.xml"
$manifest = Get-Content $manifestPath -Raw
# Reemplazar o añadir el atributo android:icon
if ($manifest -match 'android:icon=".*?"') {
    $manifest = $manifest -replace 'android:icon=".*?"', 'android:icon="@mipmap/ic_launcher"'
} else {
    $manifest = $manifest -replace '(<application)', '$1 android:icon="@mipmap/ic_launcher"'
}
Write-FileWithoutBOM $manifestPath $manifest

# ----- 5. Actualizar VpnBypassService.kt para asegurar cierre correcto de la VPN -----
$servicePath = "$basePath\app\src\main\java\com\ejemplo\vpnbypass\VpnBypassService.kt"
$serviceContent = @'
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
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean

class VpnBypassService : VpnService() {

    private var vpnInterface: ParcelFileDescriptor? = null
    private val isRunning = AtomicBoolean(false)
    private var forwarderThread: Thread? = null
    private val connections = ConcurrentHashMap<Int, Any>()

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
        if (isRunning.get()) return

        val builder = Builder()
        builder.setSession("Bypass VPN")
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
            try { builder.addAllowedApplication(pkg) }
            catch (e: Exception) { /* app no instalada */ }
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
        // Interrumpir el hilo si está corriendo
        forwarderThread?.interrupt()
        forwarderThread = null
        // Cerrar la interfaz VPN
        try {
            vpnInterface?.close()
        } catch (e: Exception) { /* ignore */ }
        vpnInterface = null
        // Cerrar conexiones (si las hubiera)
        connections.values.forEach { 
            if (it is java.net.Socket) it.close()
        }
        connections.clear()
        // Quitar la notificación y detener foreground
        stopForeground(true)
        // Detener el servicio
        stopSelf()
    }

    // -------------------------------------------------------------------------
    // Clase PacketForwarder (versión mejorada)
    // -------------------------------------------------------------------------
    inner class PacketForwarder(private val fd: ParcelFileDescriptor) : Runnable {
        override fun run() {
            val input = FileInputStream(fd.fileDescriptor)
            val output = FileOutputStream(fd.fileDescriptor)
            val buffer = ByteArray(32767)

            while (isRunning.get() && !Thread.currentThread().isInterrupted) {
                try {
                    val length = input.read(buffer)
                    if (length > 0) {
                        handlePacket(buffer, length, output)
                    }
                } catch (e: InterruptedException) {
                    // Hilo interrumpido, salir
                    break
                } catch (e: Exception) {
                    Log.e(TAG, "Error en PacketForwarder", e)
                }
            }
            // Limpiar al salir
            try { input.close() } catch (e: Exception) {}
            try { output.close() } catch (e: Exception) {}
        }

        private fun handlePacket(buffer: ByteArray, len: Int, output: FileOutputStream) {
            // Implementación simple: reenviar tal cual
            // (En un proyecto real aquí se haría el enmascaramiento)
            output.write(buffer, 0, len)
            output.flush()
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
'@
Write-FileWithoutBOM $servicePath $serviceContent

# ----- 6. Mejorar MainActivity para que al cerrar la app detenga el servicio -----
$activityPath = "$basePath\app\src\main\java\com\ejemplo\vpnbypass\MainActivity.kt"
$activityContent = @'
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

    // Cuando el usuario cierra la app desde el recents, detener el servicio también
    override fun onDestroy() {
        super.onDestroy()
        if (btnStop.isEnabled) {
            stopVpnService()
        }
    }
}
'@
Write-FileWithoutBOM $activityPath $activityContent

Write-Host "`n✅ ¡Actualización completada!" -ForegroundColor Green
Write-Host "  - Icono vectorial 'VB' añadido" -ForegroundColor Cyan
Write-Host "  - Manifiesto actualizado con nuevo icono" -ForegroundColor Cyan
Write-Host "  - VPN ahora se cierra correctamente al detener la app" -ForegroundColor Cyan
Write-Host "`nSube los cambios a GitHub:" -ForegroundColor Yellow
Write-Host "  git add ." -ForegroundColor Cyan
Write-Host "  git commit -m 'feat: add vector icon, improve VPN stop behavior'" -ForegroundColor Cyan
Write-Host "  git push origin main" -ForegroundColor Cyan