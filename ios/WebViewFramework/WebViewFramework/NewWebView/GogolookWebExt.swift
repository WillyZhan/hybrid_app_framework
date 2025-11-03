//
//  WebView+GogolookConfig.swift.swift
//  WebViewFramework
//
//  Created by Willy on 2025/10/17.
//

import SwiftUI
import WebKit

//import Foundation
//
//@available(iOS 26.0, *)
//@Observable
//class GogolookWebController {
//    // 讓 Controller 暴露 WebPage 供外部 WebView 綁定
//    let webPage = WebPage()
//    
//    // 外部必須傳入配置和 callback
//    private(set) var webContainerConfig: WebContainerConfig
//    private let webSecurityConfig: WebSecurityConfig
//    private weak var webBridgeCallback: WebBridgeCallback?
//
//    init(
//        webSecurityConfig: WebSecurityConfig,
//        webContainerConfig: WebContainerConfig,
//        webBridgeCallback: WebBridgeCallback
//    ) {
//        self.webSecurityConfig = webSecurityConfig
//        self.webContainerConfig = webContainerConfig
//        self.webBridgeCallback = webBridgeCallback
//    }
//    
//    // ... (所有 injectWebConfig, syncConfigToWeb, handleWebMessage, decidePolicy 邏輯保持不變) ...
//
//    // 唯一的區別是：我們不再有 load(url:) 方法，因為 URL 會直接從頂層的 WebView(url:) 傳入
//    // 但為了保持邏輯一致性，我們需要一個函數在載入完成後觸發配置注入
//    
//    // 網頁載入完成後觸發配置注入 (取代舊的 didFinish)
//    func injectConfigOnLoad() async {
//        // 確保配置存在且是在主框架載入完成時
//        if let config = webContainerConfig {
//            await injectWebConfig()
//        }
//    }
//}
//
//// 讓 GogolookWebController 可以作為環境物件傳遞
//struct GogolookWebControllerKey: EnvironmentKey {
//    static let defaultValue: GogolookWebController? = nil
//}
//
//extension EnvironmentValues {
//    var gogolookWebController: GogolookWebController? {
//        get { self[GogolookWebControllerKey.self] }
//        set { self[GogolookWebControllerKey.self] = newValue }
//    }
//}
//
//@available(iOS 26.0, *)
//extension WebKit.WebView {
//    
//    // MARK: - 主要配置 Modifier (取代 init)
//    
//    /// 配置 WebView 的所有 Gogolook 特定功能 (安全、橋接、初始載入)
//    /// - Parameter controller: 已初始化並持有所有配置的 Controller 實例。
//    public func gogolookConfig(using controller: GogolookWebController) -> some View {
//        self
//            // ----------------------------------------------------
//            // 1. Navigation/Security Modifier (取代 WKNavigationDelegate)
//            // ----------------------------------------------------
//            .onNavigationAction { action in
//                // 使用 Controller 的決策邏輯
//                controller.decidePolicy(for: action)
//            }
//            
//            // ----------------------------------------------------
//            // 2. JS Bridge (Web -> App) Modifier (取代 WKScriptMessageHandler)
//            // ----------------------------------------------------
//            // 註冊 JS Bridge 名稱
//            .onScriptMessage("HybridAppBridge") { message in
//                Task {
//                    await controller.handleWebMessage(message)
//                }
//            }
//            
//            // ----------------------------------------------------
//            // 3. Config Injection (取代 didFinish)
//            // ----------------------------------------------------
//            .onPageCompletion {
//                Task {
//                    // 網頁載入完成後，執行配置注入
//                    await controller.injectConfigOnLoad()
//                }
//            }
//            // 4. 將 Controller 放入環境中，供其他 Modifier 使用
//            .environment(\.gogolookWebController, controller)
//    }
//    
//    // MARK: - 次要控制 Modifier (範例：啟用滾動)
//
//    /// 啟用或禁用 Web View 的滾動
//    public func enableWebViewScrolling(_ enabled: Bool) -> some View {
//        // 假設 WebView 本身有一個內建 Modifier 來控制此行為
//        self.scrollDisabled(!enabled)
//    }
//}


@available(iOS 26.0, *)
extension WebKit.WebView {
    func gogolookContainer(
        config: WebContainerConfig,
        security: WebSecurityConfig,
        callback: WebBridgeCallback
    ) -> some View {
        //modifier(GogolookWebContainerModifier(config: config, security: security, callback: callback))
        self.onNavigationAction { _ in
            
        }
    }
}


private struct GogolookWebContainerModifier: ViewModifier {
    let config: WebContainerConfig
    let security: WebSecurityConfig
    weak var callback: WebBridgeCallback?

