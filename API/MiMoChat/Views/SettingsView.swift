//
//  SettingsView.swift
//  MiMoChat
//
//  设置视图
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: ChatViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showAPIKey = false
    @State private var showClearConfirm = false
    
    var body: some View {
        NavigationStack {
            Form {
                // API配置
                Section("API 配置") {
                    HStack {
                        if showAPIKey {
                            TextField("API Key", text: $viewModel.apiService.apiKey)
                        } else {
                            SecureField("API Key", text: $viewModel.apiService.apiKey)
                        }
                        Button(action: { showAPIKey.toggle() }) {
                            Image(systemName: showAPIKey ? "eye.slash" : "eye")
                        }
                    }
                    
                    TextField("模型", text: $viewModel.apiService.model)
                    
                    Link("获取API Key", destination: URL(string: "https://platform.xiaomimimo.com")!)
                }
                
                // 模型参数
                Section("模型参数") {
                    HStack {
                        Text("Temperature")
                        Spacer()
                        Text(String(format: "%.1f", viewModel.apiService.temperature))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $viewModel.apiService.temperature, in: 0...2, step: 0.1)
                    
                    Stepper("Max Tokens: \(viewModel.apiService.maxTokens)", 
                            value: $viewModel.apiService.maxTokens, 
                            in: 256...8192, 
                            step: 256)
                }
                
                // 系统提示
                Section("系统提示") {
                    TextEditor(text: $viewModel.apiService.systemPrompt)
                        .frame(minHeight: 80)
                }
                
                // 外观
                Section("外观") {
                    Toggle("深色模式", isOn: $themeManager.isDarkMode)
                    
                    HStack {
                        Text("主题色")
                        Spacer()
                        ForEach(ThemeManager.accentColors.indices, id: \.self) { i in
                            Circle()
                                .fill(ThemeManager.accentColors[i])
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(.white, lineWidth: themeManager.accentColorIndex == i ? 3 : 0)
                                )
                                .onTapGesture {
                                    themeManager.accentColorIndex = i
                                }
                        }
                    }
                }
                
                // 数据
                Section("数据") {
                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Label("清除所有对话", systemImage: "trash")
                    }
                }
                
                // 关于
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        viewModel.apiService.saveSettings()
                        dismiss()
                    }
                    .bold()
                }
            }
            .confirmationDialog("确定清除所有对话？", isPresented: $showClearConfirm) {
                Button("清除", role: .destructive) {
                    viewModel.conversationManager.clearAllConversations()
                    viewModel.loadCurrentConversation()
                }
            }
        }
    }
}

#Preview {
    SettingsView(viewModel: ChatViewModel())
        .environmentObject(ThemeManager())
}
