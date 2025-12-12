# Unoapp Lighting Preset Reference

Quick reference for camera presets and metering zones during field testing.

---

## Preset Values

| Preset | ISO | Exposure Bias | White Balance | Default Metering Zone |
|--------|-----|---------------|---------------|----------------------|
| **Cloudy** | 400 | +0.5 EV | 6500K (warm) | Center |
| **Sunny** | 100 | -0.5 EV | 5500K (neutral) | Center |
| **Floodlight** | 800 | -1.0 EV | 4000K (cool) | Bottom-Center |
| **Manual** | 400 | 0 EV | 5500K | Center |

### Notes on Presets

- **Cloudy**: Higher ISO and positive exposure for overcast UK conditions. Warm white balance compensates for blue-ish light.
- **Sunny**: Low ISO prevents overexposure. Negative bias handles bright highlights.
- **Floodlight**: Cool white balance counters orange sodium lamps. Negative exposure prevents blown-out lights. Meters from bottom of frame to avoid bright overhead lights.
- **Manual**: Starting point for custom adjustments.

---

## Metering Zone Grid

The camera uses the selected zone to calculate auto-exposure. This is where the camera "looks" to determine brightness.

```
┌─────────────┬─────────────┬─────────────┐
│             │             │             │
│   Top-Left  │  Top-Center │  Top-Right  │
│     (TL)    │     (T)     │     (TR)    │
│             │             │             │
├─────────────┼─────────────┼─────────────┤
│             │             │             │
│ Middle-Left │   CENTER    │ Middle-Right│
│     (L)     │     (C)     │     (R)     │
│             │             │             │
├─────────────┼─────────────┼─────────────┤
│             │             │             │
│ Bottom-Left │Bottom-Center│ Bottom-Right│
│     (BL)    │     (B)     │     (BR)    │
│             │             │             │
└─────────────┴─────────────┴─────────────┘
```

### When to Use Each Zone

| Zone | Best For |
|------|----------|
| **Top** | Sky/floodlights visible, want to expose for sky |
| **Center** | General use, balanced exposure |
| **Bottom** | Pitch/ground level, avoid bright lights at top |
| **Left/Right** | Action concentrated on one side of pitch |

### Floodlight Preset Special Case

The Floodlight preset defaults to **Bottom-Center** metering because:
- Stadium lights are typically overhead (top of frame)
- Metering on the pitch (bottom) prevents the bright lights from fooling auto-exposure
- Results in better-exposed players and pitch, even if lights are slightly blown out

---

## Value Ranges (Manual Mode)

| Setting | Range | Step |
|---------|-------|------|
| ISO | 100 - 1600 | 100 |
| Exposure Bias | -2.0 to +2.0 EV | 0.5 |
| White Balance | 3000K - 7000K | 500K |

---

## FOV Maximization Settings

For external fisheye lenses (T-Series/Moment), use these settings to capture maximum field of view:

| Setting | Location | Recommended |
|---------|----------|-------------|
| **Max FOV** | Preset bar (orange "FOV" button) | ON |
| **Aspect Ratio** | Preset bar (blue "4:3" button) | 4:3 |
| **Lens** | Bottom toolbar | Depends on fisheye adapter |

### Why These Settings?

- **Max FOV ON**: Disables iOS geometric distortion correction (GDC) which crops fisheye edges
- **4:3 Aspect**: Captures more of the circular fisheye projection than 16:9
- **Lens Choice**: T-Series fisheye is designed for 1x Wide camera (better sensor)

### Debug Overlay

**Triple-tap the camera preview** to show/hide debug info:

- FOV (degrees) - aim for highest value
- GDC status - should show "Off" for max FOV
- Zoom factor - should be 1.0x (no digital crop)
- Resolution and aspect ratio
- Stabilization - should be "Off"

Green highlights = good for FOV. Red highlights = reducing FOV.

---

## Field Testing Notes

Use this section to record what works during actual filming:

### Date: ___________

**Conditions:**

**Preset Used:**

**Adjustments Made:**

**Results:**

---

### Date: ___________

**Conditions:**

**Preset Used:**

**Adjustments Made:**

**Results:**

---
