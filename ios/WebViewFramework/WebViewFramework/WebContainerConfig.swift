//
//  WebContainerConfig.swift
//  WebViewFramework
//
//  Created by Willy on 2025/5/26.
//
struct Profile: Codable {
    let userId: String
    let email: String
    let deviceId: String
}

struct WebContainerConfig: Codable {
    let authToken: String
    let region: String
    let language: String
    let userAgent: String
    let profile: Profile
}
