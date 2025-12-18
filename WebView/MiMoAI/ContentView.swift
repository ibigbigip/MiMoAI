//
//  ContentView.swift
//  MiMoAI
//
//  主视图 - 全屏WebView
//

import SwiftUI
import WebKit

struct ContentView: View {
    @State private var isLoading = true
    @State private var loadProgress: Double = 0
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // WebView
            MiMoWebView(
                isLoading: $isLoading,
                loadProgress: $loadProgress,
                showError: $showError,
                errorMessage: $errorMessage
            )
            .ignoresSafeArea(edges: .bottom)
            
            // 加载进度条
            if isLoading {
                VStack {
                    ProgressView(value: loadProgress)
                        .progressViewStyle(.linear)
                        .tint(.orange)
                    Spacer()
                }
            }
        }
        .alert("加载失败", isPresented: $showError) {
            Button("重试") {
                NotificationCenter.default.post(name: .reloadWebView, object: nil)
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - WebView包装

struct MiMoWebView: UIViewRepresentable {
    @Binding var isLoading: Bool
    @Binding var loadProgress: Double
    @Binding var showError: Bool
    @Binding var errorMessage: String
    
    let url = URL(string: "https://aistudio.xiaomimimo.com")!
    
    func makeUIView(context: Context) -> WKWebView {
        // 配置 WebView
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        // 启用 JavaScript
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        config.defaultWebpagePreferences = preferences
        
        // 使用持久化数据存储（保存登录状态和 Cookie）
        config.websiteDataStore = WKWebsiteDataStore.default()
        
        // 设置 User-Agent（模拟 Safari 移动版）
        config.applicationNameForUserAgent = "Safari/605.1.15"
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.scrollView.bounces = true
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = true
        webView.backgroundColor = .white
        
        // 允许链接预览
        webView.allowsLinkPreview = true
        
        // 监听加载进度
        webView.addObserver(context.coordinator, forKeyPath: "estimatedProgress", options: .new, context: nil)
        
        // 监听重新加载通知
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.reload),
            name: .reloadWebView,
            object: nil
        )
        
        context.coordinator.webView = webView
        
        // 加载网页
        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60)
        webView.load(request)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: MiMoWebView
        weak var webView: WKWebView?
        
        init(_ parent: MiMoWebView) {
            self.parent = parent
        }
        
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            if keyPath == "estimatedProgress", let webView = object as? WKWebView {
                DispatchQueue.main.async {
                    self.parent.loadProgress = webView.estimatedProgress
                }
            }
        }
        
        @objc func reload() {
            webView?.reload()
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            handleError(error)
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            handleError(error)
        }
        
        private func handleError(_ error: Error) {
            // 忽略取消的请求
            let nsError = error as NSError
            if nsError.code == NSURLErrorCancelled { return }
            
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.errorMessage = error.localizedDescription
                self.parent.showError = true
            }
        }
        
        // 处理新窗口链接
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // 允许所有导航
            decisionHandler(.allow)
        }
        
        // 处理 target="_blank" 链接
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            // 在当前 WebView 中打开
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
        
        // 处理 JavaScript alert
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            // 允许 JavaScript alert
            completionHandler()
        }
        
        // 处理 JavaScript confirm
        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            completionHandler(true)
        }
        
        // 处理 JavaScript prompt
        func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
            completionHandler(defaultText)
        }
    }
}

// MARK: - 通知

extension Notification.Name {
    static let reloadWebView = Notification.Name("reloadWebView")
}

#Preview {
    ContentView()
}
