//
//  ContentView.swift
//  WebViewFramework
//
//  Created by Willy on 2025/5/26.
//
import SwiftUI

class PreviewBridgeCallback: WebBridgeCallback {
    func closeContainer() {
        print("[iOS] closeContainer")
    }

    func openDeepLink(url: String) {
        print("[iOS] openDeepLink: \(url)")
    }

    func logEvent(name: String, data: [String : Any]?) {
        print("[iOS] logEvent: \(name), data: \(String(describing: data))")
    }

    func refreshWebContainerConfig() -> WebContainerConfig {
        print("[iOS] refreshWebContainerConfig")
        return WebContainerConfig(
            authToken: "newToken from refreshWebContainerConfig",
            region: "region",
            language: "language",
            userAgent: "userAgent",
            profile: Profile(userId: "userId", email: "email", deviceId: "deviceId")
        )
    }

    func refreshToken() -> String {
        print("[iOS] refreshToken")
        return "newToken from refreshToken"
    }
}

struct ContentView: View {
    var body: some View {
        GogolookWebView(
//            url: "http://localhost:3000",
            url: "https://whoscall.com/",
            securityConfig: WebSecurityConfig(
                allowedDomains: ["whoscall.com"],
                onBlockedDomainRequest: { url in
                    print("Blocked: \(url)")
                }
            ),
            webContainerConfig: WebContainerConfig(
                authToken: "abc123",
                region: "TW",
                language: "zh-TW",
                userAgent: "GGLHybridApp/1.0",
                profile: Profile(
                    userId: "u789",
                    email: "xx@abc.com",
                    deviceId: "device123"
                )
            ),
            callback: PreviewBridgeCallback()
        )
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    ContentView()
}
