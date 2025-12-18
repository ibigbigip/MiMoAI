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
    @State private var showSettings = false
    @State private var showLogoutAlert = false
    
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
            
            // 顶部工具栏
            VStack {
                HStack {
                    Spacer()
                    
                    // 设置按钮
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.gray)
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 8)
                }
                Spacer()
            }
            
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
        .confirmationDialog("设置", isPresented: $showSettings) {
            Button("刷新页面") {
                NotificationCenter.default.post(name: .reloadWebView, object: nil)
            }
            Button("退出登录", role: .destructive) {
                showLogoutAlert = true
            }
            Button("取消", role: .cancel) {}
        }
        .alert("确认退出登录？", isPresented: $showLogoutAlert) {
            Button("退出", role: .destructive) {
                NotificationCenter.default.post(name: .logoutWebView, object: nil)
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("将清除所有登录信息")
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
        config.websiteDataStore = WKWebsiteDataStore.default()
        
        let webView = WKWebView(frame: .zero, configuration: config)
        
        // 设置桌面 Safari User-Agent（解决登录问题）
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.scrollView.bounces = true
        webView.allowsBackForwardNavigationGestures = true
        
        webView.addObserver(context.coordinator, forKeyPath: "estimatedProgress", options: .new, context: nil)
        
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.reload),
            name: .reloadWebView,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.logout),
            name: .logoutWebView,
            object: nil
        )
        
        context.coordinator.webView = webView
        
        let request = URLRequest(url: url)
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
        
        @objc func logout() {
            // 清除所有网站数据（Cookies、缓存等）
            let dataStore = WKWebsiteDataStore.default()
            let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
            let date = Date(timeIntervalSince1970: 0)
            
            dataStore.removeData(ofTypes: dataTypes, modifiedSince: date) { [weak self] in
                // 重新加载页面
                DispatchQueue.main.async {
                    self?.webView?.load(URLRequest(url: self?.parent.url ?? URL(string: "https://aistudio.xiaomimimo.com")!))
                }
            }
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
            let nsError = error as NSError
            if nsError.code == NSURLErrorCancelled { return }
            
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.errorMessage = error.localizedDescription
                self.parent.showError = true
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
    }
}

// MARK: - 通知

extension Notification.Name {
    static let reloadWebView = Notification.Name("reloadWebView")
    static let logoutWebView = Notification.Name("logoutWebView")
}

#Preview {
    ContentView()
}
