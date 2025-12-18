//
//  MiMoAIApp.swift
//  MiMoAI
//
//  MiMo AI - WebView版本
//  直接嵌入小米MIMO Studio网页版
//

import SwiftUI

@main
struct MiMoAIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)  // 跟随网页版默认浅色
        }
    }
}
