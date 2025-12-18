//
//  Extensions.swift
//  MiMoChat
//
//  扩展工具
//

import Foundation
import SwiftUI

// MARK: - Date Extensions

extension Date {
    func relativeFormatted() -> String {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear], from: self, to: now)
        
        if let weeks = components.weekOfYear, weeks >= 1 {
            return self.formatted(date: .abbreviated, time: .omitted)
        } else if let days = components.day, days >= 1 {
            return days == 1 ? "昨天" : "\(days)天前"
        } else if let hours = components.hour, hours >= 1 {
            return "\(hours)小时前"
        } else if let minutes = components.minute, minutes >= 1 {
            return "\(minutes)分钟前"
        } else {
            return "刚刚"
        }
    }
}

// MARK: - View Extensions

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - String Extensions

extension String {
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func truncated(to length: Int, trailing: String = "...") -> String {
        if count > length {
            return String(prefix(length)) + trailing
        }
        return self
    }
}

// MARK: - Color Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Haptic Feedback

enum HapticFeedback {
    static func light() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    static func medium() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    static func heavy() {
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
    }
    
    static func success() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }
    
    static func error() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.error)
    }
    
    static func warning() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.warning)
    }
}

// MARK: - Keyboard Observer

class KeyboardObserver: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .map { $0.height }
            .assign(to: \.keyboardHeight, on: self)
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
            .assign(to: \.keyboardHeight, on: self)
            .store(in: &cancellables)
    }
}

import Combine

extension Set where Element == AnyCancellable {
    mutating func store(_ cancellable: AnyCancellable) {
        insert(cancellable)
    }
}
