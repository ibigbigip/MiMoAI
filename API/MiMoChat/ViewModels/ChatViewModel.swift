//
//  ChatViewModel.swift
//  MiMoChat
//
//  聊天视图模型 - 支持流式输出
//

import Foundation
import SwiftUI

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    var apiService = MiMoAPIService()
    var conversationManager = ConversationManager()
    
    init() {
        loadCurrentConversation()
    }
    
    func loadCurrentConversation() {
        if let current = conversationManager.currentConversation {
            messages = current.messages
        }
    }
    
    func selectConversation(_ conversation: Conversation) {
        conversationManager.selectConversation(conversation)
        loadCurrentConversation()
    }
    
    func createNewConversation() {
        conversationManager.createNewConversation()
        messages = []
    }
    
    func deleteConversation(_ conversation: Conversation) {
        conversationManager.deleteConversation(conversation)
        loadCurrentConversation()
    }
    
    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // 添加用户消息
        let userMessage = Message(role: .user, content: text)
        messages.append(userMessage)
        inputText = ""
        
        // 添加AI占位消息
        let aiMessage = Message(role: .assistant, content: "", isStreaming: true, showThinking: true)
        messages.append(aiMessage)
        
        isLoading = true
        
        let messagesToSend = Array(messages.dropLast())
        let messageIndex = messages.count - 1
        
        // 使用流式请求
        apiService.sendMessageStreaming(
            messages: messagesToSend,
            onThinking: { [weak self] thinking in
                guard let self = self, messageIndex < self.messages.count else { return }
                var msg = self.messages[messageIndex]
                msg.thinkingContent = thinking
                self.messages[messageIndex] = msg
            },
            onContent: { [weak self] content in
                guard let self = self, messageIndex < self.messages.count else { return }
                var msg = self.messages[messageIndex]
                msg.content = content
                self.messages[messageIndex] = msg
            },
            onComplete: { [weak self] error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    if messageIndex < self.messages.count {
                        var msg = self.messages[messageIndex]
                        msg.content = "❌ 错误: \(error.localizedDescription)"
                        msg.isStreaming = false
                        self.messages[messageIndex] = msg
                    }
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                } else {
                    if messageIndex < self.messages.count {
                        var msg = self.messages[messageIndex]
                        msg.isStreaming = false
                        self.messages[messageIndex] = msg
                    }
                }
                
                self.saveConversation()
            }
        )
    }
    
    func stopGeneration() {
        isLoading = false
        if messages.count > 0 && messages[messages.count - 1].role == .assistant {
            var msg = messages[messages.count - 1]
            msg.isStreaming = false
            if msg.content.isEmpty {
                msg.content = "[已停止]"
            }
            messages[messages.count - 1] = msg
        }
        saveConversation()
    }
    
    func retryLastMessage() {
        if messages.last?.role == .assistant {
            messages.removeLast()
        }
        if let lastUser = messages.last, lastUser.role == .user {
            inputText = lastUser.content
            messages.removeLast()
            sendMessage()
        }
    }
    
    func clearMessages() {
        messages.removeAll()
        createNewConversation()
    }
    
    private func saveConversation() {
        conversationManager.updateCurrentConversation(with: messages)
    }
    
    func copyMessage(_ message: Message) {
        UIPasteboard.general.string = message.content
    }
    
    func deleteMessage(_ message: Message) {
        messages.removeAll { $0.id == message.id }
        saveConversation()
    }
    
    func toggleThinking(for message: Message) {
        if let idx = messages.firstIndex(where: { $0.id == message.id }) {
            messages[idx].showThinking.toggle()
        }
    }
}
