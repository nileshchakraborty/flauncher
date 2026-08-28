package me.efesser.flauncher

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.util.Log
import android.view.KeyEvent
import android.view.accessibility.AccessibilityEvent

class HomeKeyInterceptorService : AccessibilityService() {

    private var lastRedirectTime = 0L

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.i("FLauncherBoot", "HomeKeyInterceptorService connected and active")
        serviceInfo = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or AccessibilityEvent.TYPE_WINDOWS_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REQUEST_FILTER_KEY_EVENTS or
                    AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS or
                    AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            notificationTimeout = 50
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        val packageName = event.packageName?.toString() ?: return
        val className = event.className?.toString() ?: ""

        if (packageName == "com.amazon.tv.launcher") {
            val now = System.currentTimeMillis()
            if (now - lastRedirectTime > 600) {
                lastRedirectTime = now
                Log.i("FLauncherBoot", "Amazon launcher detected ($className). Overriding to FLauncher...")
                launchFLauncher()
            }
        }
    }

    override fun onKeyEvent(event: KeyEvent?): Boolean {
        if (event != null && (event.keyCode == KeyEvent.KEYCODE_HOME || event.keyCode == KeyEvent.KEYCODE_GUIDE)) {
            if (event.action == KeyEvent.ACTION_UP) {
                Log.i("FLauncherBoot", "Intercepted KEYCODE_HOME / GUIDE. Launching FLauncher...")
                launchFLauncher()
            }
            return true
        }
        return super.onKeyEvent(event)
    }

    private fun launchFLauncher() {
        try {
            val intent = Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            startActivity(intent)
        } catch (e: Exception) {
            Log.e("FLauncherBoot", "Failed to redirect to FLauncher", e)
        }
    }

    override fun onInterrupt() {
        Log.w("FLauncherBoot", "HomeKeyInterceptorService interrupted")
    }
}
