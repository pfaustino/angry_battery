package com.angrybattery.angry_battery

import android.Manifest
import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Process
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.content.BroadcastReceiver
import android.content.IntentFilter
import android.app.usage.UsageEvents
import android.os.BatteryManager
import java.util.Calendar

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.angrybattery.app/battery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getBatteryUsage") {
                if (!hasUsageStatsPermission()) {
                    requestUsageStatsPermission()
                    result.error("Permission Denied", "Usage stats permission is not granted.", null)
                } else {
                    val duration = call.argument<String>("duration")
                    val startTime = call.argument<Long>("startTime")
                    val endTime = call.argument<Long>("endTime")
                    
                    val batteryUsage = getBatteryUsage(duration, startTime, endTime)
                    result.success(batteryUsage)
                }
            } else if (call.method == "getBatteryTemperature") {
                val temperature = getBatteryTemperature()
                result.success(temperature)
            } else if (call.method == "getBatteryHealth") {
                val health = getBatteryHealth()
                result.success(health)
            } else if (call.method == "getChargeCycles") {
                val cycles = getChargeCycles()
                result.success(cycles)
            } else if (call.method == "getScreenOnTime") {
                if (!hasUsageStatsPermission()) {
                    result.success(0L) // Or error, but 0 is safe for now
                } else {
                    val sot = getScreenOnTime()
                    result.success(sot)
                }
            } else {
                result.notImplemented()
            }
        }
        
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.angrybattery.app/screen_state").setStreamHandler(
            object : EventChannel.StreamHandler {
                private var receiver: BroadcastReceiver? = null

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    receiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context, intent: Intent) {
                            if (intent.action == Intent.ACTION_SCREEN_OFF) {
                                events?.success("SCREEN_OFF")
                            } else if (intent.action == Intent.ACTION_SCREEN_ON) {
                                events?.success("SCREEN_ON")
                            }
                        }
                    }
                    val filter = IntentFilter()
                    filter.addAction(Intent.ACTION_SCREEN_OFF)
                    filter.addAction(Intent.ACTION_SCREEN_ON)
                    registerReceiver(receiver, filter)
                }

                override fun onCancel(arguments: Any?) {
                    if (receiver != null) {
                        try {
                           unregisterReceiver(receiver)
                        } catch (e: Exception) {
                           // Already unregistered
                        }
                        receiver = null
                    }
                }
            }
        )
    }

    override fun onFlutterUiDisplayed() {
        super.onFlutterUiDisplayed()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) !=
                PackageManager.PERMISSION_GRANTED
            ) {
                ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1)
            }
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun requestUsageStatsPermission() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        startActivity(intent)
    }

    private fun getBatteryUsage(duration: String?, customStart: Long?, customEnd: Long?): List<Map<String, Any>> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as android.app.usage.UsageStatsManager
        
        val endTime: Long
        val startTime: Long

        if (customStart != null && customEnd != null) {
            startTime = customStart
            endTime = customEnd
        } else {
            val cal = Calendar.getInstance()
            endTime = cal.timeInMillis
            when (duration) {
                "hour" -> cal.add(Calendar.HOUR, -1)
                "day" -> cal.add(Calendar.DAY_OF_YEAR, -1)
                "week" -> cal.add(Calendar.WEEK_OF_YEAR, -1)
                else -> cal.add(Calendar.DAY_OF_YEAR, -1)
            }
            startTime = cal.timeInMillis
        }

        val queryUsageStats = usageStatsManager.queryUsageStats(android.app.usage.UsageStatsManager.INTERVAL_DAILY, startTime, endTime)

        val batteryUsageList = mutableListOf<Map<String, Any>>()
        for (usageStats in queryUsageStats) {
            val appName = try {
                packageManager.getApplicationLabel(packageManager.getApplicationInfo(usageStats.packageName, PackageManager.GET_META_DATA)).toString()
            } catch (e: PackageManager.NameNotFoundException) {
                usageStats.packageName
            }
            val usageMinutes = (usageStats.totalTimeInForeground / (1000 * 60)).toInt()

            if (usageMinutes > 0) {
                batteryUsageList.add(mapOf(
                    "appName" to appName,
                    "usage" to usageMinutes,
                    "packageName" to usageStats.packageName
                ))
            }
        }
        batteryUsageList.sortByDescending { it["usage"] as Int }

        return batteryUsageList.take(10)
    }
    private fun getBatteryTemperature(): Double {
        val intent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val temp = intent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) ?: 0
        return temp / 10.0
    }

    private fun getBatteryHealth(): String {
        val intent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val health = intent?.getIntExtra(BatteryManager.EXTRA_HEALTH, BatteryManager.BATTERY_HEALTH_UNKNOWN) ?: BatteryManager.BATTERY_HEALTH_UNKNOWN
        return when (health) {
            BatteryManager.BATTERY_HEALTH_GOOD -> "Good"
            BatteryManager.BATTERY_HEALTH_OVERHEAT -> "Overheat"
            BatteryManager.BATTERY_HEALTH_DEAD -> "Dead"
            BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE -> "Over Voltage"
            BatteryManager.BATTERY_HEALTH_UNSPECIFIED_FAILURE -> "Failed"
            BatteryManager.BATTERY_HEALTH_COLD -> "Cold"
            else -> "Unknown"
        }
    }

    private fun getChargeCycles(): Int {
        val intent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        // EXTRA_CYCLE_COUNT is API 34. For older versions, this will default to -1.
        // We use the string literal to avoid compilation issues if compiling against older SDK (though we are on 34+)
        return intent?.getIntExtra("android.os.extra.CYCLE_COUNT", -1) ?: -1
    }

    private fun getScreenOnTime(): Long {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as android.app.usage.UsageStatsManager
        val cal = Calendar.getInstance()
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        val start = cal.timeInMillis
        val end = System.currentTimeMillis()

        val events = usageStatsManager.queryEvents(start, end)
        var totalTime = 0L
        var lastOnTime: Long? = null
        val event = UsageEvents.Event()

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.SCREEN_INTERACTIVE) {
                lastOnTime = event.timeStamp
            } else if (event.eventType == UsageEvents.Event.SCREEN_NON_INTERACTIVE) {
                if (lastOnTime != null) {
                    totalTime += event.timeStamp - lastOnTime
                    lastOnTime = null
                }
            }
        }

        // If currently on
        if (lastOnTime != null) {
            totalTime += end - lastOnTime
        }

        return totalTime
    }
}
