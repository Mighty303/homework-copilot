# 🧠 Homework Copilot

A lightweight macOS menu bar app that helps you solve homework questions instantly using AI. Capture screenshots or select text, and get answers powered by state-of-the-art language models.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)

## ✨ Features

### 🖼️ Screenshot OCR
- **Instant capture**: Press `⌘⇧S` to capture your entire screen
- **Apple Vision OCR**: Uses native macOS text recognition (fast, accurate, offline)
- **Multi-line support**: Handles complex layouts, equations, and formatted text

### 📝 Text Selection
- **Direct text input**: Press `⌘⇧T` to send highlighted text from any app
- **Stealthy mode**: Uses Accessibility API to avoid triggering copy events
- **Universal**: Works in browsers, PDFs, documents, and more

### 🤖 AI-Powered Answers
- **Multiple models**: Choose from Claude 3.7 Sonnet, Llama 3.1 70B, or Mistral 7B
- **Custom prompts**: Configure exactly how you want answers formatted
- **Bold formatting**: Answers use `**bold**` to highlight key information
- **Fast responses**: Typically 2-5 seconds per query

### 🎨 Minimal UI
- **Menu bar only**: No dock icon, stays out of your way
- **Floating answers**: Transparent overlay shows answers on top of any window
- **Keyboard shortcuts**: Control everything without touching your mouse
- **Toggle visibility**: `⌘⇧C` to hide/show the answer window

## 📦 Installation

### Prerequisites
- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- [Replicate API key](https://replicate.com/account/api-tokens) (free tier available)

### Build from Source

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/homework-copilot.git
   cd homework-copilot
   ```

2. **Open in Xcode**
   ```bash
   open homework-copilot.xcodeproj
   ```

3. **Build and run**
   - Select your Mac as the target device
   - Press `⌘R` to build and run
   - Grant required permissions when prompted

4. **First launch setup**
   - Click the brain icon (🧠) in your menu bar
   - Select "Show Settings"
   - Enter your Replicate API token
   - Choose your preferred AI model

## 🔑 Required Permissions

The app will request these permissions on first use:

### Screen Recording
- **Why**: To capture screenshots for OCR
- **When**: First time you press `⌘⇧S`
- **Location**: System Settings → Privacy & Security → Screen Recording

### Accessibility
- **Why**: To read selected text without triggering copy events
- **When**: First time you press `⌘⇧T`
- **Location**: System Settings → Privacy & Security → Accessibility

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘⇧S` | Capture screenshot and solve |
| `⌘⇧T` | Send selected text to AI |
| `⌘⇧C` | Hide/show answer window |

## ⚙️ Configuration

### AI Models

Choose from three options based on your needs:

| Model | Speed | Quality | Best For |
|-------|-------|---------|----------|
| **Claude 3.7 Sonnet** | Medium | ⭐⭐⭐⭐⭐ | Complex reasoning, essays |
| **Llama 3.1 70B** | Fast | ⭐⭐⭐⭐ | General homework, balanced |
| **Mistral 7B** | Fastest | ⭐⭐⭐ | Quick answers, simple questions |

### Custom Prompts

Customize how the AI responds by editing the prompt template:

**Default prompt:**
```
On the first line, output ONLY the final answer in bold using two asterisks 
on each side, like this: **The answer is option A**. Do not include any other 
text on that line. After that, write a 1-2 sentence explanation. Always use 
bold by wrapping text in double asterisks. No preamble, no extra lines before 
the answer.
```

**Formatting tips:**
- Use `**text**` for bold (e.g., `**Answer: B**)
- Keep it concise for faster responses
- Specify output format (bullet points, steps, etc.)

## 🏗️ Architecture

```
homework-copilot/
├── homework_copilotApp.swift    # Main app entry & hotkey handling
├── OverlayWindow.swift          # Transparent floating answer window
├── ScreenCapturer.swift         # Screenshot capture using ScreenCaptureKit
├── TextGrabber.swift            # Selected text extraction via Accessibility API
├── SettingsView.swift           # Configuration UI (SwiftUI)
└── Assets.xcassets/             # App icons and resources
```

### Key Technologies
- **SwiftUI**: Settings interface
- **AppKit**: Menu bar, windows, hotkeys
- **Vision Framework**: OCR text recognition
- **ScreenCaptureKit**: Screen capture API
- **Accessibility API**: Text selection reading
- **URLSession**: Replicate API integration

## 🐛 Troubleshooting

### "No text detected in screenshot"
- Ensure the text is clearly visible and not too small
- Try capturing a smaller region with less clutter
- Check that Screen Recording permission is granted

### "No text selected"
- Make sure text is highlighted before pressing `⌘⇧T`
- Grant Accessibility permission in System Settings
- Some apps (like secure forms) may block text selection

### Settings window doesn't appear
- Check if it's hidden behind other windows
- Try clicking "Show Settings" from the menu bar again
- Restart the app if the issue persists

### API errors
- Verify your Replicate API key is correct
- Check your internet connection
- Ensure you have API credits remaining ([check here](https://replicate.com/account))

## 🚀 Future Features

Planned improvements (contributions welcome!):

- [ ] Answer history with search
- [ ] Regional screenshot selection
- [ ] Dark mode support for overlay
- [ ] Export answers to PDF/Markdown
- [ ] RAG with local document database
- [ ] Multi-language OCR support
- [ ] Streaming responses (word-by-word)
- [ ] Study mode (hints instead of answers)

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/homework-copilot.git
cd homework-copilot

# Create a branch
git checkout -b feature/my-feature

# Make changes, test thoroughly

# Commit and push
git add .
git commit -m "Description of changes"
git push origin feature/my-feature
```
