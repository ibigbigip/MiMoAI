//
//  MiMoChatApp.swift
//  MiMoChat
//
//  小米MIMO AI大模型iOS客户端
//

import SwiftUI

@main
struct MiMoChatApp: App {
    @StateObject private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        }
    }
}
