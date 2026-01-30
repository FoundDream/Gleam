# Gleam

An elegant macOS productivity tool featuring text translation, screenshot collection, and content management.

[Chinese Documentation](README_ZH.md)

## Features

### 🌐 Text Translation

- Global hotkey `⌥T` to trigger
- Multiple translation engines: DeepSeek, OpenAI, DeepL
- Beautiful floating window for results
- Auto-save translation history

### 📸 Screenshot Collection

- Global hotkey `⌥S` to trigger
- Native macOS screenshot tool integration
- Auto-save to local storage
- Image preview and management

### ⭐ Quick Collect

- Global hotkey `⌥C` to trigger
- One-click save selected text
- Tag support for organization
- Local data persistence

## Keyboard Shortcuts

| Shortcut | Action                  |
| -------- | ----------------------- |
| `⌥T`     | Translate selected text |
| `⌥S`     | Take screenshot         |
| `⌥C`     | Quick collect           |
| `⌘N`     | New collection          |
| `⌘,`     | Open settings           |
| `ESC`    | Close popup             |

## Tech Stack

- **Language**: Swift 5
- **UI Framework**: SwiftUI
- **Database**: SQLite
- **Minimum OS**: macOS 14.0+

## Project Structure

```
Gleam/
├── GleamApp.swift                 # App entry point
├── App/
│   ├── AppDelegate.swift          # App lifecycle, hotkeys
│   └── AppState.swift             # Global state management
├── Core/
│   ├── Database/
│   │   └── DatabaseManager.swift  # SQLite database
│   └── Services/
│       ├── AccessibilityService.swift  # Get selected text
│       └── HotkeyService.swift    # Global hotkeys
├── Features/
│   ├── Translation/
│   │   ├── Services/
│   │   │   └── TranslationService.swift  # Translation APIs
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
│   │   └── MenuBarView.swift      # Menu bar
│   └── Windows/
│       ├── MainWindowView.swift   # Main window
│       └── SettingsView.swift     # Settings
└── Resources/
    └── Assets.xcassets
```

## Data Storage

Data is stored in the app sandbox:

```
~/Library/Containers/ziwen.Gleam/Data/Library/Application Support/Gleam/
├── gleam.db          # SQLite database
└── Screenshots/      # Screenshot files
```

## API Configuration

1. Open app settings (`⌘,`)
2. Go to "Translation" tab
3. Enter your API keys:
   - [DeepSeek API Key](https://platform.deepseek.com/api_keys)
   - [OpenAI API Key](https://platform.openai.com/api-keys)
   - [DeepL API Key](https://www.deepl.com/pro-api)

## Permissions Required

- **Accessibility**: Required for getting selected text
  > System Settings → Privacy & Security → Accessibility → Enable Gleam
- **Network**: Required for translation API calls

## Build

```bash
# Debug build
xcodebuild -scheme Gleam -configuration Debug build

# Release build
xcodebuild -scheme Gleam -configuration Release build
```

Or open `Gleam.xcodeproj` in Xcode and build directly.

## Distribution

1. Xcode → Product → Archive
2. Organizer → Distribute App
3. Choose distribution method:
   - Copy App (local use)
   - Developer ID (notarized distribution)
   - App Store (publish)

## License

MIT License

## Author

Ziwen
