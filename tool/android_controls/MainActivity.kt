package com.sharedbyatt.thaiformyanmar

import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var push: PushControls

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S || savedInstanceState != null) return

        val brandedSplash = ImageView(this).apply {
            setImageResource(R.drawable.chang_thai_splash)
            scaleType = ImageView.ScaleType.CENTER_CROP
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
            isClickable = true
        }
        addContentView(
            brandedSplash,
            ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT),
        )
        splashScreen.setOnExitAnimationListener { systemSplash ->
            systemSplash.remove()
            brandedSplash.postDelayed({
                (brandedSplash.parent as? ViewGroup)?.removeView(brandedSplash)
            }, 450)
        }
    }

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
