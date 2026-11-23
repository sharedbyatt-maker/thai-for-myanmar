package com.sharedbyatt.thaiformyanmar

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var push: PushControls

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        push = PushControls(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "chang.thai/controls")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "versionCode" -> {
                        val info = packageManager.getPackageInfo(packageName, 0)
                        @Suppress("DEPRECATION")
                        result.success(if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong())
                    }
                    "notificationsAvailable" -> result.success(push.available)
                    "notificationsEnabled" -> result.success(push.enabled)
                    "setNotificationsEnabled" -> push.setEnabled(call.arguments == true, result)
                    else -> result.notImplemented()
                }
            }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (::push.isInitialized) {
            push.onPermission(requestCode, grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED)
        }
    }
}
