package com.gogolook.webviewframework

import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.gogolook.webviewframework.ui.theme.WebViewFrameworkTheme
import org.json.JSONObject

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            WebViewFrameworkTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    GogolookWebViewDemo(modifier = Modifier.padding(innerPadding))
                }
            }
        }
    }
}

@Composable
fun GogolookWebViewDemo(modifier: Modifier = Modifier) {
    val webContainerConfig = WebContainerConfig(
        authToken = "authToken",
        region = "region",
        language = "language",
        userAgent = "userAgent",
        profile = Profile(
            userId = "userId",
            email = "email",
            deviceId = "deviceId"
        )
    )

    val webSecurityConfig = WebSecurityConfig(
        allowedDomains = listOf("whoscall.com"),
        onBlockedDomainRequest = { url ->
            Log.w("GogolookWebViewDemo", "Blocked domain not in allowlist: $url")
        },
    )

    val callback = object : WebBridgeCallback {
        override fun closeContainer() {
            Log.d("WebView", "closeContainer")
        }

        override fun openDeepLink(url: String) {
            Log.d("WebView", "openDeepLink: $url")
        }

        override fun logEvent(name: String, data: JSONObject?) {
            Log.d("WebView", "logEvent: $name, data: $data")
        }

        override fun refreshWebContainerConfig(): WebContainerConfig {
            Log.d("WebView", "refreshWebContainerConfig")
            return webContainerConfig.copy(authToken = "newToken from refreshWebContainerConfig")
        }

        override fun refreshToken(): String {
            Log.d("WebView", "refreshToken")
            return "newToken from refreshToken"
        }
    }


    GogolookWebView(
//        url = "http://10.0.2.2:3000",
        url = "https://whoscall.com/",
        webSecurityConfig = webSecurityConfig,
        webContainerConfig = webContainerConfig,
        webBridgeCallback = callback,
        modifier = modifier.fillMaxSize()
    )
}
