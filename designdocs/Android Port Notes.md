# Android Port Development Notes

## Overview

LAN Beam Android port planning and implementation notes. The app is built with Flutter, so most code will be reusable.

**Estimated Timeline: 2-3 weeks** (reduced from 4 weeks due to package availability)

## Current Architecture Advantages ✅

### Already Cross-Platform

- **Flutter UI**: All widgets and screens will work unchanged
- **Provider State Management**: Works identically on Android
- **file_picker ^6.1.5**: Already handles Android Storage Access Framework
- **Dart Socket/File APIs**: Core networking and file operations are cross-platform
- **Transfer Protocol**: UDP discovery + TCP transfer will work unchanged

### Existing Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.5 # ✅ Cross-platform
  file_picker: ^6.1.5 # ✅ Cross-platform (BIG advantage!)
  async: ^2.9.0 # ✅ Cross-platform
  cupertino_icons: ^1.0.8 # ✅ Cross-platform
```

## Required Android Dependencies

### Essential Packages

```yaml
dependencies:
  # Core Android functionality
  path_provider: ^2.1.2 # Get proper Android storage paths
  permission_handler: ^11.3.1 # Handle runtime permissions (CRITICAL)

  # Background processing (GAME CHANGER)
  workmanager: ^0.5.2 # Background file transfers
  wakelock_plus: ^1.2.8 # Prevent sleep during transfers

  # User experience
  flutter_local_notifications: ^17.2.2 # Transfer progress notifications
  connectivity_plus: ^6.0.5 # Monitor WiFi changes
  device_info_plus: ^10.1.2 # Android version detection

  # Optional but helpful
  saf_util: ^1.0.0 # Storage Access Framework utilities
```

## Development Timeline

### Week 1: Core Setup & Basic Functionality

**Days 1-2: Project Setup**

- Run `flutter create --platforms android` to add Android support
- Add essential dependencies to pubspec.yaml
- Configure Android manifest permissions
- Test basic app launch on Android device/emulator

**Days 3-5: File Handling**

- Implement Android storage paths using `path_provider`
- Set up runtime permissions with `permission_handler`
- Test file picker functionality (should work unchanged)
- Verify file read/write operations

**Days 6-7: Network Testing**

- Test UDP discovery on Android
- Verify TCP file transfers work
- Check firewall/network permissions

### Week 2: Android-Specific Features

**Days 1-3: Background Processing**

- Implement `workmanager` for background file transfers
- Handle Android background execution limits
- Test file reception while app is backgrounded

**Days 4-5: Notifications & UX**

- Implement transfer progress notifications
- Handle Android-specific UI considerations
- Test different screen sizes and orientations

**Days 6-7: Permissions & Storage**

- Handle Android 11+ scoped storage properly
- Implement proper permission request flows
- Test on different Android versions

### Week 3: Polish & Testing

**Days 1-3: Edge Cases**

- Battery optimization handling
- Network state change handling
- App lifecycle management

**Days 4-5: Testing & Debugging**

- Test on multiple Android versions
- Performance optimization
- Memory usage validation

**Days 6-7: Final Polish**

- UI tweaks for Android Material Design
- Documentation updates
- Release preparation

## Technical Challenges & Solutions

### 1. Background File Transfers

**Challenge**: Android restricts background network activity
**Solution**: `workmanager` package handles background execution properly
**Time Saved**: ~1 week of custom implementation

### 2. Runtime Permissions

**Challenge**: Android storage/network permissions are complex
**Solution**: `permission_handler` abstracts all permission logic
**Time Saved**: ~3-4 days of custom permission handling

### 3. Storage Access (Android 11+)

**Challenge**: Scoped storage restrictions
**Solution**: `file_picker` already handles this + `saf_util` for advanced cases
**Time Saved**: ~1 week (this is a nightmare to implement manually)

### 4. File System Paths

**Challenge**: Different Android storage locations
**Solution**: `path_provider` gives proper Android paths
**Time Saved**: ~2-3 days

## Code Changes Required

### Minimal Changes Expected

- **UI/UX**: ~5% changes (Android Material Design tweaks)
- **Networking**: 0% changes (Dart sockets work identically)
- **File Operations**: ~10% changes (path handling only)
- **State Management**: 0% changes (Provider works unchanged)
- **Transfer Logic**: 0% changes (core algorithm unchanged)

### New Code Required

- Android manifest configuration
- Permission request workflows
- Background service setup
- Notification implementations
- Platform-specific file paths

## Testing Strategy

### Device Coverage

- **Android Versions**: 8.0+ (API 26+)
- **Screen Sizes**: Phone and tablet layouts
- **Network Types**: WiFi, mobile hotspot
- **Storage Types**: Internal storage, SD card (if accessible)

### Test Scenarios

1. **Basic Transfer**: File send/receive while app is foreground
2. **Background Reception**: Receive files while app is backgrounded
3. **Permission Handling**: Fresh install permission flows
4. **Network Changes**: WiFi disconnection/reconnection during transfer
5. **Battery Optimization**: App behavior with battery saver modes
6. **Large Files**: 10GB file transfer stress test
7. **Multiple Devices**: Android ↔ Windows transfers

## Performance Considerations

### Memory Management

- Android has stricter memory limits than Windows
- Large file transfers need efficient chunk handling
- Garbage collection during transfers

### Battery Usage

- Background transfers impact battery life
- Need proper wake lock management
- Consider transfer speed vs. power consumption

### Network Efficiency

- Android may have different network buffer sizes
- Mobile data awareness (even though app is WiFi-only)
- Connection stability on mobile devices

## Release Strategy

### Alpha Testing (Internal)

- Test on 2-3 Android devices
- Verify core functionality works
- Basic performance validation

### Beta Testing

- Small group of Android users
- Cross-platform testing (Android ↔ Windows)
- Feedback collection

### Production Release

- Simultaneous release with v0.3.0 or v0.4.0
- Updated documentation for Android
- Google Play Store consideration

## Future Considerations

### Cross-Platform Features

- Settings sync between devices
- Device discovery improvements
- Transfer history synchronization

### Android-Specific Enhancements

- Android Auto integration
- Tasker integration
- Android TV support
- Wear OS companion app

## Package Impact Analysis

### Time Savings by Package

- **workmanager**: Saves 1-2 weeks (background processing is complex)
- **permission_handler**: Saves 3-4 days (permission handling is tedious)
- **file_picker** (already have): Saves 1 week (storage access is painful)
- **flutter_local_notifications**: Saves 2-3 days (notification API is complex)
- **path_provider**: Saves 2-3 days (Android storage paths are confusing)

**Total Package Time Savings**: ~3-4 weeks
**Actual Development Time**: 2-3 weeks

## Resources & References

### Documentation

- [Flutter Android Integration](https://docs.flutter.dev/platform-integration/android)
- [Android Background Execution Limits](https://developer.android.com/about/versions/oreo/background)
- [Storage Access Framework](https://developer.android.com/guide/topics/providers/document-provider)

### Key Packages Documentation

- [workmanager](https://pub.dev/packages/workmanager)
- [permission_handler](https://pub.dev/packages/permission_handler)
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)

### Testing Tools

- Android Studio Emulator
- Physical Android devices (various versions)
- Firebase Test Lab (for broader device testing)

---

**Last Updated**: July 28, 2025
**Next Review**: Before starting v0.3.0 development
