//
//  ChatInputView.swift
//  MiMoChat
//
//  聊天输入组件 - 带深度思考和联网搜索按钮
//

import SwiftUI

struct ChatInputView: View {
    @ObservedObject var viewModel: ChatViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @FocusState private var isFocused: Bool
    
    @State private var enableDeepThinking = false  // 深度思考
    @State private var enableWebSearch = false     // 联网搜索
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            VStack(spacing: 10) {
                // 功能按钮行
                HStack(spacing: 12) {
                    // 深度思考按钮
                    FeatureToggleButton(
                        icon: "brain.head.profile",
                        title: "深度思考",
                        isEnabled: $enableDeepThinking,
                        color: .purple
                    )
                    
                    // 联网搜索按钮
                    FeatureToggleButton(
                        icon: "globe",
                        title: "联网搜索",
                        isEnabled: $enableWebSearch,
                        color: .blue
                    )
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // 输入框和发送按钮
                HStack(alignment: .bottom, spacing: 10) {
                    // 输入框
                    TextField("输入消息...", text: $viewModel.inputText, axis: .vertical)
                        .focused($isFocused)
                        .lineLimit(1...5)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(themeManager.inputBackgroundColor)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isFocused ? themeManager.accentColor : themeManager.dividerColor, lineWidth: 1)
                        )
                        .onSubmit {
                            sendIfPossible()
                        }
                    
                    // 发送按钮
                    Button(action: sendOrStop) {
                        ZStack {
                            Circle()
                                .fill(canSend ? themeManager.accentColor : Color.gray.opacity(0.3))
                                .frame(width: 42, height: 42)
                            
                            Image(systemName: viewModel.isLoading ? "stop.fill" : "arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .disabled(!canSend && !viewModel.isLoading)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            .background(themeManager.backgroundColor)
        }
        .onChange(of: enableDeepThinking) { newValue in
            viewModel.apiService.enableThinking = newValue
        }
    }
    
    private var canSend: Bool {
        !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func sendOrStop() {
        if viewModel.isLoading {
            viewModel.stopGeneration()
        } else {
            sendIfPossible()
        }
    }
    
    private func sendIfPossible() {
        guard canSend else { return }
        viewModel.sendMessage()
        isFocused = false
    }
}

// MARK: - 功能切换按钮

struct FeatureToggleButton: View {
    let icon: String
    let title: String
    @Binding var isEnabled: Bool
    let color: Color
    
    var body: some View {
        Button(action: { isEnabled.toggle() }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.subheadline)
            }
            .foregroundStyle(isEnabled ? .white : color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isEnabled ? color : color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        Spacer()
        ChatInputView(viewModel: ChatViewModel())
    }
    .environmentObject(ThemeManager())
}
