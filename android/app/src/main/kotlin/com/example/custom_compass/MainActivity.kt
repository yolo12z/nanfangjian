package com.example.custom_compass

import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.graphics.PixelFormat
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity(), SensorEventListener {
    private val CHANNEL = "com.example.custom_compass/floating"
    private var windowManager: WindowManager? = null
    private var floatingView: View? = null
    private var pointerImageView: ImageView? = null
    private var sensorManager: SensorManager? = null
    private var orientationSensor: Sensor? = null
    private var isFloating = false

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        orientationSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        result.success(Settings.canDrawOverlays(this))
                    } else {
                        result.success(true)
                    }
                }
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                    }
                    result.success(true)
                }
                "showFloatingWindow" -> {
                    showFloat()
                    result.success(true)
                }
                "hideFloatingWindow" -> {
                    hideFloat()
                    result.success(true)
                }
                "isFloating" -> {
                    result.success(isFloating)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun showFloat() {
        if (isFloating) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            return
        }

        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            WindowManager.LayoutParams.TYPE_PHONE
        }

        // 小巧精致的悬浮窗尺寸 (约 65dp)
        val density = resources.displayMetrics.density
        val size = (68 * density).toInt()

        val params = WindowManager.LayoutParams(
            size,
            size,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = (resources.displayMetrics.widthPixels - size - (16 * density).toInt())
            y = (200 * density).toInt()
        }

        val imageView = ImageView(this).apply {
            // 从 Flutter assets 加载居中人物透明指针
            try {
                val assetKey = flutterEngine?.dartExecutor?.let {
                    // Flutter asset standard path
                }
                val inputStream = assets.open("flutter_assets/assets/images/pointer_centered.png")
                val bitmap = BitmapFactory.decodeStream(inputStream)
                setImageBitmap(bitmap)
            } catch (e: Exception) {
                setImageResource(android.R.drawable.ic_menu_compass)
            }
            scaleType = ImageView.ScaleType.FIT_CENTER
        }

        pointerImageView = imageView
        floatingView = imageView

        // 支持手指任意拖拽移动悬浮窗
        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f

        imageView.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params.x
                    initialY = params.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    params.x = initialX + (event.rawX - initialTouchX).toInt()
                    params.y = initialY + (event.rawY - initialTouchY).toInt()
                    windowManager?.updateViewLayout(floatingView, params)
                    true
                }
                else -> false
            }
        }

        windowManager?.addView(floatingView, params)
        isFloating = true

        // 注册传感器监听
        orientationSensor?.let {
            sensorManager?.registerListener(this, it, SensorManager.SENSOR_DELAY_UI)
        }
    }

    private fun hideFloat() {
        if (!isFloating) return
        sensorManager?.unregisterListener(this)
        floatingView?.let {
            windowManager?.removeView(it)
        }
        floatingView = null
        pointerImageView = null
        isFloating = false
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null || pointerImageView == null) return

        if (event.sensor.type == Sensor.TYPE_ROTATION_VECTOR) {
            val rotationMatrix = FloatArray(9)
            SensorManager.getRotationMatrixFromVector(rotationMatrix, event.values)
            val orientation = FloatArray(3)
            SensorManager.getOrientation(rotationMatrix, orientation)

            // 转化为航向角度 (0-360)
            var azimuthDeg = Math.toDegrees(orientation[0].toDouble()).toFloat()
            if (azimuthDeg < 0) azimuthDeg += 360f

            // 核心算法：原图正上方是南，地理正南相对手机顺时针偏转 (180 - heading)
            val pointerAngle = 180f - azimuthDeg
            pointerImageView?.rotation = pointerAngle
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    override fun onDestroy() {
        super.onDestroy()
        hideFloat()
    }
}
