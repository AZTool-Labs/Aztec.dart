package com.example.aztec_dart

import android.content.Context
import android.os.Build
import android.provider.Settings
import java.io.File

object SecurityUtils {
    /**
     * Gets a unique device ID
     *
     * @param context The application context
     * @return A unique device ID
     */
    fun getDeviceId(context: Context): String {
        return Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID)
    }
    
    /**
     * Checks if the device is rooted
     *
     * @return true if the device is rooted, false otherwise
     */
    fun isDeviceRooted(): Boolean {
        // Check for common root management apps
        val rootApps = arrayOf(
            "com.noshufou.android.su",
            "com.noshufou.android.su.elite",
            "eu.chainfire.supersu",
            "com.koushikdutta.superuser",
            "com.thirdparty.superuser",
            "com.yellowes.su",
            "com.topjohnwu.magisk"
        )
        
        for (app in rootApps) {
            if (File("/data/app/$app").exists()) {
                return true
            }
        }
        
        // Check for su binary
        val paths = arrayOf(
            "/system/bin/su",
            "/system/xbin/su",
            "/sbin/su",
            "/system/su",
            "/system/bin/.ext/.su",
            "/system/usr/we-need-root/su-backup",
            "/system/xbin/mu"
        )
        
        for (path in paths) {
            if (File(path).exists()) {
                return true
            }
        }
        
        // Check for test-keys in build tags
        val buildTags = Build.TAGS
        if (buildTags != null && buildTags.contains("test-keys")) {
            return true
        }
        
        return false
    }
}
