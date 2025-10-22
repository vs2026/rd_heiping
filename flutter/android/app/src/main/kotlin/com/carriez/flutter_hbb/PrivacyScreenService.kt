package com.carriez.flutter_hbb

import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout

/**
 * 系统级全屏隐私屏遮罩服务
 * 
 * 功能：
 * - 创建一个覆盖整个屏幕的黑色遮罩层
 * - 遮罩层会覆盖所有应用，包括主屏幕
 * - 使用系统级悬浮窗权限 (SYSTEM_ALERT_WINDOW)
 * 
 * 用途：
 * - 当被控端启用隐私屏时，防止旁边的人看到屏幕内容
 * - 只有控制端能通过远程连接看到实际画面
 */
class PrivacyScreenService : Service() {

    companion object {
        private const val TAG = "PrivacyScreenService"
        private var isRunning = false
        
        /**
         * 启动全屏遮罩
         */
        fun start(context: Context) {
            if (isRunning) {
                Log.d(TAG, "Privacy screen already running")
                return
            }
            
            val intent = Intent(context, PrivacyScreenService::class.java)
            context.startService(intent)
            Log.d(TAG, "Privacy screen service start requested")
        }
        
        /**
         * 停止全屏遮罩
         */
        fun stop(context: Context) {
            if (!isRunning) {
                Log.d(TAG, "Privacy screen not running")
                return
            }
            
            val intent = Intent(context, PrivacyScreenService::class.java)
            context.stopService(intent)
            Log.d(TAG, "Privacy screen service stop requested")
        }
        
        /**
         * 检查遮罩是否正在运行
         */
        fun isActive(): Boolean {
            return isRunning
        }
    }

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "onCreate: Creating privacy screen overlay")
        
        try {
            createOverlay()
            isRunning = true
            Log.d(TAG, "Privacy screen overlay created successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create privacy screen overlay", e)
            stopSelf()
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand: Privacy screen service started")
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "onDestroy: Removing privacy screen overlay")
        
        try {
            removeOverlay()
            isRunning = false
            Log.d(TAG, "Privacy screen overlay removed successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error removing privacy screen overlay", e)
        }
    }

    /**
     * 创建全屏黑色遮罩层
     */
    private fun createOverlay() {
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager

        // 创建一个全屏的黑色视图
        overlayView = FrameLayout(this).apply {
            setBackgroundColor(android.graphics.Color.BLACK)
            
            // 添加文字提示（可选）
            val textView = android.widget.TextView(this@PrivacyScreenService).apply {
                text = "隐私屏已启用\nPrivacy Screen Enabled"
                textSize = 24f
                setTextColor(android.graphics.Color.WHITE)
                gravity = Gravity.CENTER
            }
            addView(textView, FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            ))
        }

        // 设置窗口参数
        val layoutFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Android 8.0 及以上使用 TYPE_APPLICATION_OVERLAY
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            // 旧版本使用 TYPE_SYSTEM_ALERT
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_SYSTEM_ALERT
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,  // 宽度：填满屏幕
            WindowManager.LayoutParams.MATCH_PARENT,  // 高度：填满屏幕
            layoutFlag,                                // 窗口类型：系统级悬浮窗
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE  // 不接收焦点（不拦截触摸事件）
                    or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE  // 不接收触摸事件
                    or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN  // 覆盖整个屏幕
                    or WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED  // 锁屏时也显示
                    or WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD,  // 解除键盘锁
            PixelFormat.TRANSLUCENT                    // 支持透明度
        )

        params.gravity = Gravity.TOP or Gravity.START  // 从屏幕左上角开始
        params.x = 0
        params.y = 0

        // 添加遮罩层到窗口
        windowManager?.addView(overlayView, params)
        
        Log.d(TAG, "Overlay view added to window manager")
    }

    /**
     * 移除遮罩层
     */
    private fun removeOverlay() {
        overlayView?.let { view ->
            try {
                windowManager?.removeView(view)
                Log.d(TAG, "Overlay view removed from window manager")
            } catch (e: Exception) {
                Log.e(TAG, "Error removing view", e)
            }
        }
        
        overlayView = null
        windowManager = null
    }
}

