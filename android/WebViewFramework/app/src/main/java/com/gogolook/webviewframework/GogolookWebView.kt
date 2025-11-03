package com.gogolook.webviewframework

import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView

@Composable
fun GogolookWebView(
    modifier: Modifier = Modifier,
    url: String,
    webSecurityConfig: WebSecurityConfig,
    webContainerConfig: WebContainerConfig,
    webBridgeCallback: WebBridgeCallback
) {
    val context = LocalContext.current
    val webViewFrameLayout = remember {
        GogolookWebViewFrameLayout(context).apply {
            initWebContainer(
                webSecurityConfig = webSecurityConfig,
                webContainerConfig = webContainerConfig,
                webBridgeCallback = webBridgeCallback
            )
            loadUrl(url)
        }
    }

    DisposableEffect(Unit) {
        onDispose {
            webViewFrameLayout.cleanUp()
        }
    }

    AndroidView(
        modifier = modifier,
        factory = { webViewFrameLayout },
    )
}
