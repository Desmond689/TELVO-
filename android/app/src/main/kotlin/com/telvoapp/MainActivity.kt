package com.telvoapp

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.telvoapp/notifications"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Do not create the channel blindly on native startup. The Dart side
        // will request channel creation during app init so it runs on demand.

        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, CHANNEL).setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                if (call.method == "createNotificationChannel") {
                    val args = call.arguments as? Map<String, Any?>
                    val id = args?.get("id") as? String ?: "default_notification_channel"
                    val name = args?.get("name") as? String ?: "Default"
                    val importanceStr = args?.get("importance") as? String ?: "default"
                    val importance = if (importanceStr == "high") NotificationManager.IMPORTANCE_HIGH else NotificationManager.IMPORTANCE_DEFAULT
                    createNotificationChannel(id, name, importance)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    private fun createNotificationChannel(id: String, name: String, importance: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(id, name, importance)
            channel.description = "Default channel for app notifications"
            channel.enableVibration(true)
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}
