//
//  ThemeManager.swift
//  MiMoChat
//
//  主题管理
//

import SwiftUI

class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    
    @Published var accentColorIndex: Int {
        didSet {
            UserDefaults.standard.set(accentColorIndex, forKey: "accentColorIndex")
        }
    }
    
    static let accentColors: [Color] = [
        Color(red: 255/255, green: 103/255, blue: 31/255),  // 小米橙
        Color(red: 88/255, green: 86/255, blue: 214/255),   // 紫色
        Color(red: 50/255, green: 173/255, blue: 230/255),  // 蓝色
        Color(red: 52/255, green: 199/255, blue: 89/255),   // 绿色
        Color(red: 255/255, green: 45/255, blue: 85/255),   // 粉红
    ]
    
    init() {
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        self.accentColorIndex = UserDefaults.standard.integer(forKey: "accentColorIndex")
    }
    
    // MARK: - Colors
    
    var accentColor: Color {
        Self.accentColors[safe: accentColorIndex] ?? Self.accentColors[0]
    }
    
    var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accentColor, accentColor.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var backgroundColor: Color {
        isDarkMode 
            ? Color(red: 18/255, green: 18/255, blue: 22/255)
            : Color(red: 245/255, green: 245/255, blue: 250/255)
    }
    
    var cardBackgroundColor: Color {
        isDarkMode
            ? Color(red: 28/255, green: 28/255, blue: 34/255)
            : Color.white
    }
    
    var bubbleBackgroundColor: Color {
        isDarkMode
            ? Color(red: 38/255, green: 38/255, blue: 46/255)
            : Color(red: 240/255, green: 240/255, blue: 245/255)
    }
    
    var inputBackgroundColor: Color {
        isDarkMode
            ? Color(red: 38/255, green: 38/255, blue: 46/255)
            : Color.white
    }
    
    var primaryTextColor: Color {
        isDarkMode ? .white : Color(red: 30/255, green: 30/255, blue: 35/255)
    }
    
    var secondaryTextColor: Color {
        isDarkMode 
            ? Color(red: 160/255, green: 160/255, blue: 170/255)
            : Color(red: 120/255, green: 120/255, blue: 130/255)
    }
    
    var dividerColor: Color {
        isDarkMode
            ? Color.white.opacity(0.1)
            : Color.black.opacity(0.08)
    }
    
    // MARK: - Methods
    
    func setAccentColor(_ color: Color) {
        if let index = Self.accentColors.firstIndex(of: color) {
            accentColorIndex = index
        }
    }
}

// MARK: - Safe Array Access

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
