package com.gogolook.webviewframework

import android.content.Context
import android.util.AttributeSet
import android.util.Log
import android.webkit.JavascriptInterface
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.widget.FrameLayout
import androidx.webkit.WebViewClientCompat
import org.json.JSONException
import org.json.JSONObject

class GogolookWebViewFrameLayout @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : FrameLayout(context, attrs, defStyleAttr), GogolookWebViewContract {

    private lateinit var webView: WebView
    private var webSecurityConfig: WebSecurityConfig? = null
    private var webContainerConfig: WebContainerConfig? = null
    private var webBridgeCallback: WebBridgeCallback? = null

    override fun initWebContainer(
        webSecurityConfig: WebSecurityConfig,
        webContainerConfig: WebContainerConfig,
        webBridgeCallback: WebBridgeCallback
    ) {
        //TODO: 加入初始時間紀錄
        //TODO: 加入網頁讀取完成時間紀錄
        //TODO: performance log 交由 framework 管理，同時也開出去給 app 注入 logger 進來
        this.webSecurityConfig = webSecurityConfig
        this.webContainerConfig = webContainerConfig
        this.webBridgeCallback = webBridgeCallback

        removeAllViews()
        webView = WebView(context).apply {
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
            settings.allowFileAccess = false
            settings.allowContentAccess = false

            webViewClient = object : WebViewClientCompat() {
                override fun shouldOverrideUrlLoading(
                    view: WebView,
                    request: WebResourceRequest
                ): Boolean {
                    val url = request.url.toString()
                    val host = request.url.host ?: return true
                    //TODO: Willy, 白名單只擋第一層？？
                    //  白名單網域內的 JS 才生效
                    //  先放在 whoscall 內，之後再包裝成 lib？
                    return when {
                        request.url.scheme != "https" -> {
                            Log.w(TAG, "Blocked non-HTTPS URL: $url")
                            webSecurityConfig.onBlockedDomainRequest(url)
                            true
                        }

                        webSecurityConfig.allowedDomains.isNotEmpty()
                                && webSecurityConfig.allowedDomains.none { host.endsWith(it) } -> {
                            Log.w(TAG, "Blocked domain not in allowlist, url: $url")
                            webSecurityConfig.onBlockedDomainRequest(url)
                            true
                        }

                        else -> {
                            Log.d(TAG, "Loading URL: $url")
                            false
                        }
                    }
                }

                override fun onPageFinished(view: WebView?, url: String?) {
                    super.onPageFinished(view, url)
                    this@GogolookWebViewFrameLayout.webContainerConfig?.let {
                        injectWebConfig(it)
                    }
                }
            }

            addJavascriptInterface(object {
                @Suppress("unused")
                @JavascriptInterface
                //TODO: 考慮是否 web 會不會一直呼叫，會的話是否需要一些過濾機制
                //TODO: 限制 log event 以外的事件發送頻率
                fun postMessage(name: String, json: String) {
                    Log.d(TAG, "Bridge message, name: $name, json: $json")
                    when (name) {
                        "closeContainer" -> webBridgeCallback.closeContainer()
                        "openDeepLink" -> {
                            try {
                                val url = JSONObject(json).optString("url")
                                webBridgeCallback.openDeepLink(url)
                            } catch (e: JSONException) {
                                Log.e(TAG, "openDeepLink, parse failed", e)
                            }
                        }

                        "logEvent" -> {
                            try {
                                val obj = JSONObject(json)

                                val key = obj.optString("name")
                                if (key.length > 100) {
                                    Log.w(TAG, "logEvent name too long, dropped.")
                                    return
                                }

                                val value = obj.optJSONObject("data")
                                val dataSize = value?.toString()?.toByteArray()?.size ?: 0
                                if (dataSize > 2048) {
                                    Log.w(TAG, "logEvent payload too large, dropped.")
                                    return
                                }

                                webBridgeCallback.logEvent(key, value)
                            } catch (e: JSONException) {
                                Log.e(TAG, "logEvent, parse failed", e)
                            }
                        }

                        "refreshWebContainerConfig" -> {
                            syncConfigToWeb(webBridgeCallback.refreshWebContainerConfig())
                        }

                        "refreshToken" -> {
                            webBridgeCallback.refreshToken().let {
                                this@GogolookWebViewFrameLayout.webContainerConfig?.copy(
                                    authToken = it
                                )?.let { newConfig ->
                                    syncConfigToWeb(newConfig)
                                }
                            }
                        }

                        else -> {
                            Log.w(TAG, "Unsupported API: $name")
                        }
                    }
                }
            }, "HybridAppBridge")
        }
        addView(webView, LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
    }

    override fun loadUrl(url: String) {
        webView.loadUrl(url)
    }

    override fun syncConfigToWeb(webContainerConfig: WebContainerConfig) {
        post {
            this.webContainerConfig = webContainerConfig
            injectWebConfig(webContainerConfig)
            webView.evaluateJavascript("window.__refreshWebContainerConfig__?.()") { result ->
                Log.d(TAG, "同步完成，JS 回傳: $result")
            }
        }
    }

    override fun cleanUp() {
        webView.destroy()
    }

    private fun injectWebConfig(config: WebContainerConfig) {
        val js = buildJsInjection(config)
        webView.evaluateJavascript(js) { result ->
            Log.d(TAG, "注入完成，JS 回傳: $result")
        }
    }

    private fun buildJsInjection(config: WebContainerConfig): String {
        val profileJson = JSONObject().apply {
            put("userId", config.profile.userId)
            put("email", config.profile.email)
            put("deviceId", config.profile.deviceId)
        }

        val contextJson = JSONObject().apply {
            put("authToken", config.authToken)
            put("language", config.language)
            put("region", config.region)
            put("userAgent", config.userAgent)
            put("profile", profileJson)
        }

        return "window.__WEB_CONTAINER_CONFIG__ = $contextJson;"
    }

    companion object {
        private const val TAG = "GogolookWebView"
    }
}
