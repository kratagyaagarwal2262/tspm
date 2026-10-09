package com.example.tspm

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var protectedBaselineStore: ProtectedBaselineStore? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        protectedBaselineStore?.close()
        protectedBaselineStore = ProtectedBaselineStore(applicationContext).also {
            it.register(flutterEngine.dartExecutor.binaryMessenger)
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        protectedBaselineStore?.close()
        protectedBaselineStore = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
