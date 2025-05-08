package com.example.aztec_dart

import android.app.Activity
import android.content.Context
import androidx.annotation.NonNull
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executor

/** AztecDartPlugin */
class AztecDartPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  private lateinit var channel : MethodChannel
  private lateinit var context: Context
  private var activity: Activity? = null
  private lateinit var executor: Executor

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.example.aztec_dart")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "getApplicationDirectory" -> {
        result.success(context.filesDir.absolutePath)
      }
      "extractLibrary" -> {
        val libraryName = call.argument<String>("libraryName")
        val directory = call.argument<String>("directory")
        
        if (libraryName == null || directory == null) {
          result.error("INVALID_ARGUMENTS", "Library name and directory must be provided", null)
          return
        }
        
        try {
          val success = NativeLibraryLoader.extractNativeLibrary(context, libraryName, directory)
          if (success) {
            result.success(null)
          } else {
            result.error("EXTRACTION_FAILED", "Failed to extract library", null)
          }
        } catch (e: Exception) {
          result.error("EXTRACTION_ERROR", e.message, e.stackTraceToString())
        }
      }
      "isBiometricAvailable" -> {
        if (activity == null) {
          result.error("ACTIVITY_UNAVAILABLE", "Activity is not available", null)
          return
        }
        
        val biometricManager = BiometricManager.from(context)
        val canAuthenticate = biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)
        
        result.success(canAuthenticate == BiometricManager.BIOMETRIC_SUCCESS)
      }
      "authenticateWithBiometrics" -> {
        if (activity == null || activity !is FragmentActivity) {
          result.error("ACTIVITY_UNAVAILABLE", "Activity is not available or not a FragmentActivity", null)
          return
        }
        
        val reason = call.argument<String>("reason") ?: "Authentication required"
        authenticateWithBiometrics(reason, result)
      }
      "getDeviceId" -> {
        result.success(SecurityUtils.getDeviceId(context))
      }
      "isDeviceRooted" -> {
        result.success(SecurityUtils.isDeviceRooted())
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun authenticateWithBiometrics(reason: String, result: Result) {
    val fragmentActivity = activity as FragmentActivity
    executor = ContextCompat.getMainExecutor(context)
    
    val promptInfo = BiometricPrompt.PromptInfo.Builder()
      .setTitle("Biometric Authentication")
      .setSubtitle(reason)
      .setNegativeButtonText("Cancel")
      .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
      .build()
    
    val biometricPrompt = BiometricPrompt(fragmentActivity, executor,
      object : BiometricPrompt.AuthenticationCallback() {
        override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
          super.onAuthenticationError(errorCode, errString)
          result.error("AUTHENTICATION_ERROR", errString.toString(), errorCode.toString())
        }

        override fun onAuthenticationSucceeded(authResult: BiometricPrompt.AuthenticationResult) {
          super.onAuthenticationSucceeded(authResult)
          result.success(true)
        }

        override fun onAuthenticationFailed() {
          super.onAuthenticationFailed()
          result.success(false)
        }
      })
    
    biometricPrompt.authenticate(promptInfo)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }
}
