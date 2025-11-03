//
//  GogolookWebView.swift
//  WebViewFramework
//
//  Created by Willy on 2025/6/2.
//

import UIKit
import WebKit

class GogolookWebViewUIKit: UIView, GogolookWebViewContract, WKScriptMessageHandler {
    private var webView: WKWebView!
    private var webSecurityConfig: WebSecurityConfig?
    private var webContainerConfig: WebContainerConfig?
    private weak var webBridgeCallback: WebBridgeCallback?

    func initWebContainer(
        webSecurityConfig: WebSecurityConfig,
        webContainerConfig: WebContainerConfig,
        webBridgeCallback: WebBridgeCallback
    ) {
        self.webSecurityConfig = webSecurityConfig
        self.webContainerConfig = webContainerConfig
        self.webBridgeCallback = webBridgeCallback

        let contentController = WKUserContentController()
        contentController.add(self, name: "HybridAppBridge")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        webView?.removeFromSuperview()
        webView = WKWebView(frame: bounds, configuration: config)
        webView.navigationDelegate = self
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(webView)
    }

    func loadUrl(_ url: String) {
        if let url = URL(string: url) {
            webView.load(URLRequest(url: url))
        }
    }

    func syncConfigToWeb(_ config: WebContainerConfig) {
        self.webContainerConfig = config
        injectWebConfig(config)
        webView.evaluateJavaScript("window.__refreshWebContainerConfig__?.()")
    }

    func cleanUp() {
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.removeFromSuperview()
        webView.configuration.userContentController.removeAllScriptMessageHandlers()
        webView = nil

    }

    private func injectWebConfig(_ config: WebContainerConfig) {
        let js = """
        window.__WEB_CONTAINER_CONFIG__ = {
            authToken: "\(config.authToken)",
            language: "\(config.language)",
            region: "\(config.region)",
            userAgent: "\(config.userAgent)",
            profile: {
                userId: "\(config.profile.userId)",
                email: "\(config.profile.email)",
                deviceId: "\(config.profile.deviceId)"
            }
        };
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "HybridAppBridge" else { return }
        
        print("[iOS] JS 收到訊息: \(message.body)")
        print("[iOS] message.body type: \(type(of: message.body))")
        
        guard let body = message.body as? [String: Any],
              let name = body["name"] as? String else {
            print("[iOS] 無法解析 message 或缺少 name")
            return
        }
        
        switch name {
        case "closeContainer":
            print("[iOS] userContentController: closeContainer")
            webBridgeCallback?.closeContainer()
        case "openDeepLink":
            if let json = body["json"] as? [String: Any],
               let url = json["url"] as? String {
                print("[iOS] userContentController: openDeepLink: \(url)")
                webBridgeCallback?.openDeepLink(url: url)
            } else {
                print("[iOS] openDeepLink 缺少 url")
            }
        case "logEvent":
            guard let json = body["json"] as? [String: Any] else {
                print("[iOS] logEvent json 格式錯誤")
                return
            }
            let eventName = json["name"] as? String ?? "(unknown)"
            let eventData = json["data"] as? [String: Any]
            print("[iOS] userContentController: logEvent: \(eventName), data: \(String(describing: eventData))")
            webBridgeCallback?.logEvent(name: eventName, data: eventData)
        case "refreshWebContainerConfig":
            let newConfig = webBridgeCallback?.refreshWebContainerConfig() ?? webContainerConfig!
            print("[iOS] userContentController: refreshWebContainerConfig: \(newConfig)")
            syncConfigToWeb(newConfig)
        case "refreshToken":
            let newToken = webBridgeCallback?.refreshToken() ?? ""
            print("[iOS] userContentController: refreshToken: \(newToken)")
            if let existing = webContainerConfig {
                syncConfigToWeb(WebContainerConfig(
                    authToken: newToken,
                    region: existing.region,
                    language: existing.language,
                    userAgent: existing.userAgent,
                    profile: existing.profile
                ))
            }
        default:
            print("Unsupported action: \(name)")
        }
    }
}

extension GogolookWebViewUIKit: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        //TODO: Willy, 只擋第一層？
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        let host = url.host ?? ""
        if url.scheme != "https" {
            webSecurityConfig?.onBlockedDomainRequest(url.absoluteString)
            decisionHandler(.cancel)
            return
        }

        if let allowed = webSecurityConfig?.allowedDomains,
           !allowed.contains(where: { host.hasSuffix($0) }) {
            webSecurityConfig?.onBlockedDomainRequest(url.absoluteString)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let config = webContainerConfig {
            injectWebConfig(config)
        }
    }
}
