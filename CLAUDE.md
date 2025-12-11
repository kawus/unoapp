# Unoapp - Project Documentation

## Overview

Proof-of-concept iOS app to validate whether a single iPhone + Moment fisheye lens can capture a full football pitch (180° FOV).

**Target**: iOS 26 with Liquid Glass design
**Framework**: SwiftUI + AVFoundation
**Status**: Iteration 6 Complete (Max FOV Mode)

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
- Grid toggle button in bottom toolbar (next to record button, opposite thumbnail)
- Tap a zone to set where camera calculates auto-exposure
- Each preset has a default zone (floodlight defaults to bottom-center to avoid bright lights)
- Switching presets resets zone to that preset's default
- Uses AVFoundation `exposurePointOfInterest` API

**Recording Metadata (Iteration 3.5)**
- Camera settings saved with each recording as JSON sidecar file
- Stores: preset, exposure bias, metering zone, ISO, white balance
- Recordings list shows summary (e.g., "Floodlight • -1.0 EV")
- Playback view shows full settings in header area
- Legacy recordings without metadata still work
- JSON is human-readable for field testing debugging

**Video Orientation Fix (Iteration 3.6)**
- Recording embeds correct rotation metadata based on device orientation
- Videos play back correctly regardless of recording orientation
- Thumbnails display with correct orientation
- Uses AVCaptureConnection.videoRotationAngle at recording start
- Playback uses AVPlayerViewController for proper transform handling

**Metering Zone Metadata Fix (Iteration 3.7)**
- Fixed: Metadata now saves user's actual metering zone selection, not preset default
- Added `selectedMeteringZone` property to track zone independently from presets
- Zone resets to preset default when switching presets
- Manual zone changes within a preset are correctly saved to recording metadata

**UX Polish (Iteration 4)**
- Haptic feedback on record button (medium impact on tap, rigid impact on state change)
- Press feedback animation on all interactive buttons (scale to 90-92% on press)
- Spring animations on selection state changes (presets, zones, grid toggle)
- Consistent animation patterns across: PresetButton, ZoneCell, StepperButton, GridToggleButton, ThumbnailButton

**Lens Selector (Iteration 5)**
- Switch between ultrawide (0.5x) and wide (1x) camera lenses
- Compact segmented selector in bottom toolbar (above record button in portrait, beside in landscape)
- Preserves current preset and exposure settings when switching lenses
- Disabled during recording (cannot switch cameras mid-record)
- Lens choice saved to recording metadata (e.g., "0.5x • Floodlight • -1.0 EV")
- Stabilization stays OFF for both lenses to maintain maximum FOV
- Brief preview interruption (~0.2-0.5s) during lens switch is normal

**Max FOV Mode (Iteration 6)**
- Toggle in preset bar (orange "FOV" button) to maximize field of view for external fisheye lenses
- **Disables Geometric Distortion Correction (GDC)** - iOS normally "flattens" lens edges, removing fisheye FOV
- Uses `inputPriority` session preset for maximum format control
- Selects camera format with highest `videoFieldOfView` value
- May result in non-4K resolution when prioritizing FOV over quality
- Disabled during recording (cannot toggle mid-record)
- Max FOV state saved to recording metadata (e.g., "0.5x • Floodlight • -1.0 EV • MaxFOV")
- Expected to unlock ~15-25° additional FOV with T-Series/Moment fisheye lenses
- Comprehensive debug logging: prints available formats, GDC support, and selected format on startup

**UI Polish (Iteration 6.1)**
- Compact preset bar: smaller buttons fit on one line with FOV toggle
- Fixed landscape lens selector position: now appears LEFT of record button (was incorrectly on right)
- Portrait lens selector remains above record button

**Bluetooth Remote Support (Iteration 6.2)**
- Volume buttons now start/stop recording (instead of changing volume)
- Bluetooth camera remotes work for hands-free recording
- iPhone 16 Camera Control button supported
- Action button supported
- Uses Apple's `.onCameraCaptureEvent` API (iOS 17.2+)

### File Structure

```
unoapp/
├── unoappApp.swift              # App entry point + permission routing
├── Camera/
│   ├── CameraManager.swift      # AVFoundation camera control
│   └── CameraPreviewView.swift  # Preview layer + rotation handling
├── Models/
│   ├── Recording.swift          # Recording data model
│   ├── RecordingMetadata.swift  # Settings metadata saved with recordings
│   ├── CameraPreset.swift       # Lighting preset enum (Cloudy/Sunny/Floodlight/Manual)
│   ├── CameraLens.swift         # Lens enum (ultraWide/wide) with AVFoundation device types
│   ├── CameraSettings.swift     # Camera settings struct with preset defaults
│   └── MeteringZone.swift       # 3x3 metering zone enum with AVFoundation coordinates
├── Services/
│   ├── OrientationManager.swift # Device orientation tracking
│   └── RecordingStorage.swift   # File scanning, thumbnails, export
├── ViewModels/
│   └── CameraViewModel.swift    # State management
└── Views/
    ├── ViewfinderView.swift     # Main camera UI
    ├── AdaptiveToolbar.swift    # Orientation-aware toolbar (record, thumbnail, lens, grid)
    ├── LensSelectorView.swift   # Compact 0.5x/1x lens selector
    ├── PresetBar.swift          # Lighting preset buttons
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

### Iteration 7: Field Testing & Refinement

- Field testing with T-Series/Moment fisheye lens (compare Max FOV ON vs OFF)
- Measure actual FOV achieved (target: 185-200° with Max FOV enabled)
- Tune preset values based on real conditions (cloudy UK days, stadium floodlights)
- Add full ISO/WB control if exposure bias alone isn't sufficient
- Edge case handling (interruptions, storage full, low battery)
- Consider 4:3 capture mode for maximum vertical FOV
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

### Max FOV Mode Technical Notes

**Why iOS limits fisheye FOV by default:**
1. **Geometric Distortion Correction (GDC)** - iOS "flattens" lens edges to make images look natural
2. **Session preset cropping** - `.high` preset applies Apple's processing pipeline
3. **Format selection** - Default doesn't prioritize maximum FOV formats
4. **Video stabilization** - Crops frame (we already disable this)

**What Max FOV mode does:**

```swift
// 1. Disable geometric distortion correction
device.isGeometricDistortionCorrectionEnabled = false

