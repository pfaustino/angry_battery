package com.angrybattery.angry_battery

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

class BatteryNotificationService : Service() {
    override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
        val batteryPct = intent.getFloatExtra("batteryPct", -1f)
        Log.d("BatteryNotificationService", "Service started with battery level: $batteryPct%")

        createNotificationChannel()
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Battery Level")
            .setContentText("Battery level: $batteryPct%")
            .setSmallIcon(R.mipmap.ic_launcher)
            .build()

        startForeground(1, notification)

        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent): IBinder? {
        return null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Battery Level"
            val descriptionText = "Shows the current battery level"
            val importance = NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    companion object {
        private const val CHANNEL_ID = "BatteryNotificationServiceChannel"
    }
}
