package com.example.vocat_lock

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class LockScreenReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_SCREEN_ON ||
            intent.action == Intent.ACTION_USER_PRESENT) {
            // Ekran açıldığında veya kilit çözüldüğünde MainActivity'yi başlat
            val i = Intent(context, MainActivity::class.java)
            i.addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP
            )
            context.startActivity(i)
        }
    }
}