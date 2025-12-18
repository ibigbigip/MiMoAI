//
//  ConversationListView.swift
//  MiMoChat
//
//  会话列表视图
//

import SwiftUI

struct ConversationListView: View {
    @ObservedObject var viewModel: ChatViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        List {
            Section {
                Button(action: { viewModel.createNewConversation() }) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(themeManager.accentGradient)
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        
                        Text("新对话")
                            .font(.headline)
                            .foregroundStyle(themeManager.primaryTextColor)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(themeManager.cardBackgroundColor)
            }
            
            Section("历史对话") {
                ForEach(viewModel.conversationManager.conversations) { conversation in
                    ConversationRow(
                        conversation: conversation,
                        isSelected: viewModel.conversationManager.currentConversation?.id == conversation.id,
                        onSelect: {
                            viewModel.selectConversation(conversation)
                        }
                    )
                    .listRowBackground(
                        viewModel.conversationManager.currentConversation?.id == conversation.id
                        ? themeManager.accentColor.opacity(0.1)
                        : themeManager.cardBackgroundColor
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.deleteConversation(conversation)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(themeManager.backgroundColor)
        .navigationTitle("对话")
    }
}

// MARK: - Conversation Row

struct ConversationRow: View {
    let conversation: Conversation
    let isSelected: Bool
    let onSelect: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // 图标
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? themeManager.accentGradient : LinearGradient(colors: [Color.gray.opacity(0.2)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : themeManager.secondaryTextColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(conversation.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(themeManager.primaryTextColor)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Text("\(conversation.messages.count) 条消息")
                            .font(.caption)
                            .foregroundStyle(themeManager.secondaryTextColor)
                        
                        Text("·")
                            .foregroundStyle(themeManager.secondaryTextColor)
                        
                        Text(conversation.updatedAt.relativeFormatted())
                            .font(.caption)
                            .foregroundStyle(themeManager.secondaryTextColor)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(themeManager.accentGradient)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    NavigationStack {
        ConversationListView(viewModel: ChatViewModel())
            .environmentObject(ThemeManager())
    }
}
