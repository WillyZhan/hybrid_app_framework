package com.gogolook.webviewframework

data class WebSecurityConfig(
    val allowedDomains: List<String> = emptyList(),
    val onBlockedDomainRequest: (url: String) -> Unit = { _ -> },
)