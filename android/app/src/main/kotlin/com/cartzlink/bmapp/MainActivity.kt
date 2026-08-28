package com.cartzlink.bmapp

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val CHANNEL    = "com.cartzlink.bmapp/call"
        const val TAG        = "MainActivity"
        const val PERM_CODE  = 100
    }

    private var methodChannel: MethodChannel? = null
    private var currentPhone   = ""

    // ─── Flutter Engine Setup ─────────────────────────────────
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                // Flutter se call karo
                "makeCall" -> {
                    val phone = call.argument<String>("phone") ?: ""
                    if (phone.isNotEmpty()) {
                        requestPermissionsAndCall(phone)
                        result.success(true)
                    } else {
                        result.error("INVALID", "Phone number empty", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestCallPermission()
    }

    // ─── Permissions ──────────────────────────────────────────
    private fun requestCallPermission() {
        if (!hasCallPermission()) {
            ActivityCompat.requestPermissions(
                this, arrayOf(Manifest.permission.CALL_PHONE), PERM_CODE
            )
        }
    }

    private fun hasCallPermission(): Boolean =
        ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) ==
                PackageManager.PERMISSION_GRANTED

    // ─── Make Call ────────────────────────────────────────────
    private fun requestPermissionsAndCall(phone: String) {
        currentPhone = phone
        if (hasCallPermission()) {
            makePhoneCall(phone)
        } else {
            requestCallPermission()
        }
    }

    private fun makePhoneCall(phone: String) {
        try {
            val clean = phone.replace(Regex("[^0-9+]"), "")
            val uri   = Uri.parse("tel:$clean")
            val intent = Intent(Intent.ACTION_CALL, uri)
            startActivity(intent)
            Log.d(TAG, "Call started: $clean")
        } catch (e: Exception) {
            Log.e(TAG, "Call error: ${e.message}")
        }
    }
}
