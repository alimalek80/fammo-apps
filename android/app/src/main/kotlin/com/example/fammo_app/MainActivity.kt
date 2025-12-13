package com.example.fammo_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.fragment.app.FragmentActivity
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.example.fammo_app/notifications"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Create notification channels
        createNotificationChannels()
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "createNotificationChannels" -> {
                        createNotificationChannels()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // Create default notification channel for FAMMO app
            val channelId = "fammo_notifications"
            val channelName = "FAMMO Notifications"
            val channelDescription = "Notifications for pet health, appointments, and updates"
            val importance = NotificationManager.IMPORTANCE_DEFAULT

            val channel = NotificationChannel(channelId, channelName, importance).apply {
                description = channelDescription
                enableVibration(true)
                enableLights(true)
            }

            notificationManager.createNotificationChannel(channel)

            // Create high priority channel for urgent notifications
            val urgentChannelId = "fammo_urgent"
            val urgentChannelName = "Urgent Notifications"
            val urgentChannelDescription = "Urgent notifications from FAMMO"
            val urgentImportance = NotificationManager.IMPORTANCE_HIGH

            val urgentChannel = NotificationChannel(urgentChannelId, urgentChannelName, urgentImportance).apply {
                description = urgentChannelDescription
                enableVibration(true)
                enableLights(true)
            }

            notificationManager.createNotificationChannel(urgentChannel)
        }
    }
}

