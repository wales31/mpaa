package com.mpaa.debugwebview

import android.annotation.SuppressLint
import android.content.pm.ApplicationInfo
import android.os.Build
import android.os.Bundle
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {
    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val webView = findViewById<WebView>(R.id.webview)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            val isDebuggable = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
            WebView.setWebContentsDebuggingEnabled(isDebuggable)
        }

        webView.webViewClient = WebViewClient()
        webView.settings.javaScriptEnabled = true
        webView.settings.domStorageEnabled = true
        webView.settings.cacheMode = WebSettings.LOAD_DEFAULT
        webView.settings.allowFileAccess = true
        webView.settings.allowContentAccess = true

        webView.loadUrl("file:///android_asset/index.html")
    }

    override fun onBackPressed() {
        val webView = findViewById<WebView>(R.id.webview)
        if (webView.canGoBack()) {
            webView.goBack()
        } else {
            super.onBackPressed()
        }
    }
}
