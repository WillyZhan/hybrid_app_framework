package com.gogolook.webviewframework

data class WebContainerConfig(
    val authToken: String,
    val region: String,
    val language: String,
    val userAgent: String,
    val profile: Profile
)

data class Profile(
    val userId: String,
    val email: String,
    val deviceId: String
)
