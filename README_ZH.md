# Gleam

一款优雅的 macOS 效率工具，集成划词翻译、截图收藏、内容管理功能。

## 功能特性

### 🌐 划词翻译
- 全局快捷键 `⌥T` 触发
- 支持多翻译引擎：DeepSeek、OpenAI、DeepL
- 美观的浮窗显示翻译结果
- 自动保存翻译历史

### 📸 截图收藏
- 全局快捷键 `⌥S` 触发
- 调用系统截图工具
- 自动保存到本地
- 支持图片预览和管理

### ⭐ 快速收藏
- 全局快捷键 `⌥C` 触发
- 选中文字一键收藏
- 支持添加标签分类
- 本地数据持久化

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| `⌥T` | 划词翻译 |
| `⌥S` | 截图 |
| `⌥C` | 快速收藏 |
| `⌘N` | 新建收藏 |
| `⌘,` | 打开设置 |
| `ESC` | 关闭浮窗 |

## 技术栈

- **语言**: Swift 5
- **UI 框架**: SwiftUI
- **数据存储**: SQLite
- **最低版本**: macOS 14.0+

## 项目结构

```
Gleam/
├── GleamApp.swift                 # 应用入口
├── App/
│   ├── AppDelegate.swift          # 应用生命周期、快捷键
│   └── AppState.swift             # 全局状态管理
├── Core/
│   ├── Database/
│   │   └── DatabaseManager.swift  # SQLite 数据库
│   └── Services/
│       ├── AccessibilityService.swift  # 获取选中文本
│       └── HotkeyService.swift    # 全局快捷键
├── Features/
│   ├── Translation/
│   │   ├── Services/
│   │   │   └── TranslationService.swift  # 翻译 API
│   │   └── Views/
│   │       └── TranslationPopoverView.swift
│   ├── Screenshot/
│   │   └── Services/
│   │       └── ScreenshotService.swift
│   └── Collection/
│       ├── Services/
│       │   └── CollectionService.swift
│       └── Views/
│           └── QuickCollectView.swift
├── UI/
│   ├── MenuBar/
│   │   └── MenuBarView.swift      # 菜单栏
│   └── Windows/
│       ├── MainWindowView.swift   # 主窗口
│       └── SettingsView.swift     # 设置
└── Resources/
    └── Assets.xcassets
```

## 数据存储

数据存储在应用沙盒目录：
```
~/Library/Containers/ziwen.Gleam/Data/Library/Application Support/Gleam/
├── gleam.db          # SQLite 数据库
└── Screenshots/      # 截图文件
```

## 配置翻译 API

1. 打开应用设置（`⌘,`）
2. 进入「翻译」标签页
3. 填入 API Key：
   - [DeepSeek API Key](https://platform.deepseek.com/api_keys)
   - [OpenAI API Key](https://platform.openai.com/api-keys)
   - [DeepL API Key](https://www.deepl.com/pro-api)

## 权限要求

- **辅助功能权限**: 用于获取选中文本
  > 系统设置 → 隐私与安全性 → 辅助功能 → 勾选 Gleam
- **网络权限**: 用于调用翻译 API

## 构建

```bash
# 开发版本
xcodebuild -scheme Gleam -configuration Debug build

# 发布版本
xcodebuild -scheme Gleam -configuration Release build
```

或使用 Xcode 打开 `Gleam.xcodeproj` 直接构建。

## 打包分发

1. Xcode → Product → Archive
2. Organizer → Distribute App
3. 选择分发方式：
   - Copy App（本地使用）
   - Developer ID（公证分发）
   - App Store（上架）

## License

MIT License

## 作者

Song Ziwen
