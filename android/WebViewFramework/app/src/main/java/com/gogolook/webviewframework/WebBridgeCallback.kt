package com.gogolook.webviewframework

import org.json.JSONObject

interface WebBridgeCallback {
    fun closeContainer()
    fun openDeepLink(url: String)
    fun logEvent(name: String, data: JSONObject?)//TODO: Willy, JSONObject 改為 map??? 可以討論有沒有需要
    fun refreshWebContainerConfig(): WebContainerConfig
    fun refreshToken(): String
}