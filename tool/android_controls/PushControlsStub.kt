package com.sharedbyatt.thaiformyanmar

import android.app.Activity
import io.flutter.plugin.common.MethodChannel

class PushControls(activity: Activity) {
    val available = false
    val enabled = false
    fun setEnabled(enabled: Boolean, callback: MethodChannel.Result) = callback.success(false)
    fun onPermission(requestCode: Int, granted: Boolean) = Unit
}