// 2. Use inputPriority for maximum control
session.sessionPreset = .inputPriority

// 3. Select format with highest videoFieldOfView
let bestFormat = device.formats.max {
    $0.videoFieldOfView < $1.videoFieldOfView
}
device.activeFormat = bestFormat
```

**Expected results:**
- Standard mode: ~170° with T-Series fisheye
- Max FOV mode: ~185-195° (hardware limit)
- Perfect 200° not achievable due to unavoidable 16:9 crop + sensor readout limitations

**Trade-offs:**
- May result in lower resolution (non-4K)
- Raw fisheye distortion visible (no correction applied)
- Ideal for external fisheye lenses; may look unusual without one

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

Metadata JSON sidecars are saved alongside:
`Documents/unoapp_YYYY-MM-DD_HH-mm-ss.json`

Example metadata file:
```json
{
  "preset": "floodlight",
  "exposureBias": -1.0,
  "meteringZone": "bottomCenter",
  "iso": 800,
  "whiteBalance": 4000,
  "recordedAt": "2025-12-08T14:30:00Z",
  "lens": "ultraWide",
  "maxFOV": true
}
```

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
- [ ] Portrait recordings play back correctly
- [ ] Landscape-left recordings play back correctly
- [ ] Landscape-right recordings play back correctly
- [ ] Thumbnails show correct orientation for all recordings

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
- [ ] Grid toggle button visible in bottom toolbar (right side in portrait, bottom in landscape)
- [ ] Tapping grid button shows/hides 3x3 overlay
- [ ] Tapping a zone selects it (visual feedback)
- [ ] Selected zone affects auto-exposure calculations
- [ ] Tap preview to hide grid (same as manual controls)
- [ ] Grid works in both portrait and landscape
- [ ] Floodlight preset defaults to bottom-center zone

**Recording Metadata**
- [ ] Recording creates both .mov and .json files
- [ ] JSON contains correct preset, exposure, metering zone
- [ ] Manual zone change (e.g., Sunny + bottom-center) saves correctly in metadata
- [ ] Recordings list shows settings summary (e.g., "Floodlight • -1.0 EV")
- [ ] Legacy recordings without JSON display gracefully
- [ ] Playback view shows full settings in header
- [ ] Deleting recording removes both .mov and .json files

**UX Polish (Iteration 4)**
- [ ] Record button gives haptic feedback on tap
- [ ] Record start AND stop both have haptic
- [ ] Preset buttons scale down on press
- [ ] Preset selection animates smoothly
- [ ] Grid toggle scales on press
- [ ] Zone cells scale/fade on press
- [ ] Zone selection animates smoothly
- [ ] Stepper buttons scale on press (when enabled)
- [ ] Thumbnail button scales on press
- [ ] All animations feel responsive (not sluggish)
- [ ] No animation conflicts or glitches in landscape

**Lens Selector (Iteration 5)**
- [ ] Lens selector visible above record button (portrait) or beside (landscape)
- [ ] Tapping 0.5 selects ultrawide camera
- [ ] Tapping 1 selects wide camera
- [ ] Lens switch causes brief preview interruption (expected)
- [ ] Current preset/exposure preserved after lens switch
- [ ] Lens selector disabled (dimmed) during recording
- [ ] Cannot switch lenses while recording
- [ ] Lens selector has haptic feedback on selection
- [ ] Lens selector buttons have press animation
- [ ] Recording metadata shows lens info (e.g., "0.5x • Floodlight • -1.0 EV")
- [ ] Playback view shows lens in settings header
- [ ] Stabilization stays OFF for both lenses

**Max FOV Mode (Iteration 6)**
- [ ] FOV toggle visible in preset bar (orange when enabled)
- [ ] FOV toggle disabled (dimmed) during recording
- [ ] Toggling FOV causes brief preview reconfiguration (expected)
- [ ] FOV toggle has haptic feedback
- [ ] FOV toggle has press animation
- [ ] Console prints format info when Max FOV enabled (for debugging)
- [ ] Recording metadata shows "MaxFOV" when enabled
- [ ] Playback view shows "Max FOV: On" in settings
- [ ] With fisheye lens: visible FOV increase when Max FOV enabled
- [ ] Without fisheye: more distortion visible at edges (expected)
- [ ] Stabilization stays OFF in both modes

---

## References

- [iOS 26 Liquid Glass HIG](https://developer.apple.com/design/human-interface-guidelines/)
- [AVCam Sample Project](https://developer.apple.com/documentation/avfoundation/avcam-building-a-camera-app)
- [Video Stabilization API](https://developer.apple.com/documentation/avfoundation/avcaptureconnection/preferredvideostabilizationmode)
- [Exposure Point of Interest](https://developer.apple.com/documentation/avfoundation/avcapturedevice/exposurepointofinterest)
- [Geometric Distortion Correction](https://developer.apple.com/documentation/avfoundation/avcapturedevice/isgeometricdistortioncorrectionenabled)
- [Video Field of View](https://developer.apple.com/documentation/avfoundation/avcapturedevice/format/videofieldofview)
