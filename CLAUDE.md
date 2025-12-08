# Unoapp - Project Documentation

## Overview

Proof-of-concept iOS app to validate whether a single iPhone + Moment fisheye lens can capture a full football pitch (180° FOV).

**Target**: iOS 26 with Liquid Glass design
**Framework**: SwiftUI + AVFoundation
**Status**: Iteration 3 Complete (Lighting Presets + Metering Zones)

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

**Lighting Presets (Iteration 3)**
- 4 lighting presets: Cloudy, Sunny, Floodlight, Manual
- Preset bar at top of screen (always visible, transparent)
- Manual mode shows stepper controls with visible values (ISO, EXP, WB)
- Tap camera preview to collapse manual controls (stays in manual mode)
- Currently implements exposure bias - simplest API that works with auto-exposure
- Values displayed for field testing notes

**Metering Zone Control (Iteration 3)**
- 3x3 grid overlay for selecting exposure metering zone
- Toggle button in preset bar (grid icon) to show/hide overlay
- Tap a zone to set where camera calculates auto-exposure
- Each preset has a default zone (floodlight defaults to bottom-center to avoid bright lights)
- Zone selection persists when switching presets
- Uses AVFoundation `exposurePointOfInterest` API

### File Structure

```
unoapp/
├── unoappApp.swift              # App entry point + permission routing
├── Camera/
│   ├── CameraManager.swift      # AVFoundation camera control
│   └── CameraPreviewView.swift  # Preview layer + rotation handling
├── Models/
│   ├── Recording.swift          # Recording data model
│   ├── CameraPreset.swift       # Lighting preset enum (Cloudy/Sunny/Floodlight/Manual)
│   ├── CameraSettings.swift     # Camera settings struct with preset defaults
│   └── MeteringZone.swift       # 3x3 metering zone enum with AVFoundation coordinates
├── Services/
│   ├── OrientationManager.swift # Device orientation tracking
│   └── RecordingStorage.swift   # File scanning, thumbnails, export
├── ViewModels/
│   └── CameraViewModel.swift    # State management
└── Views/
    ├── ViewfinderView.swift     # Main camera UI
    ├── AdaptiveToolbar.swift    # Orientation-aware control positioning
    ├── PresetBar.swift          # Lighting preset buttons + grid toggle
    ├── ManualControlsView.swift # Stepper controls for manual mode
    ├── MeteringGridOverlay.swift # 3x3 tappable zone selection grid
    ├── RecordingsListView.swift # Recordings list with thumbnails
    ├── PlaybackView.swift       # Video playback + export
    ├── ThumbnailButton.swift    # Thumbnail button component
    └── PermissionView.swift     # Permission denied screen
```

Note: Camera/photo permissions are in project build settings (INFOPLIST_KEY_*), not a separate Info.plist.

---

## Next Steps

### Iteration 4: Polish & Field Testing

- Field testing with Moment fisheye lens
- Tune preset values based on real conditions (cloudy UK days, stadium floodlights)
- Add full ISO/WB control if exposure bias alone isn't sufficient
- Edge case handling (interruptions, storage full, low battery)
- Haptic feedback on record start/stop
- Recording file naming/renaming

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

### Lighting Preset Values

Current defaults (to be tuned during field testing):

| Preset | ISO | Exposure Bias | White Balance | Metering Zone |
|--------|-----|---------------|---------------|---------------|
| Cloudy | 400 | +0.5 EV | 6500K | Center |
| Sunny | 100 | -0.5 EV | 5500K | Center |
| Floodlight | 800 | **-1.0 EV** | 4000K | Bottom-Center |
| Manual | 400 | 0 EV | 5500K | Center |

**Note:** Currently only exposure bias and metering zone are applied. ISO and WB values are stored for future implementation if needed.

### Metering Zone Technical Notes

Uses AVFoundation `exposurePointOfInterest` API:

```swift
device.exposurePointOfInterest = zone.point
device.exposureMode = .continuousAutoExposure
```

**Coordinate system:** {0,0} = top-left, {1,1} = bottom-right (landscape-right orientation)

**Known iOS bug:** Avoid using exactly (0.5, 0.5) for center - can cause issues on some devices. Use (0.51, 0.51) instead.

**Zone positions:** Each zone maps to 1/3 intervals:
- Row/Col 0: 0.167 (1/6 from edge)
- Row/Col 1: 0.51 (center, avoiding 0.5)
- Row/Col 2: 0.833 (5/6 from edge)

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

**Lighting Presets**
- [ ] Preset bar visible at top of screen (no background)
- [ ] Tapping preset switches selection
- [ ] Manual mode shows stepper controls
- [ ] Tap preview to collapse manual controls (stays in manual mode)
- [ ] Tap Manual again to reopen controls
- [ ] Steppers adjust values within valid ranges
- [ ] Values display correctly for note-taking
- [ ] Exposure changes visible in preview

**Metering Grid**
- [ ] Grid toggle button visible in preset bar (grid icon)
- [ ] Tapping grid button shows/hides 3x3 overlay
- [ ] Tapping a zone selects it (visual feedback)
- [ ] Selected zone affects auto-exposure calculations
- [ ] Tap preview to hide grid (same as manual controls)
- [ ] Grid works in both portrait and landscape
- [ ] Floodlight preset defaults to bottom-center zone

---

## References

- [iOS 26 Liquid Glass HIG](https://developer.apple.com/design/human-interface-guidelines/)
- [AVCam Sample Project](https://developer.apple.com/documentation/avfoundation/avcam-building-a-camera-app)
- [Video Stabilization API](https://developer.apple.com/documentation/avfoundation/avcaptureconnection/preferredvideostabilizationmode)
- [Exposure Point of Interest](https://developer.apple.com/documentation/avfoundation/avcapturedevice/exposurepointofinterest)
