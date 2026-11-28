package com.sharedbyatt.thaiformyanmar

import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var push: PushControls
    private var showStartupArtwork = false
    private var startupArtwork: ImageView? = null
    private var artworkShownAt = 0L

    override fun onCreate(savedInstanceState: Bundle?) {
        showStartupArtwork = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && savedInstanceState == null
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S || !showStartupArtwork) return

        val artwork = ImageView(this).apply {
            setImageResource(R.drawable.chang_thai_splash)
            scaleType = ImageView.ScaleType.CENTER_CROP
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
            isClickable = true
        }
        startupArtwork = artwork
        artworkShownAt = SystemClock.uptimeMillis()
        addContentView(
            artwork,
            ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT),
        )
        splashScreen.setOnExitAnimationListener { it.remove() }
    }

    // In surface mode Flutter blocks the activity's first draw until its own
    // first frame, hiding the native artwork throughout Flutter initialization.
    override fun getRenderMode(): RenderMode =
        if (showStartupArtwork) RenderMode.texture else super.getRenderMode()

    override fun onFlutterUiDisplayed() {
        super.onFlutterUiDisplayed()
        val artwork = startupArtwork ?: return
        startupArtwork = null
        val remaining = (450L - (SystemClock.uptimeMillis() - artworkShownAt)).coerceAtLeast(0)
        artwork.postOnAnimationDelayed({
            (artwork.parent as? ViewGroup)?.removeView(artwork)
        }, remaining)
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
