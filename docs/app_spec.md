# Routine Timers - Garmin Watch App Specification

**Version:** 1.0.0-draft  
**Last Updated:** January 11, 2026  
**Target Platform:** Garmin Connect IQ (System 8+)  
**Language:** Monkey C  

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Product Vision](#product-vision)
3. [Target Devices](#target-devices)
4. [Core Features](#core-features)
5. [User Interface Design](#user-interface-design)
6. [Application Architecture](#application-architecture)
7. [Data Model](#data-model)
8. [Trigger Mechanisms](#trigger-mechanisms)
9. [Garmin Connect IQ Integration](#garmin-connect-iq-integration)
10. [Settings & Configuration](#settings--configuration)
11. [Freemium Model (Future)](#freemium-model-future)
12. [Technical Constraints & Considerations](#technical-constraints--considerations)
13. [Testing Strategy](#testing-strategy)
14. [Appendix](#appendix)

---

## Executive Summary

**Routine Timers** is a Garmin Connect IQ application designed to help users execute timed routines with multiple sequential steps. Users define routines (e.g., "Morning Routine") composed of ordered activities with specific durations. The app guides users through each step with visual countdown timers, haptic feedback, and audio alerts.

**Example Use Case:**
```
Morning Routine (Total: 27:00)
├── Scripture Study     20:00
├── Tidy up office       5:00
└── Fill up water bottle 2:00
```

---

## Product Vision

### Problem Statement
Many people struggle to maintain consistent routines due to poor time awareness. Existing timer apps require manual resets between activities, breaking flow and reducing adherence.

### Solution
A seamless, guided timer experience that:
- Automatically progresses through routine steps
- Provides clear visual hierarchy (current vs. upcoming activities)
- Supports multiple trigger mechanisms (manual, scheduled, event-based)
- Lives on the wrist for glanceable, always-available guidance

### Target Users
- Productivity enthusiasts with structured daily routines
- Athletes with warm-up/cool-down sequences
- Parents managing morning/bedtime routines
- Anyone seeking to build consistent habits

---

## Target Devices

### Phase 1 (Initial Release)
| Device | Display | Resolution | Display Type |
|--------|---------|------------|--------------|
| Fenix 7S | 1.2" | 240 × 240 | MIP |
| Fenix 7 | 1.3" | 260 × 260 | MIP |
| Fenix 7X | 1.4" | 280 × 280 | MIP |
| Fenix 8 (43mm) | 1.2" | 416 × 416 | AMOLED |
| Fenix 8 (47mm) | 1.3" | 454 × 454 | AMOLED |
| Fenix 8 (51mm) | 1.4" | 484 × 484 | AMOLED |

### Phase 2 (Future Expansion)
- Forerunner series (255, 265, 955, 965)
- Venu series (Venu 2, Venu 3)
- Enduro series
- Epix series

### Minimum API Level
- Connect IQ SDK 6.0+ (for background service support)
- System 8 recommended for enhanced Notifications API

---

## Core Features

### MVP Features (v1.0)

| Feature | Priority | Description |
|---------|----------|-------------|
| Routine Playback | P0 | Sequential timer execution with auto-advance |
| Manual Trigger | P0 | Start routine via app/widget launch |
| Step Navigation | P0 | Skip forward/back between steps |
| Pause/Resume | P0 | Pause and resume active routine |
| Haptic Alerts | P0 | Vibration at step transitions |
| Routine Editor (Phone) | P0 | Create/edit routines via Garmin Connect Mobile |
| Progress Visualization | P1 | Visual progress indicator for current step |
| Audio Tones | P1 | Optional audio alerts at transitions |
| Scheduled Trigger | P1 | Start routine at configured time |
| Routine Library | P1 | Store multiple routines on device |

### Post-MVP Features (v1.x+)

| Feature | Priority | Description |
|---------|----------|-------------|
| Event Trigger | P2 | Chain off wake alarm or other system events |
| Activity Integration | P2 | Log routine as Garmin activity |
| Complication/Glance | P2 | Quick-access from watch face |
| Routine Templates | P3 | Pre-built routines (Morning, Workout, etc.) |
| Statistics | P3 | Track routine completion rates |
| Watch-based Editor | P3 | Simple on-device routine editing |

---

## User Interface Design

### Design Principles
1. **Glanceable** - Current activity and time remaining visible in <1 second
2. **High Contrast** - Readable in bright sunlight (MIP) and dark rooms (AMOLED)
3. **Minimal Interaction** - Routine runs hands-free once started
4. **Consistent** - Familiar Garmin design language

### Color Palette
```
Primary Text:      White (#FFFFFF)
Secondary Text:    Light Gray (#AAAAAA)
Accent/Progress:   Garmin Blue (#00A0DD)
Warning (< 30s):   Orange (#FF8C00)
Alert (< 10s):     Red (#FF4444)
Background:        Black (#000000)
```

### Screen Mockups

#### Main Timer Screen (Active Routine)
```
┌────────────────────────────────┐
│         MORNING ROUTINE        │  ← Routine name (small, top)
│                                │
│      ┌──────────────────┐      │
│      │                  │      │
│      │     18:42        │      │  ← Time remaining (large, primary)
│      │                  │      │
│      └──────────────────┘      │
│                                │
│       SCRIPTURE STUDY          │  ← Current activity name (medium)
│                                │
│  ════════════════░░░░░░░░░░░░  │  ← Progress bar for current step
│                                │
│  ─────────────────────────────  │
│  NEXT: Tidy up office    5:00  │  ← Next activity (small, dimmed)
│                                │
│        Step 1 of 3             │  ← Step indicator
└────────────────────────────────┘
```

#### Timer Screen (Warning State - Under 30 Seconds)
```
┌────────────────────────────────┐
│         MORNING ROUTINE        │
│                                │
│      ┌──────────────────┐      │
│      │                  │      │
│      │      0:24        │      │  ← Orange color
│      │                  │      │
│      └──────────────────┘      │
│                                │
│       SCRIPTURE STUDY          │
│                                │
│  ████████████████████████████░ │  ← Nearly complete
│                                │
│  ─────────────────────────────  │
│  NEXT: Tidy up office    5:00  │
│                                │
│        Step 1 of 3             │
└────────────────────────────────┘
```

#### Timer Screen (Alert State - Under 10 Seconds)
```
┌────────────────────────────────┐
│         MORNING ROUTINE        │
│                                │
│      ┌──────────────────┐      │
│      │    ╔════════╗    │      │
│      │    ║  0:07  ║    │      │  ← Red color, pulsing border
│      │    ╚════════╝    │      │
│      └──────────────────┘      │
│                                │
│       SCRIPTURE STUDY          │
│                                │
│  █████████████████████████████ │
│                                │
│  ─────────────────────────────  │
│  NEXT: Tidy up office    5:00  │
│                                │
│        Step 1 of 3             │
└────────────────────────────────┘
```

#### Paused State
```
┌────────────────────────────────┐
│         MORNING ROUTINE        │
│              ⏸ PAUSED          │  ← Pause indicator
│                                │
│      ┌──────────────────┐      │
│      │                  │      │
│      │     12:30        │      │  ← Dimmed/grayed
│      │                  │      │
│      └──────────────────┘      │
│                                │
│       SCRIPTURE STUDY          │
│                                │
│  ████████████░░░░░░░░░░░░░░░░  │
│                                │
│  ─────────────────────────────  │
│  Press START to resume         │  ← Action hint
│                                │
│        Step 1 of 3             │
└────────────────────────────────┘
```

#### Routine Selection Screen
```
┌────────────────────────────────┐
│       SELECT ROUTINE           │
│                                │
│  ┌────────────────────────┐    │
│  │ ▶ Morning Routine      │    │  ← Selected (highlighted)
│  │   3 steps • 27:00      │    │
│  └────────────────────────┘    │
│                                │
│  ┌────────────────────────┐    │
│  │   Evening Wind-down    │    │
│  │   5 steps • 45:00      │    │
│  └────────────────────────┘    │
│                                │
│  ┌────────────────────────┐    │
│  │   Workout Warm-up      │    │
│  │   4 steps • 12:00      │    │
│  └────────────────────────┘    │
│                                │
└────────────────────────────────┘
```

#### Routine Complete Screen
```
┌────────────────────────────────┐
│                                │
│             ✓                  │  ← Large checkmark
│                                │
│      ROUTINE COMPLETE          │
│                                │
│      Morning Routine           │
│                                │
│  ─────────────────────────────  │
│                                │
│      Total Time: 27:42         │  ← Actual elapsed time
│      Target:     27:00         │
│                                │
│  ─────────────────────────────  │
│                                │
│     Press any button to exit   │
│                                │
└────────────────────────────────┘
```

#### Widget/Glance View
```
┌────────────────────────────────┐
│                                │
│    ⏱ ROUTINE TIMERS           │
│                                │
│    Morning Routine             │
│    Scheduled: 6:00 AM          │
│                                │
│    Tap to start now            │
│                                │
└────────────────────────────────┘
```

### Button Mapping (5-Button Layout - Fenix)

```
          [LIGHT]
             │
             │ Long press: Toggle backlight
             │ Short press: (Contextual)
             │
    [UP]─────┼─────[DOWN]
      │      │      │
      │      │      │ Scroll through menus
      │      │      │ During timer: Skip to next/prev step
      │      │
[BACK]───────┴───────[START]
   │                    │
   │ Short: Back/Exit   │ Short: Start/Pause/Resume
   │ Long: Menu         │ Long: Stop routine (confirm)
```

---

## Application Architecture

### App Type Selection

The application will be built as a **Widget** with **Background Service** support.

**Rationale:**
- Widgets support background temporal events for scheduled triggers
- Lower resource footprint than full Device Apps
- Quick access from widget carousel
- Can register for system events when available

### Module Structure

```
routine-timers/
├── source/
│   ├── RoutineTimersApp.mc          # Main app entry point
│   ├── RoutineTimersView.mc         # Primary timer display view
│   ├── RoutineTimersDelegate.mc     # Input handling
│   ├── RoutineTimersMenuView.mc     # Routine selection menu
│   ├── RoutineTimersMenuDelegate.mc # Menu input handling
│   ├── RoutineTimersGlanceView.mc   # Widget glance view
│   ├── RoutineTimersBackground.mc   # Background service delegate
│   ├── models/
│   │   ├── Routine.mc               # Routine data model
│   │   └── Step.mc                  # Step data model
│   ├── services/
│   │   ├── TimerService.mc          # Timer logic and state
│   │   ├── StorageService.mc        # Persistence layer
│   │   └── AlertService.mc          # Haptic/audio feedback
│   └── utils/
│       ├── TimeFormatter.mc         # Time display formatting
│       └── ColorUtils.mc            # Color state management
├── resources/
│   ├── strings/
│   │   └── strings.xml              # Localized strings
│   ├── layouts/
│   │   └── layout.xml               # UI layouts
│   ├── drawables/
│   │   └── drawables.xml            # Icons and graphics
│   └── settings/
│       └── settings.xml             # App settings schema
├── manifest.xml                      # App manifest
└── monkey.jungle                     # Build configuration
```

### State Machine

```
                    ┌─────────────┐
                    │    IDLE     │ ◄─────────────────────┐
                    └──────┬──────┘                       │
                           │                              │
                    Start Routine                         │
                           │                              │
                           ▼                              │
                    ┌─────────────┐                       │
           ┌────────│   RUNNING   │────────┐              │
           │        └──────┬──────┘        │              │
           │               │               │              │
        Pause           Step End        Complete          │
           │               │               │              │
           ▼               ▼               │              │
    ┌─────────────┐  ┌───────────┐         │              │
    │   PAUSED    │  │TRANSITION │         │              │
    └──────┬──────┘  └─────┬─────┘         │              │
           │               │               │              │
        Resume          Next Step          │              │
           │               │               │              │
           └───────►───────┘               │              │
                           │               │              │
                           ▼               ▼              │
                    ┌─────────────────────────┐           │
                    │       (continues)        │──────────┘
                    └─────────────────────────┘
                              │
                              ▼
                    ┌─────────────────────────┐
                    │        COMPLETE         │
                    └─────────────────────────┘
```

---

## Data Model

### Routine Object

```monkeyc
class Routine {
    var id as String;           // Unique identifier (UUID)
    var name as String;         // Display name (max 32 chars)
    var steps as Array<Step>;   // Ordered array of steps
    var createdAt as Number;    // Unix timestamp
    var updatedAt as Number;    // Unix timestamp
    var totalDuration as Number; // Computed total in seconds
    var isActive as Boolean;    // Currently running flag
    
    // Trigger configuration
    var triggerType as TriggerType; // MANUAL, SCHEDULED, EVENT
    var scheduledTime as Number?;   // Seconds from midnight (if scheduled)
    var scheduledDays as Array<Number>?; // Days of week (0-6, Sun-Sat)
    var triggerEvent as String?;    // Event identifier (if event-based)
}
```

### Step Object

```monkeyc
class Step {
    var id as String;           // Unique identifier
    var name as String;         // Display name (max 24 chars)
    var duration as Number;     // Duration in seconds
    var order as Number;        // Sort order within routine
    var alertSound as Boolean;  // Play audio at start/end
    var alertVibrate as Boolean; // Vibrate at start/end
    var color as Number?;       // Optional accent color (hex)
}
```

### Trigger Types Enum

```monkeyc
enum TriggerType {
    MANUAL,     // User-initiated only
    SCHEDULED,  // Time-based trigger
    EVENT       // System event trigger (future)
}
```

### Storage Schema

Data will be stored using `Application.Storage` with the following keys:

| Key | Type | Description |
|-----|------|-------------|
| `routines` | Array | Serialized array of Routine objects |
| `activeRoutineId` | String | Currently running routine ID (null if none) |
| `activeStepIndex` | Number | Current step index in active routine |
| `remainingTime` | Number | Remaining seconds in current step |
| `state` | String | Current state (IDLE, RUNNING, PAUSED) |
| `settings` | Dictionary | User preferences |

### Storage Limits

- Connect IQ apps have limited persistent storage (~32KB typical)
- Routines should be optimized for minimal storage footprint
- Recommend: Max 10 routines, 20 steps per routine for free tier

---

## Trigger Mechanisms

### 1. Manual Trigger (MVP)

**Flow:**
1. User opens widget/app
2. Selects routine from list (or auto-starts if only one)
3. Presses START button
4. Timer begins

**Implementation:** Standard widget launch → menu → start flow

### 2. Scheduled Trigger (MVP)

**Flow:**
1. User configures schedule in Garmin Connect Mobile app
2. App registers temporal event via `Background.registerTemporalEvent()`
3. At scheduled time, background service fires
4. Service launches foreground app with routine pre-loaded
5. Vibration/tone alerts user
6. Timer begins (or waits for confirmation based on settings)

**Implementation:**
```monkeyc
// In BackgroundServiceDelegate
function onTemporalEvent() {
    var now = Time.now();
    var scheduledRoutine = findScheduledRoutine(now);
    
    if (scheduledRoutine != null) {
        // Store the routine to launch
        Storage.setValue("pendingRoutineId", scheduledRoutine.id);
        
        // Wake the app (Connect IQ System 8+)
        // Note: May require user interaction on some devices
        Background.exit(scheduledRoutine.id);
    }
}
```

**Limitations:**
- Temporal events have minimum ~5 minute resolution
- Cannot guarantee exact second precision
- Device must not be in Do Not Disturb mode

### 3. Event Trigger (Future - Post-MVP)

**Potential Events:**
- Wake-up alarm dismissed
- Sleep tracking ended
- Activity completed
- Sunrise/sunset
- Location-based (geofence)

**Implementation Notes:**
- Connect IQ System 8 introduces new event hooks
- Requires investigation of available system events
- May need companion app integration for some triggers
- Wake alarm integration is highest priority for this feature

**Proposed API (Conceptual):**
```monkeyc
// Future implementation
Background.registerEventTrigger({
    :event => Background.EVENT_ALARM_DISMISSED,
    :routineId => "morning-routine-uuid"
});
```

---

## Garmin Connect IQ Integration

### Connect IQ App Types Used

| Component | Type | Purpose |
|-----------|------|---------|
| Main App | Widget | Primary user interface |
| Background | ServiceDelegate | Scheduled triggers |
| Glance | GlanceView | Quick info display |
| Settings | Properties | Configuration via phone |

### Garmin Connect Mobile Integration

The companion phone app (Garmin Connect) will be used for:

1. **Routine Management**
   - Create new routines
   - Edit routine names and steps
   - Reorder steps via drag-and-drop
   - Delete routines
   - Duplicate routines

2. **Settings Configuration**
   - Default alert preferences
   - Scheduled trigger times
   - Event trigger mapping (future)

3. **Data Sync**
   - Routines sync via `Application.Properties`
   - Changes pushed to watch automatically
   - Conflict resolution: phone version wins

### Settings Schema (settings.xml)

```xml
<settings>
    <setting propertyKey="@Properties.defaultVibrate" 
             title="@Strings.vibrationTitle">
        <settingConfig type="boolean" />
    </setting>
    
    <setting propertyKey="@Properties.defaultSound" 
             title="@Strings.soundTitle">
        <settingConfig type="boolean" />
    </setting>
    
    <setting propertyKey="@Properties.autoAdvance" 
             title="@Strings.autoAdvanceTitle">
        <settingConfig type="boolean" />
    </setting>
    
    <setting propertyKey="@Properties.showNextStep" 
             title="@Strings.showNextStepTitle">
        <settingConfig type="boolean" />
    </setting>
    
    <setting propertyKey="@Properties.routineData" 
             title="@Strings.routinesTitle">
        <settingConfig type="list" />
    </setting>
</settings>
```

### Permissions Required

```xml
<!-- manifest.xml -->
<iq:permissions>
    <iq:uses-permission id="Background" />
    <iq:uses-permission id="Communications" />
</iq:permissions>
```

---

## Settings & Configuration

### User-Configurable Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| Vibration Alerts | Boolean | true | Vibrate at step transitions |
| Audio Alerts | Boolean | false | Play tone at step transitions |
| Auto-Advance | Boolean | true | Automatically start next step |
| Show Next Step | Boolean | true | Display upcoming step info |
| Warning Threshold | Number | 30 | Seconds before step end to show warning color |
| Alert Threshold | Number | 10 | Seconds before step end to show alert color |
| Confirm Scheduled Start | Boolean | false | Require button press for scheduled routines |

### Per-Routine Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| Loop Routine | Boolean | false | Restart routine after completion |
| Skip Confirmation | Boolean | false | Start immediately when selected |
| Custom Vibration Pattern | Enum | STANDARD | Vibration intensity pattern |

---

## Freemium Model (Future)

### Free Tier Limitations

| Feature | Free Limit | Premium |
|---------|------------|---------|
| Routines | 3 | Unlimited |
| Steps per Routine | 10 | Unlimited |
| Scheduled Triggers | 1 | Unlimited |
| Event Triggers | ❌ | ✓ |
| Custom Colors | ❌ | ✓ |
| Statistics/History | 7 days | Unlimited |
| Export Data | ❌ | ✓ |
| Priority Support | ❌ | ✓ |

### Premium Pricing Strategy

- **Option A:** One-time purchase ($4.99 - $9.99)
- **Option B:** Annual subscription ($2.99/year)
- **Recommendation:** One-time purchase (better for Connect IQ ecosystem)

### Implementation Approach

1. Use Garmin's Connect IQ Store purchase verification
2. Store license status in `Application.Properties`
3. Graceful degradation: don't break existing routines if downgrade
4. Upsell prompts: gentle, non-intrusive limit notifications

### Upgrade Prompt UI

```
┌────────────────────────────────┐
│                                │
│      ROUTINE LIMIT REACHED     │
│                                │
│   Free version supports up to  │
│   3 routines. Upgrade to       │
│   Premium for unlimited!       │
│                                │
│  ┌──────────────────────────┐  │
│  │     View in Store        │  │
│  └──────────────────────────┘  │
│                                │
│        Maybe Later             │
│                                │
└────────────────────────────────┘
```

---

## Technical Constraints & Considerations

### Memory Constraints

- **Widget Memory:** ~28-32KB heap on Fenix 7/8
- **Background Service Memory:** ~8KB heap
- **Code Space:** 16MB additional with `:extendedCode` annotation (System 8)

**Mitigation Strategies:**
- Lazy-load routine data
- Keep only active routine in memory during playback
- Use efficient data serialization
- Limit string lengths

### Battery Considerations

- Avoid frequent screen updates (1 Hz max for timer)
- Use efficient drawing (partial updates when possible)
- Background services should exit quickly
- Avoid continuous sensor polling

### Display Considerations

| Display Type | Considerations |
|--------------|----------------|
| MIP (Fenix 7) | High contrast colors, no gradients, 1-bit optimal |
| AMOLED (Fenix 8) | True blacks save power, be cautious with large white areas |

### Localization

Support for Connect IQ standard locales:
- English (en)
- German (de)
- Spanish (es)
- French (fr)
- Italian (it)
- Portuguese (pt)
- Japanese (ja)
- Chinese Simplified (zh-Hans)

---

## Testing Strategy

### Unit Testing

```monkeyc
// Example test structure using Monkey C test framework
(:test)
function testStepTimerDecrement(logger as Logger) as Boolean {
    var step = new Step({
        :name => "Test Step",
        :duration => 60
    });
    
    var timer = new TimerService();
    timer.start(step);
    timer.tick(); // Simulate 1 second
    
    return timer.getRemainingTime() == 59;
}
```

### Integration Testing

1. **Timer Accuracy Test**
   - Run 5-minute routine, verify total time within ±1 second

2. **State Persistence Test**
   - Pause routine, exit app, reopen, verify state restored

3. **Background Trigger Test**
   - Schedule routine, verify it triggers within acceptable window

4. **Multi-Routine Test**
   - Create max routines, verify no performance degradation

### Device Testing Matrix

| Device | Resolution | Priority | Test Coverage |
|--------|------------|----------|---------------|
| Fenix 7 | 260×260 | High | Full regression |
| Fenix 7S | 240×240 | Medium | Layout verification |
| Fenix 7X | 280×280 | Medium | Layout verification |
| Fenix 8 (47mm) | 454×454 | High | Full regression |
| Fenix 8 (43mm) | 416×416 | Medium | Layout verification |
| Fenix 8 (51mm) | 484×484 | Medium | Layout verification |

### Simulator Testing

Use Garmin Connect IQ Simulator for:
- UI layout at all resolutions
- Button mapping verification
- State machine transitions
- Temporal event triggering (Simulation menu)

---

## Appendix

### A. Glossary

| Term | Definition |
|------|------------|
| Routine | A named collection of sequential timed steps |
| Step | A single timed activity within a routine |
| Temporal Event | Background scheduled callback in Connect IQ |
| MIP | Memory-in-Pixel display technology |
| Glance | Quick-view widget preview on compatible devices |

### B. References

- [Connect IQ SDK Documentation](https://developer.garmin.com/connect-iq/)
- [Monkey C Language Reference](https://developer.garmin.com/connect-iq/monkey-c/)
- [Connect IQ API Reference](https://developer.garmin.com/connect-iq/api-docs/)
- [Connect IQ System 8 Release Notes](https://forums.garmin.com/developer/connect-iq/)

### C. Open Questions

1. **Event Triggers:** What system events are available in Connect IQ System 8 for chaining routines off alarms?

2. **Notifications API:** Can the new System 8 Notifications API wake the app from background?

3. **Watch Face Complication:** Is it feasible to show next scheduled routine on watch face?

4. **Activity Recording:** Should routine completions be logged as Garmin Activities for tracking?

5. **Sync Protocol:** What's the optimal approach for syncing large routine libraries between phone and watch?

### D. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0-draft | 2026-01-11 | — | Initial specification |
| 1.0.1-draft | 2026-01-11 | — | Added development milestones |

---

## Development Milestones

This specification has been broken down into actionable development milestones. Each milestone is a separate document with checkboxes, success criteria, and testing procedures.

**See:** [milestones/README.md](./milestones/README.md)

| Milestone | Name | Est. Duration |
|-----------|------|---------------|
| M0 | [Project Setup & Scaffolding](./milestones/M0_project_setup.md) | 1-2 days |
| M1 | [Core Timer Engine](./milestones/M1_core_timer.md) | 2-3 days |
| M2 | [Multi-Step Routine Execution](./milestones/M2_multi_step_routines.md) | 2-3 days |
| M3 | [Timer User Interface](./milestones/M3_timer_ui.md) | 3-4 days |
| M4 | [Routine Storage & Selection](./milestones/M4_storage_selection.md) | 2-3 days |
| M5 | [Alerts & Haptic Feedback](./milestones/M5_alerts_feedback.md) | 1-2 days |
| M6 | [Background Service & Scheduling](./milestones/M6_background_scheduling.md) | 3-4 days |
| M7 | [Garmin Connect Mobile Integration](./milestones/M7_mobile_integration.md) | 3-4 days |
| M8 | [Multi-Device Testing & Polish](./milestones/M8_testing_polish.md) | 3-5 days |
| M9 | [Freemium & Store Submission](./milestones/M9_freemium_store.md) | 2-3 days |

**Total Estimated Duration:** 22-33 days (4-6 weeks)

---

*End of Specification Document*
