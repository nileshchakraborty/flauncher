package me.efesser.flauncher

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.i("FLauncherBoot", "BootReceiver received broadcast action: $action")
        if (Intent.ACTION_BOOT_COMPLETED == action ||
            "android.intent.action.QUICKBOOT_POWERON" == action ||
            "com.htc.intent.action.QUICKBOOT_POWERON" == action ||
            Intent.ACTION_MY_PACKAGE_REPLACED == action) {
            
            val handler = Handler(Looper.getMainLooper())
            val delays = listOf(0L, 3000L, 6000L, 9000L)
            
            for (delay in delays) {
                handler.postDelayed({
                    Log.i("FLauncherBoot", "Launching MainActivity from BootReceiver (delay=${delay}ms)")
                    val launchIntent = Intent(context, MainActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    }
                    try {
                        context.startActivity(launchIntent)
                        Log.i("FLauncherBoot", "MainActivity started successfully (delay=${delay}ms)")
                    } catch (e: Exception) {
                        Log.e("FLauncherBoot", "Failed to start MainActivity at delay=${delay}ms", e)
                    }
                }, delay)
            }
        }
    }
}
