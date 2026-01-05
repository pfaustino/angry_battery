package com.angrybattery.angry_battery

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.BatteryManager
import android.util.Log

class BatteryBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        val batteryPct = level * 100 / scale.toFloat()
        Log.d("BatteryBroadcastReceiver", "Battery level: $batteryPct%")

        val serviceIntent = Intent(context, BatteryNotificationService::class.java).apply {
            putExtra("batteryPct", batteryPct)
        }
        context.startService(serviceIntent)
    }
}
