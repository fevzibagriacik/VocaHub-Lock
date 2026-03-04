package com.example.vocat_lock

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class LockScreenService : Service() {
    private var receiver: LockScreenReceiver? = null

    override fun onCreate() {
        super.onCreate()

        // Ekran açılmasını ve kilit çözülmesini dinle
        receiver = LockScreenReceiver()
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        registerReceiver(receiver, filter)

        // Android 8.0+ için bildirim kanalı (zorunlu)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "vocat_channel",
                "Vocat Servisi",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, "vocat_channel")
            .setContentTitle("Vocat Lock Aktif")
            .setContentText("Kilit ekranında kelime bekliyor...")
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .build()

        startForeground(1, notification)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Servis öldürülürse Android tarafından otomatik yeniden başlatılır
        return START_STICKY
    }

    override fun onDestroy() {
        receiver?.let { unregisterReceiver(it) }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}