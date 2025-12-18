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
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        // 设置User-Agent模拟移动端
        config.applicationNameForUserAgent = "MiMoAI/1.0 iOS"
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.bounces = true
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = .white
        
        // 监听加载进度
        webView.addObserver(context.coordinator, forKeyPath: "estimatedProgress", options: .new, context: nil)
        
        // 监听重新加载通知
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.reload),
            name: .reloadWebView,
            object: nil
        )
        
        // 加载网页
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        webView.load(request)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: MiMoWebView
        var webView: WKWebView?
        
        init(_ parent: MiMoWebView) {
            self.parent = parent
        }
        
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            if keyPath == "estimatedProgress", let webView = object as? WKWebView {
                self.webView = webView
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
                
                // 注入CSS隐藏不需要的元素（可选）
                let hideHeaderJS = """
                    // 可以在这里隐藏网页的某些元素，让它更像原生App
                    // document.querySelector('header')?.style.display = 'none';
                """
                webView.evaluateJavaScript(hideHeaderJS)
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            handleError(error)
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            handleError(error)
        }
        
        private func handleError(_ error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.errorMessage = error.localizedDescription
                self.parent.showError = true
            }
        }
        
        // 处理新窗口链接
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.targetFrame == nil {
                // 在当前WebView中打开
                webView.load(navigationAction.request)
            }
            decisionHandler(.allow)
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
