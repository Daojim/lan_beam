# 📡 LAN Beam

> **Fast, simple, and secure file transfers across your local network**

LAN Beam is a Windows Flutter application that enables seamless file sharing between devices on the same Wi-Fi network. No internet required, no cloud storage needed - just pure peer-to-peer file transfer with support for files up to 10GB.

![Version](https://img.shields.io/badge/version-0.2.1-blue.svg)
![Platform](https://img.shields.io/badge/platform-Windows-lightgrey.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## ✨ Features

### 🚀 Current Capabilities (v0.2.1)

- **📁 Smart File Management**

  - Automatic file collision handling with incremental naming (`document.pdf` → `document-1.pdf`)
  - Support for all file types up to 10GB
  - Intelligent file type detection
  - **NEW**: Enhanced partial file cleanup with proper Windows file handle management
  - **NEW**: Fixed "file in use" errors - can now delete partial files while app is running

- **🔍 Auto-Discovery**

  - Automatic device discovery on local network
  - Real-time availability status
  - Custom device naming

- **📊 Transfer Management**

  - Real-time progress tracking with visual indicators
  - **IMPROVED**: Smart cancel behavior with immediate cleanup and better user flow
  - **IMPROVED**: Enhanced cancellation detection - sender cancellations now properly detected by receiver
  - **IMPROVED**: Smoother progress synchronization with faster updates (50ms intervals)
  - Automatic partial file cleanup on failed transfers
  - Direction-aware navigation (sending vs receiving)

- **🎯 Enhanced UX**

  - Toast notifications for real-time feedback
  - Responsive UI with fixed headers and scrollable content
  - Smart state management across different screens
  - Intuitive accept/reject flow for incoming transfers
  - **NEW**: Improved cancellation flow - clear "CANCELLED" status with one-click return to home
  - **NEW**: Enhanced visual feedback with color-coded status indicators

- **⚙️ Customizable Settings**
  - Configurable device name
  - Custom save folder with browse functionality
  - Testing mode for self-transfers
  - Persistent settings across sessions

### 🔒 Security & Reliability

- **Local Network Only** - Files never leave your network
- **No Cloud Storage** - Direct peer-to-peer transfers
- **Enhanced Cleanup** - Robust file handle management prevents system locks
- **Improved Navigation** - Seamless transfer cancellation without UI confusion
- **Better Error Handling** - Enhanced socket disconnection detection and recovery

## 🚀 Getting Started

### Installation

#### Windows

1. Download the latest release from [Releases](https://github.com/Daojim/lan_beam/releases)
2. Extract `lan_beam_v0.2.1_windows.zip`
3. Run `lan_beam.exe`

#### Building from Source

```bash
# Clone the repository
git clone https://github.com/Daojim/lan_beam.git
cd lan_beam

# Get dependencies
flutter pub get

# Build for Windows
flutter build windows
```

### Usage

1. **Setup**

   - Launch LAN Beam on all devices
   - Configure device names in Settings
   - Set your preferred save folder

2. **Sending Files**

   - Choose a file using the file picker
   - Select a target device from the discovered list
   - Monitor transfer progress

3. **Receiving Files**
   - Keep LAN Beam running to listen for incoming transfers
   - Accept or reject incoming file requests
   - Files are automatically saved to your configured folder

## � Changelog

### v0.2.1 - File Transfer Reliability & Cancellation Fixes

**🔧 Critical Fixes:**

- Fixed "file in use" errors preventing deletion of partial files after cancellation
- Resolved Windows file handle locks that required closing the app to delete files
- Fixed receiver-side cancellation flow that forced users through multiple screens
- Fixed sender cancellation detection - receiver now properly detects when sender cancels

**🚀 Improvements:**

- Enhanced file handle management with proper cleanup sequence and retry logic
- Improved cancellation experience with clear visual feedback and one-click navigation
- Better progress synchronization with smoother updates (50ms intervals)
- Enhanced socket disconnection detection and automatic cleanup

### v0.2.0 - Major Feature Release

- Smart file collision handling with incremental naming
- Enhanced transfer management with real-time progress tracking
- Improved UI/UX with responsive design and toast notifications
- Direction-aware navigation and smart state management
- Comprehensive settings with custom save folders and device naming

## �🛣️ Roadmap

### 📋 Planned Features

#### 🔜 Coming Soon (v0.3.0)

- **📂 Folder Transfer Support** - Send entire directories with structure preservation
- **🔄 Batch Transfers** - Queue multiple files for sequential transfer

#### 🚧 Future Releases

- **� Mobile App** - Android version with full feature parity
- **�🔐 Optional Encryption** - End-to-end encryption for sensitive files
- **📈 Transfer History** - Log of recent transfers with retry capability
- **🎨 Themes & Customization** - Dark mode and custom UI themes
- **⚡ Performance Optimizations** - Faster transfers and lower resource usage

#### 🧪 Experimental Features Under Consideration

- **📋 Clipboard Sync** - Share text and images via clipboard

## 🏗️ Technical Details

### Architecture

- **Frontend**: Flutter (Dart)
- **Networking**: UDP discovery + TCP file transfer
- **State Management**: Provider pattern
- **File I/O**: Native Dart file operations

### Network Protocol

- **Discovery**: UDP broadcast on local network
- **Transfer**: TCP stream with metadata exchange and enhanced disconnection detection
- **Ports**: UDP 65000, TCP 65001
- **Transfer Chunks**: Adaptive chunk sizes (4KB-2MB) for optimal performance
- **Progress Updates**: Real-time synchronization with 50ms intervals
- **Cleanup**: Robust file handle management with retry logic and proper closure

### System Requirements

- **Windows**: Windows 10/11
- **Network**: Same Wi-Fi network for all devices
- **Storage**: Available disk space for received files
- **Firewall**: May require firewall exceptions for first run

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. **🐛 Bug Reports** - Found an issue? [Open an issue](https://github.com/Daojim/lan_beam/issues)
2. **🔧 Code Contributions** - Fork, improve, and submit a PR
3. **📖 Documentation** - Help improve docs and examples

### Development Setup

```bash
# Prerequisites
flutter --version  # Ensure Flutter 3.0+

# Setup
git clone https://github.com/Daojim/lan_beam.git
cd lan_beam
flutter pub get
flutter run -d windows
```

## Acknowledgments

- Built with [Flutter](https://flutter.dev/) for future cross-platform compatibility
- Inspired by the need for simple, secure local file sharing
- Thanks to the open-source community for tools and inspiration

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/Daojim/lan_beam/issues)
- **Email**: [Contact Developer](mailto:daojim.dev@gmail.com)
