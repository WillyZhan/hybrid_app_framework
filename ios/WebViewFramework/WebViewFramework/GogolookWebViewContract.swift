//
//  GogolookWebContainer.swift
//  WebViewFramework
//
//  Created by Willy on 2025/5/26.
//

protocol GogolookWebViewContract: AnyObject {
    func initWebContainer(
        webSecurityConfig: WebSecurityConfig,
        webContainerConfig: WebContainerConfig,
        webBridgeCallback: WebBridgeCallback
    )
    
    func loadUrl(_ url: String)
    func syncConfigToWeb(_ config: WebContainerConfig)
    func cleanUp()
}