    func body(content: Content) -> some View {
        content

            // 1) atDocumentStart 注入「初始」Config（安全：用 JSONEncoder）
//            .configureWebView { webView in
//                webView.configuration.userContentController
//                    .addUserScript(makeBootstrapConfigScript(config))
//            }
            // 如果你的 SDK 沒有 .configureWebView，改用下面這行（把上面的註解掉）：
             .webViewConfiguration { cfg in cfg.userContentController.addUserScript(makeBootstrapConfigScript(config)) }

//             .background(_GGLIntrospectWebView { webView in
//                 webView.configuration.userContentController
//                     .addUserScript(makeBootstrapConfigScript(config))
//             })

            // 2) 只針對「主框架導覽」限制 https + allowlist
            .onNavigationAction { action in
                guard let url = action.request.url else { action.cancel(); return }
                guard action.isMainFrame else { action.allow(); return }

                let scheme = (url.scheme ?? "").lowercased()
                if scheme != "https" {
                    security.onBlockedDomainRequest(url.absoluteString)
                    action.cancel(); return
                }
                if !security.allowedDomains.isEmpty {
                    let host = (url.host ?? "").lowercased()
                    let allowed = security.allowedDomains.contains { allow in
                        let a = allow.lowercased()
                        return host == a || host.hasSuffix("." + a)
                    }
                    if !allowed {
                        security.onBlockedDomainRequest(url.absoluteString)
                        action.cancel(); return
                    }
                }
                action.allow()
            }

            // 3) JS → Native：固定 5 個事件，嚴格對齊你原本的 WebBridgeCallback
            .onScriptMessage("HybridAppBridge") { message in
                guard let body = message.body as? [String: Any],
                      let name = body["name"] as? String else { return }

                // 基本防護（與 Android 同思路）
                if name.count > 100 { return }
                let json = body["json"] ?? [:]
                if let data = try? JSONSerialization.data(withJSONObject: json),
                   data.count > 2048 { return }

                switch name {

                case "closeContainer":
                    callback?.closeContainer()

                case "openDeepLink":
                    // 對齊你的簽名：傳入 String，而非 URL
                    guard let dict = json as? [String: Any],
                          let s = dict["url"] as? String else { return }
                    callback?.openDeepLink(url: s)

                case "logEvent":
                    guard let dict = json as? [String: Any],
                          let rawName = dict["name"] as? String
                    else { return }
                    let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    let evtName = String(trimmed.prefix(100))
                    let evtData = dict["data"] as? [String: Any]
                    callback?.logEvent(name: evtName, data: evtData)

                case "refreshWebContainerConfig":
                    // 取回「最新」Config，覆蓋到 window.__WEB_CONTAINER_CONFIG__，然後呼叫 refresh()
                    guard let newCfg = callback?.refreshWebContainerConfig(),
                          let wv = message.webView else { return }
                    let js = makePatchConfigAndRefreshJS(newConfig: newCfg)
                    wv.evaluateJavaScript(js, completionHandler: nil)

                case "refreshToken":
                    // 取回「最新 token」，只更新 authToken 欄位，然後 refresh()
                    guard let newToken = callback?.refreshToken(),
                          let wv = message.webView else { return }
                    let js = """
                    (function(){
                      if (window.__WEB_CONTAINER_CONFIG__) {
                        window.__WEB_CONTAINER_CONFIG__.authToken = \(jsString(newToken));
                        if (typeof window.__refreshWebContainerConfig__ === 'function') { window.__refreshWebContainerConfig__(); }
                      }
                    })();
                    """
                    wv.evaluateJavaScript(js, completionHandler: nil)

                default:
                    // 未支援事件名：忽略或印 debug
                    break
                }
            }
    }

    // MARK: - Helpers

    private func makeBootstrapConfigScript(_ config: WebContainerConfig) -> WKUserScript {
        let json = encodeJSON(config)
        let src = """
        (function(){
          window.__WEB_CONTAINER_CONFIG__ = \(json);
          window.__refreshWebContainerConfig__ = function(){};
        })();
        """
        return WKUserScript(source: src, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }

    private func makePatchConfigAndRefreshJS(newConfig: WebContainerConfig) -> String {
        let json = encodeJSON(newConfig)
        return """
        (function(){
          window.__WEB_CONTAINER_CONFIG__ = \(json);
          if (typeof window.__refreshWebContainerConfig__ === 'function') { window.__refreshWebContainerConfig__(); }
        })();
        """
    }

    private func encodeJSON<T: Encodable>(_ value: T) -> String {
        let data = (try? JSONEncoder().encode(value)) ?? Data("{}".utf8)
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    private func jsString(_ s: String) -> String {
        // 安全地把 Swift String 轉為 JS 字串常值
        let escaped = s
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
        return "'\(escaped)'"
    }
}
