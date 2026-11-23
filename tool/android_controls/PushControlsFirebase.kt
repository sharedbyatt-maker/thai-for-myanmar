package com.sharedbyatt.thaiformyanmar

import android.Manifest
import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import com.google.firebase.messaging.FirebaseMessaging
import io.flutter.plugin.common.MethodChannel

class PushControls(private val activity: Activity) {
    val available = true
    private val prefs = activity.getSharedPreferences("chang-thai-push", Context.MODE_PRIVATE)
    private val messaging get() = FirebaseMessaging.getInstance()
    private var pending: MethodChannel.Result? = null
    private val topic = "chang_thai_announcements_v1"
    private val permissionCode = 24017
    private val manager = activity.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    val enabled get() = prefs.getBoolean("enabled", false) && manager.areNotificationsEnabled()

    init {
        if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(
                NotificationChannel("chang_thai_announcements", "Chang Thai announcements", NotificationManager.IMPORTANCE_DEFAULT)
            )
        }
    }

    fun setEnabled(enable: Boolean, result: MethodChannel.Result) {
        if (pending != null) {
            result.error("PERMISSION_PENDING", "Notification permission is pending.", null)
            return
        }
        if (enable && Build.VERSION.SDK_INT >= 33 &&
            activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            pending = result
            activity.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), permissionCode)
            return
        }
        subscribe(enable, result)
    }

    fun onPermission(requestCode: Int, granted: Boolean) {
        if (requestCode != permissionCode) return
        val result = pending ?: return
        pending = null
        if (granted) subscribe(true, result) else result.success(false)
    }

    private fun subscribe(enable: Boolean, result: MethodChannel.Result) {
        val task = if (enable) {
            messaging.isAutoInitEnabled = true
            messaging.subscribeToTopic(topic)
        } else {
            messaging.unsubscribeFromTopic(topic)
        }
        task.addOnCompleteListener {
            if (it.isSuccessful) {
                prefs.edit().putBoolean("enabled", enable).apply()
                if (!enable) messaging.isAutoInitEnabled = false
                result.success(enabled)
            } else {
                result.error("FCM_UNAVAILABLE", "Unable to update notification preferences.", null)
            }
        }
    }
}
