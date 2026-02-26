package lpg.ops.arungas

import android.os.Bundle
import android.os.StrictMode
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Disable StrictMode for MIUI compatibility with Google Maps
        StrictMode.setThreadPolicy(
            StrictMode.ThreadPolicy.Builder()
                .permitDiskReads()
                .permitDiskWrites()
                .build()
        )
        StrictMode.setVmPolicy(
            StrictMode.VmPolicy.Builder()
                .build()
        )

        super.onCreate(savedInstanceState)
    }
}

