package com.example.winplus

import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity : exigée par local_auth (déverrouillage par
// empreinte, fenêtre biométrique du système).
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Protection des contenus payants (visionneuse, lecteur de formation) :
        // FLAG_SECURE interdit captures et enregistrements d'écran, et masque
        // la page dans la liste des applications récentes. L'équivalent du
        // filigrane du site. Appelé par lib/widgets/protected_content.dart.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "cm.winplus/ecran")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "proteger" -> {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    "liberer" -> {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
