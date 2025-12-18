//
//  Message.swift
//  MiMoChat
//
//  消息模型
//

import Foundation

struct Message: Identifiable, Codable {
    let id: UUID
    let role: MessageRole
    var content: String
    var thinkingContent: String?
    let timestamp: Date
    var isStreaming: Bool
    var showThinking: Bool
    
    init(id: UUID = UUID(), role: MessageRole, content: String, thinkingContent: String? = nil, timestamp: Date = Date(), isStreaming: Bool = false, showThinking: Bool = false) {
        self.id = id
        self.role = role
        self.content = content
        self.thinkingContent = thinkingContent
        self.timestamp = timestamp
        self.isStreaming = isStreaming
        self.showThinking = showThinking
    }
}

// 让SwiftUI能检测到content变化
extension Message: Equatable {
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id &&
        lhs.content == rhs.content &&
        lhs.isStreaming == rhs.isStreaming &&
        lhs.showThinking == rhs.showThinking
    }
}

enum MessageRole: String, Codable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"
}
