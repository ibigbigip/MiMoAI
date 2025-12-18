//
//  ChatView.swift
//  MiMoChat
//
//  聊天主界面
//

import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showDebug = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 调试面板
            if showDebug {
                ScrollView {
                    Text(viewModel.apiService.debugLog)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                }
                .frame(height: 120)
                .background(Color.black.opacity(0.9))
                .foregroundColor(.green)
            }
            
            // 消息列表
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if viewModel.messages.isEmpty {
                            EmptyStateView()
                                .padding(.top, 60)
                        } else {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message, viewModel: viewModel)
                                    .id(message.id)
                            }
                        }
                        
                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onChange(of: viewModel.messages.last?.content) { _ in
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
            
            // 输入区域
            ChatInputView(viewModel: viewModel)
        }
        .background(themeManager.backgroundColor)
        .navigationTitle("MiMo AI")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { showDebug.toggle() }) {
                    Image(systemName: showDebug ? "ladybug.fill" : "ladybug")
                        .foregroundStyle(showDebug ? .red : .gray)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { viewModel.createNewConversation() } label: {
                        Label("新对话", systemImage: "plus.bubble")
                    }
                    Button { viewModel.apiService.debugLog = "" } label: {
                        Label("清除日志", systemImage: "doc.badge.clock")
                    }
                    Button(role: .destructive) { viewModel.clearMessages() } label: {
                        Label("清空对话", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("错误", isPresented: $viewModel.showError) {
            Button("确定") { }
        } message: {
            Text(viewModel.errorMessage ?? "未知错误")
        }
    }
}

// MARK: - 空状态视图

struct EmptyStateView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 24) {
            // Logo
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                    .shadow(color: themeManager.accentColor.opacity(0.4), radius: 16, x: 0, y: 8)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(.white)
            }
            
            // 标题
            VStack(spacing: 8) {
                Text("MiMo AI")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(themeManager.primaryTextColor)
                
                Text("小米MIMO大模型助手")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            // 功能特点
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "brain.head.profile", text: "支持思考过程展示", color: .purple)
                FeatureRow(icon: "bolt.fill", text: "快速响应", color: .yellow)
                FeatureRow(icon: "bubble.left.and.bubble.right.fill", text: "多轮对话", color: themeManager.accentColor)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 32)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        ChatView(viewModel: ChatViewModel())
            .environmentObject(ThemeManager())
    }
}
