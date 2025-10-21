package com.carriez.flutter_hbb

import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.TextView

/**
 * PrivacyOverlayManager 管理本地黑屏覆盖层
 * 
 * 该覆盖层会在 Android 设备屏幕上显示黑屏和文字,
 * 但由于使用了 FLAG_SECURE 标志,MediaProjection 不会捕获此窗口的内容,
 * 因此 PC 控制端看到的远程画面不受影响。
 */
class PrivacyOverlayManager(private val context: Context) {
    
    private val logTag = "PrivacyOverlay"
    private var overlayView: View? = null
    private var windowManager: WindowManager? = null
    private var isShowing = false

    companion object {
        // 覆盖层显示的文字
        private const val PRIVACY_TEXT = "隐私保护已开启\n\n远程桌面仍在正常运行"
    }

    /**
     * 切换覆盖层的显示状态
     */
    fun toggleOverlay() {
        if (isShowing) {
            hideOverlay()
        } else {
            showOverlay()
        }
    }

    /**
     * 显示黑屏覆盖层
     */
    fun showOverlay() {
        if (isShowing) {
            Log.d(logTag, "Overlay is already showing")
            return
        }

        try {
            windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager

            // 创建覆盖层视图
            overlayView = createOverlayView()

            // 设置窗口参数
            val params = createWindowParams()

            // 添加覆盖层到窗口
            windowManager?.addView(overlayView, params)
            isShowing = true
            Log.d(logTag, "Privacy overlay shown successfully")
        } catch (e: Exception) {
            Log.e(logTag, "Failed to show privacy overlay: ${e.message}")
            e.printStackTrace()
        }
    }

    /**
     * 隐藏黑屏覆盖层
     */
    fun hideOverlay() {
        if (!isShowing) {
            Log.d(logTag, "Overlay is not showing")
            return
        }

        try {
            overlayView?.let {
                windowManager?.removeView(it)
            }
            overlayView = null
            windowManager = null
            isShowing = false
            Log.d(logTag, "Privacy overlay hidden successfully")
        } catch (e: Exception) {
            Log.e(logTag, "Failed to hide privacy overlay: ${e.message}")
            e.printStackTrace()
        }
    }

    /**
     * 创建覆盖层视图
     */
    private fun createOverlayView(): TextView {
        val textView = TextView(context)
        textView.text = PRIVACY_TEXT
        textView.textSize = 24f
        textView.setTextColor(Color.WHITE)
        textView.gravity = Gravity.CENTER
        textView.setBackgroundColor(Color.BLACK)
        return textView
    }

    /**
     * 创建窗口参数
     * 
     * 关键点:
     * 1. FLAG_SECURE: 防止截屏和屏幕录制,MediaProjection 无法捕获此窗口
     * 2. FLAG_NOT_TOUCHABLE: 不拦截触摸事件,保证手机正常操作
     * 3. FLAG_NOT_FOCUSABLE: 不获取焦点,不影响其他应用
     * 4. FLAG_FULLSCREEN: 全屏显示
     */
    private fun createWindowParams(): WindowManager.LayoutParams {
        val layoutFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Android 8.0 及以上使用 TYPE_APPLICATION_OVERLAY
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            // Android 8.0 以下使用 TYPE_SYSTEM_ALERT
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_SYSTEM_ALERT
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            layoutFlag,
            WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_FULLSCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_SECURE,  // 关键标志:防止被 MediaProjection 捕获
            PixelFormat.TRANSLUCENT
        )

        params.gravity = Gravity.CENTER
        return params
    }

    /**
     * 检查当前状态
     */
    fun isOverlayShowing(): Boolean {
        return isShowing
    }

    /**
     * 清理资源
     */
    fun destroy() {
        hideOverlay()
    }
}

