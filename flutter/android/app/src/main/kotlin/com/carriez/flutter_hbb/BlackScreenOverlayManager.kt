package com.carriez.flutter_hbb

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager

/**
 * 黑屏遮罩管理器
 * 用于在本地屏幕显示黑色遮罩层，阻止用户看到被操作内容
 * 但不影响远程端通过MediaProjection捕获屏幕画面
 */
class BlackScreenOverlayManager(private val context: Context) {
    private val logTag = "BlackScreenOverlay"
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var isShowing = false

    init {
        windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    }

    /**
     * 切换黑屏遮罩的显示状态
     */
    fun toggle() {
        if (isShowing) {
            hide()
        } else {
            show()
        }
    }

    /**
     * 显示黑屏遮罩
     */
    @SuppressLint("RtlHardcoded")
    fun show() {
        if (isShowing) {
            Log.d(logTag, "Black screen overlay is already showing")
            return
        }

        try {
            // 创建全屏黑色View
            overlayView = View(context).apply {
                setBackgroundColor(Color.BLACK)
            }

            // 配置WindowManager参数
            val params = WindowManager.LayoutParams().apply {
                // 设置窗口类型
                type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_SYSTEM_ALERT
                }

                // 设置窗口格式
                format = PixelFormat.TRANSLUCENT

                // 设置窗口标志
                // FLAG_NOT_FOCUSABLE: 不获取焦点,不影响其他窗口接收事件
                // FLAG_NOT_TOUCHABLE: 不接收触摸事件,触摸事件穿透到下层
                // FLAG_LAYOUT_IN_SCREEN: 允许窗口延伸到屏幕之外
                // FLAG_FULLSCREEN: 全屏显示
                flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                        WindowManager.LayoutParams.FLAG_FULLSCREEN or
                        WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS

                // 设置为全屏尺寸
                width = WindowManager.LayoutParams.MATCH_PARENT
                height = WindowManager.LayoutParams.MATCH_PARENT

                // 设置位置
                gravity = Gravity.TOP or Gravity.LEFT
                x = 0
                y = 0
            }

            // 添加View到WindowManager
            windowManager?.addView(overlayView, params)
            isShowing = true
            Log.d(logTag, "Black screen overlay shown")
        } catch (e: Exception) {
            Log.e(logTag, "Failed to show black screen overlay: ${e.message}")
            e.printStackTrace()
        }
    }

    /**
     * 隐藏黑屏遮罩
     */
    fun hide() {
        if (!isShowing) {
            Log.d(logTag, "Black screen overlay is not showing")
            return
        }

        try {
            overlayView?.let {
                windowManager?.removeView(it)
                overlayView = null
            }
            isShowing = false
            Log.d(logTag, "Black screen overlay hidden")
        } catch (e: Exception) {
            Log.e(logTag, "Failed to hide black screen overlay: ${e.message}")
            e.printStackTrace()
        }
    }

    /**
     * 检查遮罩是否正在显示
     */
    fun isOverlayShowing(): Boolean {
        return isShowing
    }

    /**
     * 释放资源
     */
    fun release() {
        hide()
        windowManager = null
    }
}

