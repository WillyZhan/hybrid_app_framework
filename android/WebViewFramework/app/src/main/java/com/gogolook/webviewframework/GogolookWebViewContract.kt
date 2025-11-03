package com.gogolook.webviewframework

interface GogolookWebViewContract {
    fun initWebContainer(
        webSecurityConfig: WebSecurityConfig,
        webContainerConfig: WebContainerConfig,
        webBridgeCallback: WebBridgeCallback,
    )

    fun loadUrl(url: String)
    fun syncConfigToWeb(webContainerConfig: WebContainerConfig)
    fun cleanUp()
}