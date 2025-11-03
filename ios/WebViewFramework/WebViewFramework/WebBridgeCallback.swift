//
//  WebBridgeCallback.swift
//  WebViewFramework
//
//  Created by Willy on 2025/5/26.
//

protocol WebBridgeCallback: AnyObject {
    func closeContainer()
    func openDeepLink(url: String)
    func logEvent(name: String, data: [String: Any]?)
    func refreshWebContainerConfig() -> WebContainerConfig
    func refreshToken() -> String
}

