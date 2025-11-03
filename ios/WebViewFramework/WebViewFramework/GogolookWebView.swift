//
//  GogolookWebViewContainer.swift
//  WebViewFramework
//
//  Created by Willy on 2025/6/7.
//

import SwiftUI

struct GogolookWebView: UIViewRepresentable {
    let url: String
    let securityConfig: WebSecurityConfig
    let webContainerConfig: WebContainerConfig
    let callback: WebBridgeCallback

    func makeUIView(context: Context) -> GogolookWebViewUIKit {
        let webViewUIKit = GogolookWebViewUIKit()
        webViewUIKit.initWebContainer(
            webSecurityConfig: securityConfig,
            webContainerConfig: webContainerConfig,
            webBridgeCallback: callback
        )
        webViewUIKit.loadUrl(url)
        return webViewUIKit
    }

    func updateUIView(_ uiView: GogolookWebViewUIKit, context: Context) {
        // 若有需要動態更新 config，可在此處 sync
    }
}
