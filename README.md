# MiMo AI iOS Client

小米 MIMO 大模型 iOS 客户端 - WebView 版本

## 功能特点

- 🧠 支持深度思考过程展示
- 🌐 联网搜索功能
- 💬 多轮对话
- ⚡ 快速响应
- 📱 原生 iOS 体验

## 安装要求

- macOS 13.0+
- Xcode 15.0+
- iOS 16.0+ 设备或模拟器

## 编译步骤

1. 克隆仓库
```bash
git clone https://github.com/ibigbigip/MiMoAI.git
cd MiMoAI
```

2. 安装 XcodeGen（如果没有）
```bash
brew install xcodegen
```

3. 生成 Xcode 项目
```bash
xcodegen generate
```

4. 打开项目并运行
```bash
open MiMoAI.xcodeproj
```

5. 在 Xcode 中选择您的开发团队，然后按 Cmd+R 运行

## 项目结构

```
MiMoAI/
├── MiMoAI/
│   ├── MiMoAIApp.swift      # App 入口
│   ├── ContentView.swift     # WebView 主视图
│   ├── Info.plist
│   └── Assets.xcassets/      # 资源文件
└── project.yml               # XcodeGen 配置
```

## 技术栈

- SwiftUI
- WKWebView
- XcodeGen

## 许可证

MIT License

## 致谢

- 小米 MIMO 团队提供的 AI 服务
