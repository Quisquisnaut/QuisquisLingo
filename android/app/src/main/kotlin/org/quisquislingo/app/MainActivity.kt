package org.quisquislingo.app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var storage: QqlStorageBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        storage = QqlStorageBridge(this).also { it.register(flutterEngine) }
    }

    @Deprecated("Flutter's embedding delivers activity results here.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (storage?.onActivityResult(requestCode, resultCode, data) == true) return
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
    }
}
