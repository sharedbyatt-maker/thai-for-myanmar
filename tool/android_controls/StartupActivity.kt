package com.sharedbyatt.thaiformyanmar

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.ResultReceiver
import android.view.View
import android.widget.ImageView

class StartupActivity : Activity() {
    companion object {
        const val DISPLAYED_RECEIVER = "chang.thai.startup.displayed_receiver"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        @Suppress("DEPRECATION")
        window.decorView.systemUiVisibility =
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
        val artwork = ImageView(this).apply {
            setImageResource(R.drawable.chang_thai_splash)
            scaleType = ImageView.ScaleType.CENTER_CROP
            contentDescription = "Chang Thai"
        }
        setContentView(artwork)

        // Present the native artwork before initializing the Flutter engine.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && window.decorView.isHardwareAccelerated) {
            artwork.viewTreeObserver.registerFrameCommitCallback {
                artwork.post { openMainActivity() }
            }
        } else {
            artwork.postOnAnimation { artwork.postOnAnimation { openMainActivity() } }
        }
    }

    private fun openMainActivity() {
        if (isFinishing || isDestroyed) return
        val displayed = object : ResultReceiver(Handler(Looper.getMainLooper())) {
            override fun onReceiveResult(resultCode: Int, resultData: Bundle?) {
                finish()
            }
        }
        // Keep this window visible until Flutter's first frame. MainActivity
        // uses its normal opaque Flutter surface without a starting preview.
        val main = Intent(this, MainActivity::class.java).apply {
            putExtras(this@StartupActivity.intent)
            putExtra(DISPLAYED_RECEIVER, displayed)
            addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION)
        }
        startActivity(main)
    }
}
