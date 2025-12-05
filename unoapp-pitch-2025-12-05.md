# Shape Up Pitch: Unoapp

> **Purpose**: Proof-of-concept iOS app to validate whether a single iPhone + Moment fisheye lens can capture a full football pitch (180° FOV).

**Created**: 2025-12-05
**Author**: Kawus
**Status**: 🟡 Draft

---

## 1. Problem

**The situation today:**

We need to validate whether a single iPhone with an attached Moment fisheye lens can capture an entire football pitch in one shot. The native iOS Camera app's built-in stabilization crops the field of view, which defeats the purpose of using the ultrawide + fisheye combination. We can't get the raw, maximum FOV footage needed to prove or disprove this assumption.

**Why this matters:**

This is a foundational hardware decision. If a single-phone solution works, it massively simplifies our capture setup. If it doesn't work, we need to plan for a two-phone solution — with all the added cost, complexity, and synchronization challenges that brings.

**What's at stake:** 1 phone vs 2 phones — a fundamental architectural decision for the larger project.

---

## 2. Appetite

**Time Budget**: 🎯 **Standard Cycle (4-6 weeks)**

**Why this appetite?**

This isn't just a quick test — we need to stress-test the solution across different conditions (cloudy, sunny, low-light) to truly validate whether the single-lens approach is viable. A single happy-path test could be misleading. The potential payoff (simplifying from 2 phones to 1) justifies the investment.

**If we had less time:** We'd focus solely on proving maximum FOV capture works, cutting the condition presets.

**Circuit Breaker**: 🔴 If this project runs over appetite, we ship what we have or kill it. No extensions.

---

## 3. Solution

### Core Elements

**Screen 1: Viewfinder/Recording**
- Full-screen live preview showing raw fisheye distortion (what you see is what you get)
- Three preset buttons: **Cloudy / Sunny / Low-light** — AI-assisted camera settings (exposure, ISO, white balance determined during build)
- Big, obvious record button — start/stop
- Navigation to recordings list

**Screen 2: Recordings List**
- Simple list view: thumbnail + date
- Tap to rename recordings
- Tap to open playback

**Screen 3: Playback**
- Watch the recording
- Export to Camera Roll

### Technical Constraints
- **Lens**: Hardcoded to ultrawide (no lens selection UI)
- **Stabilization**: Completely disabled for maximum FOV
- **Quality**: 4K 30fps (good balance of quality and file size)
- **No audio**: Video only for v1

### Key Trade-offs

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Lens selection | Hardcoded ultrawide | Simplicity — this PoC is specifically about ultrawide + fisheye |
| Video format | 4K 30fps | Sweet spot for quality vs. file size, not raw |
| Presets | 3 simple buttons | User-friendly, AI helps determine optimal settings |
| Stabilization | Off | Maximum FOV is the whole point |

---

## 4. Rabbit Holes

### Identified Risks

| Risk | Level | Notes |
|------|-------|-------|
| iOS camera APIs / disabling stabilization | 🟢 Low | Confirmed possible, prior iOS experience |
| 180° FOV with Moment lens | 🟢 Low | Moment specs confirm 180° |
| Preset tuning complexity | 🟢 Low | Keep simple, AI-assisted during build |
| Video file sizes | 🟢 Low | 4K 30fps is standard, manageable |
| Testing access (football pitches) | 🟢 Low | Pitches are nearby |

### Technical Decisions Made

- Ultrawide lens hardcoded (no runtime selection)
- Stabilization disabled at camera API level
- 4K 30fps output format
- Export directly to Camera Roll (standard iOS sharing)

---

## 5. No-Gos

### Explicitly Out of Scope

- ❌ **Lens selection UI** — hardcoded to ultrawide
- ❌ **Raw video recording** — using 4K 30fps instead
- ❌ **Multiple stability options** — just disabled entirely
- ❌ **Any post-processing** — no de-warping, stitching, or color correction
- ❌ **Audio recording** — video only, add later if needed
- ❌ **Android version**
- ❌ **Cloud sync / backup**
- ❌ **Video editing features**

### Future Considerations (if PoC succeeds)

- Lens selection for different use cases
- Audio capture
- Additional presets or manual controls
- Evolve into a more robust recording tool

---

## Decision

**Betting Table Outcome**: [To be filled after review]
- [ ] ✅ **Approved** - Scheduled for [Cycle/Sprint]
- [ ] 🤔 **Needs Revision** - [What needs to change]
- [ ] ⏸️ **Deferred** - [Why we're waiting]
- [ ] 🚫 **Rejected** - [Why this isn't worth pursuing]

**Team Assignment**: [TBD]

**Success Metrics**:
- Can we capture a full football pitch (180° FOV) with acceptable quality?
- Does it work reliably across cloudy, sunny, and low-light conditions?
- Binary outcome: 1 phone is viable, or 2 phones are required

---

## Notes & Context

- **Hardware**: iPhone + Moment fisheye lens attachment
- **Purpose**: Internal proof-of-concept, not user-facing product (yet)
- **Next step if successful**: Continue building on this foundation
- **Next step if unsuccessful**: Plan for two-phone capture solution
