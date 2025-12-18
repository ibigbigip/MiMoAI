//
//  ContentView.swift
//  MiMoChat
//
//  主内容视图 - 包含会话列表和聊天界面
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showSettings = false
    @State private var showConversationList = false
    
    // 检测是否是iPad
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // iPad: 使用分栏布局
                NavigationSplitView {
                    ConversationListView(viewModel: viewModel)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button(action: { showSettings = true }) {
                                    Image(systemName: "gearshape.fill")
                                        .foregroundStyle(themeManager.accentGradient)
                                }
                            }
                        }
                } detail: {
                    ChatView(viewModel: viewModel)
                }
            } else {
                // iPhone: 使用简单导航
                NavigationStack {
                    ChatView(viewModel: viewModel)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button(action: { showConversationList = true }) {
                                    Image(systemName: "list.bullet")
                                        .foregroundStyle(themeManager.accentGradient)
                                }
                            }
                            ToolbarItem(placement: .topBarTrailing) {
                                Button(action: { showSettings = true }) {
                                    Image(systemName: "gearshape.fill")
                                        .foregroundStyle(themeManager.accentGradient)
                                }
                            }
                        }
                }
                .sheet(isPresented: $showConversationList) {
                    NavigationStack {
                        ConversationListView(viewModel: viewModel)
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button("完成") {
                                        showConversationList = false
                                    }
                                }
                            }
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel)
        }
        .tint(themeManager.accentColor)
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
}
