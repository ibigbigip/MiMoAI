//
//  Conversation.swift
//  MiMoChat
//
//  会话模型
//

import Foundation

struct Conversation: Identifiable, Codable {
    let id: UUID
    var title: String
    var messages: [Message]
    let createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), title: String = "新对话", messages: [Message] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    mutating func updateTitle() {
        // 根据第一条用户消息生成标题
        if let firstUserMessage = messages.first(where: { $0.role == .user }) {
            let content = firstUserMessage.content
            let maxLength = 20
            if content.count > maxLength {
                title = String(content.prefix(maxLength)) + "..."
            } else {
                title = content
            }
        }
    }
}

// MARK: - Conversation Manager
class ConversationManager: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var currentConversation: Conversation?
    
    private let userDefaults = UserDefaults.standard
    private let conversationsKey = "saved_conversations"
    
    init() {
        loadConversations()
        if conversations.isEmpty {
            createNewConversation()
        } else {
            currentConversation = conversations.first
        }
    }
    
    func createNewConversation() {
        let newConversation = Conversation()
        conversations.insert(newConversation, at: 0)
        currentConversation = newConversation
        saveConversations()
    }
    
    func selectConversation(_ conversation: Conversation) {
        currentConversation = conversation
    }
    
    func deleteConversation(_ conversation: Conversation) {
        conversations.removeAll { $0.id == conversation.id }
        if currentConversation?.id == conversation.id {
            currentConversation = conversations.first
            if currentConversation == nil {
                createNewConversation()
            }
        }
        saveConversations()
    }
    
    func updateCurrentConversation(with messages: [Message]) {
        guard var current = currentConversation else { return }
        current.messages = messages
        current.updatedAt = Date()
        current.updateTitle()
        
        if let index = conversations.firstIndex(where: { $0.id == current.id }) {
            conversations[index] = current
        }
        currentConversation = current
        saveConversations()
    }
    
    func clearAllConversations() {
        conversations.removeAll()
        createNewConversation()
    }
    
    // MARK: - Persistence
    
    private func saveConversations() {
        if let encoded = try? JSONEncoder().encode(conversations) {
            userDefaults.set(encoded, forKey: conversationsKey)
        }
    }
    
    private func loadConversations() {
        if let data = userDefaults.data(forKey: conversationsKey),
           let decoded = try? JSONDecoder().decode([Conversation].self, from: data) {
            conversations = decoded
        }
    }
}
