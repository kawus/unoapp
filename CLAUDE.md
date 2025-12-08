# Unoapp - Project Documentation

## Overview

Proof-of-concept iOS app to validate whether a single iPhone + Moment fisheye lens can capture a full football pitch (180° FOV).

**Target**: iOS 26 with Liquid Glass design
**Framework**: SwiftUI + AVFoundation
**Status**: Iteration 2 Complete (Landscape + Recordings)

---

## Current State

### Implemented Features

**Core Camera (Iteration 1)**
- Full-screen live preview of ultrawide camera
- Start/stop video recording with visual feedback
- Hardcoded to `.builtInUltraWideCamera`
- Stabilization disabled for maximum FOV
- 4K 30fps recording
- Permission handling with Settings deep link

**Landscape + Recordings (Iteration 2)**
- Landscape orientation support with adaptive UI
- Camera preview rotates correctly in all orientations
- Record button centered, thumbnail button offset
- In-app recordings list with thumbnails
- Video playback with native controls
- Swipe-to-delete recordings
- Export to Camera Roll

### File Structure

```
unoapp/
├── unoappApp.swift              # App entry point + permission routing
├── Camera/
│   ├── CameraManager.swift      # AVFoundation camera control
│   └── CameraPreviewView.swift  # Preview layer + rotation handling
├── Models/
│   └── Recording.swift          # Recording data model
├── Services/
│   ├── OrientationManager.swift # Device orientation tracking
│   └── RecordingStorage.swift   # File scanning, thumbnails, export
├── ViewModels/
│   └── CameraViewModel.swift    # State management
└── Views/
    ├── ViewfinderView.swift     # Main camera UI
    ├── AdaptiveToolbar.swift    # Orientation-aware control positioning
    ├── RecordingsListView.swift # Recordings list with thumbnails
    ├── PlaybackView.swift       # Video playback + export
    ├── ThumbnailButton.swift    # Thumbnail button component
    └── PermissionView.swift     # Permission denied screen
```

Note: Camera/photo permissions are in project build settings (INFOPLIST_KEY_*), not a separate Info.plist.

---

## Next Steps

### Iteration 3: Lighting Presets

Add Cloudy/Sunny/Low-light preset buttons with hardcoded camera settings:

- `CameraPreset.swift` - Preset enum
- `CameraConfiguration.swift` - Hardcoded ISO/exposure/WB values
- Add preset buttons to AdaptiveToolbar

**Preset Values (to be tuned):**
- Cloudy: Higher ISO (~400), cooler WB (~6000K), longer exposure
- Sunny: Lower ISO (~100), neutral WB (~5500K), shorter exposure
- Low-light: Max ISO (~1600), warm WB (~4000K), longest exposure

### Iteration 4: Polish & Field Testing

- Edge case handling (interruptions, storage full, low battery)
- Haptic feedback on record start/stop
- Recording file naming/renaming
- Field testing across lighting conditions
- Moment fisheye lens validation

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

**Camera & Recording**
- [ ] Camera preview shows full ultrawide FOV
- [ ] Recording starts/stops correctly
- [ ] Recordings save to Documents directory
- [ ] Permission denied shows Settings link
- [ ] With Moment fisheye: Full 180° pitch visible

**Landscape & Orientation**
- [ ] UI adapts when rotating to landscape
- [ ] Camera preview rotates correctly (not upside down)
- [ ] Record button stays centered in both orientations
- [ ] Thumbnail button stays accessible in both orientations

**Recordings List**
- [ ] Thumbnail button shows most recent recording
- [ ] Tapping thumbnail opens recordings list
- [ ] List shows all recordings with thumbnails
- [ ] Tapping recording opens playback
- [ ] Swipe-to-delete works
- [ ] Export to Camera Roll works
- [ ] Empty state shows when no recordings

---

## References

- [iOS 26 Liquid Glass HIG](https://developer.apple.com/design/human-interface-guidelines/)
- [AVCam Sample Project](https://developer.apple.com/documentation/avfoundation/avcam-building-a-camera-app)
- [Video Stabilization API](https://developer.apple.com/documentation/avfoundation/avcaptureconnection/preferredvideostabilizationmode)
