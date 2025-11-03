//
//  WebSecurityConfig.swift
//  WebViewFramework
//
//  Created by Willy on 2025/6/2.
//

struct WebSecurityConfig {
    let allowedDomains: [String]
    let onBlockedDomainRequest: (String) -> Void
}
