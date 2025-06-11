package com.leapcompany.tripjoy

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(null)  // ← 이 한 줄로 SplashScreen 비활성화
    }
}
