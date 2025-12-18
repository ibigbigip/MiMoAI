//
//  MessageBubble.swift
//  MiMoChat
//
//  消息气泡组件 - 带操作按钮和动态思考效果
//

import SwiftUI

struct MessageBubble: View {
    let message: Message
    @ObservedObject var viewModel: ChatViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showCopied = false
    
    private var isUser: Bool { message.role == .user }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if isUser { Spacer(minLength: 16) }
            else { avatarView(isUser: false) }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                // 思考动画（正在加载时显示）
                if !isUser && message.isStreaming {
                    ThinkingAnimationView()
                }
                
                // 消息内容
                if !message.content.isEmpty {
                    messageContent
                }
                
                // 操作按钮（AI消息且不在加载中）
                if !isUser && !message.isStreaming && !message.content.isEmpty {
                    actionButtons
                }
            }
            
            if isUser { avatarView(isUser: true) }
            else { Spacer(minLength: 16) }
        }
    }
    
    private func avatarView(isUser: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isUser ? Color.blue : themeManager.accentColor)
                .frame(width: 30, height: 30)
            
            Image(systemName: isUser ? "person.fill" : "sparkles")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
    
    @ViewBuilder
    private var messageContent: some View {
        Text(message.content)
            .font(.body)
            .foregroundStyle(isUser ? .white : themeManager.primaryTextColor)
            .textSelection(.enabled)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isUser ? themeManager.accentColor : themeManager.bubbleBackgroundColor)
            )
    }
    
    // 操作按钮
    private var actionButtons: some View {
        HStack(spacing: 20) {
            // 复制按钮
            Button(action: copyMessage) {
                HStack(spacing: 4) {
                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 13))
                }
                .foregroundStyle(showCopied ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            // 分享按钮
            Button(action: shareMessage) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            
            // 重新生成
            Button(action: { viewModel.retryLastMessage() }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // 时间
            Text(message.timestamp, style: .time)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.top, 2)
    }
    
    private func copyMessage() {
        UIPasteboard.general.string = message.content
        showCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopied = false
        }
    }
    
    private func shareMessage() {
        let activityVC = UIActivityViewController(
            activityItems: [message.content],
            applicationActivities: nil
        )
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - 动态思考动画

struct ThinkingAnimationView: View {
    @State private var rotation: Double = 0
    @State private var dotIndex = 0
    @State private var thinkingText = "正在思考"
    
    let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
    
    private let thinkingSteps = [
        "正在思考",
        "分析问题",
        "整理思路",
        "组织回答"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题
            HStack(spacing: 8) {
                // 旋转的大脑图标
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 16))
                    .foregroundStyle(.purple)
                    .rotationEffect(.degrees(rotation))
                
                Text(thinkingText)
                    .font(.subheadline.bold())
                    .foregroundStyle(.purple)
                
                // 动态省略号
                HStack(spacing: 2) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(Color.purple.opacity(i <= dotIndex ? 1 : 0.3))
                            .frame(width: 5, height: 5)
                            .animation(.easeInOut(duration: 0.2), value: dotIndex)
                    }
                }
            }
            
            // 模拟思考进度条
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.purple.opacity(0.2))
                    .frame(height: 4)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .purple.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(dotIndex + 1) / 4.0)
                            .animation(.easeInOut(duration: 0.3), value: dotIndex)
                    }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.purple.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                dotIndex = (dotIndex + 1) % 4
                rotation += 15
                thinkingText = thinkingSteps[dotIndex]
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        MessageBubble(
            message: Message(role: .user, content: "你好，这是一段测试文本"),
            viewModel: ChatViewModel()
        )
        MessageBubble(
            message: Message(role: .assistant, content: "", isStreaming: true),
            viewModel: ChatViewModel()
        )
        MessageBubble(
            message: Message(role: .assistant, content: "你好！我是MiMo AI，很高兴为你服务。"),
            viewModel: ChatViewModel()
        )
    }
    .padding()
    .environmentObject(ThemeManager())
}
