# Unoapp - Project Documentation

## Overview

Proof-of-concept iOS app to validate whether a single iPhone + Moment fisheye lens can capture a full football pitch (180° FOV).

**Target**: iOS 26 with Liquid Glass design
**Framework**: SwiftUI + AVFoundation
**Status**: Iteration 1 (Walking Skeleton) Complete

---

## Current State

### Implemented (Iteration 1 - Walking Skeleton)

The core camera functionality is complete:

- **Camera Preview**: Full-screen live preview of ultrawide camera
- **Recording**: Start/stop video recording with visual feedback
- **Ultrawide Lens**: Hardcoded to `.builtInUltraWideCamera`
- **Stabilization Disabled**: `preferredVideoStabilizationMode = .off` for maximum FOV
- **4K 30fps**: Configured for quality/file size balance
- **Permission Handling**: Settings deep link when camera access denied
- **iOS 26 Styling**: Liquid Glass materials on floating controls

### File Structure

```
unoapp/
├── unoappApp.swift              # App entry point + permission routing
├── Camera/
│   ├── CameraManager.swift      # AVFoundation camera control
│   └── CameraPreviewView.swift  # UIViewRepresentable for preview
├── ViewModels/
│   └── CameraViewModel.swift    # State management
└── Views/
    ├── ViewfinderView.swift     # Main camera UI
    └── PermissionView.swift     # Permission denied screen
```

Note: Camera/photo permissions are in project build settings (INFOPLIST_KEY_*), not a separate Info.plist.

---

## Future Iterations

### Iteration 2: Lighting Presets (Pending)

Add Cloudy/Sunny/Low-light preset buttons with hardcoded camera settings:

- `CameraPreset.swift` - Preset enum
- `CameraConfiguration.swift` - Hardcoded ISO/exposure/WB values
- Update ViewfinderView with three preset buttons

**Preset Values (to be tuned):**
- Cloudy: Higher ISO (~400), cooler WB (~6000K), longer exposure
- Sunny: Lower ISO (~100), neutral WB (~5500K), shorter exposure
- Low-light: Max ISO (~1600), warm WB (~4000K), longest exposure

### Iteration 3: Recordings List + Playback (Pending)

- `Recording.swift` - Data model with metadata
- `RecordingStorage.swift` - File persistence & thumbnails
- `RecordingsListView.swift` - List UI with rename support
- `PlaybackView.swift` - Video player + export to Camera Roll

### Iteration 4: Polish & Field Testing (Pending)

- Liquid Glass refinements
- Edge case handling (interruptions, storage full)
- Field testing across lighting conditions

---

## Technical Notes

### Critical: Stabilization Must Stay Off

The entire purpose of this PoC is to capture maximum FOV. Video stabilization crops the image, defeating the purpose of the ultrawide + fisheye combination.

```swift
connection.preferredVideoStabilizationMode = .off
```

### Camera Configuration

```swift
// Ultrawide camera selection
AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back)

// 4K 30fps format
device.activeFormat = /* 3840x2160 format */
device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 30)
```

### Recordings Location

Videos are saved to the app's Documents directory:
`Documents/unoapp_YYYY-MM-DD_HH-mm-ss.mov`

---

## Testing Checklist

- [ ] Camera preview shows full ultrawide FOV
- [ ] Recording starts/stops correctly
- [ ] Recordings save to Documents directory
- [ ] Permission denied shows Settings link
- [ ] Settings link opens correct app settings page
- [ ] With Moment fisheye: Full 180° pitch visible

---

## References

- [iOS 26 Liquid Glass HIG](https://developer.apple.com/design/human-interface-guidelines/)
- [AVCam Sample Project](https://developer.apple.com/documentation/avfoundation/avcam-building-a-camera-app)
- [Video Stabilization API](https://developer.apple.com/documentation/avfoundation/avcaptureconnection/preferredvideostabilizationmode)
