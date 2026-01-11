# Milestone 9: Freemium & Store Submission

**Estimated Duration:** 2-3 days  
**Dependencies:** M8 (Testing & Polish)  
**Deliverable:** App with freemium tier enforcement, store listing, and successful submission

---

## Goal

Implement the freemium model with free tier limitations, prepare all store assets, and submit the app to the Garmin Connect IQ Store for review.

---

## Implementation Checklist

### Freemium Service

- [ ] Create `source/services/FreemiumService.mc`:
  ```monkeyc
  import Toybox.Application;
  import Toybox.Application.Storage;
  import Toybox.Lang;
  import Toybox.System;

  // Freemium tier limits
  module FreemiumLimits {
      const FREE_MAX_ROUTINES = 3;
      const FREE_MAX_STEPS_PER_ROUTINE = 10;
      const FREE_MAX_SCHEDULED_TRIGGERS = 1;
      const FREE_HISTORY_DAYS = 7;
  }

  module FreemiumService {
      private const STORAGE_KEY_PREMIUM = "isPremium";
      private const STORAGE_KEY_PURCHASE_DATE = "purchaseDate";

      // Check if user has premium
      function isPremium() as Boolean {
          var premium = Storage.getValue(STORAGE_KEY_PREMIUM);
          return premium != null && premium == true;
      }

      // Set premium status (called after purchase verification)
      function setPremiumStatus(isPremium as Boolean) as Void {
          Storage.setValue(STORAGE_KEY_PREMIUM, isPremium);
          if (isPremium) {
              Storage.setValue(STORAGE_KEY_PURCHASE_DATE, Time.now().value());
          }
      }

      // Check if can add more routines
      function canAddRoutine() as Boolean {
          if (isPremium()) {
              return true;
          }
          var count = StorageService.getRoutineCount();
          return count < FreemiumLimits.FREE_MAX_ROUTINES;
      }

      // Get remaining routine slots
      function getRemainingRoutineSlots() as Number {
          if (isPremium()) {
              return 999; // Effectively unlimited
          }
          var count = StorageService.getRoutineCount();
          var remaining = FreemiumLimits.FREE_MAX_ROUTINES - count;
          return remaining > 0 ? remaining : 0;
      }

      // Check if can add more steps to a routine
      function canAddStepToRoutine(routine as Routine) as Boolean {
          if (isPremium()) {
              return true;
          }
          return routine.getStepCount() < FreemiumLimits.FREE_MAX_STEPS_PER_ROUTINE;
      }

      // Get remaining step slots for a routine
      function getRemainingStepSlots(routine as Routine) as Number {
          if (isPremium()) {
              return 999;
          }
          var count = routine.getStepCount();
          var remaining = FreemiumLimits.FREE_MAX_STEPS_PER_ROUTINE - count;
          return remaining > 0 ? remaining : 0;
      }

      // Check if can add scheduled trigger
      function canAddScheduledTrigger() as Boolean {
          if (isPremium()) {
              return true;
          }
          
          var routines = StorageService.loadRoutines();
          var scheduledCount = 0;
          
          for (var i = 0; i < routines.size(); i++) {
              if (routines[i].triggerType == TRIGGER_SCHEDULED) {
                  scheduledCount++;
              }
          }
          
          return scheduledCount < FreemiumLimits.FREE_MAX_SCHEDULED_TRIGGERS;
      }

      // Get number of scheduled triggers used
      function getScheduledTriggerCount() as Number {
          var routines = StorageService.loadRoutines();
          var count = 0;
          
          for (var i = 0; i < routines.size(); i++) {
              if (routines[i].triggerType == TRIGGER_SCHEDULED) {
                  count++;
              }
          }
          
          return count;
      }

      // Check if feature is available
      function isFeatureAvailable(feature as String) as Boolean {
          if (isPremium()) {
              return true;
          }
          
          // Free tier feature restrictions
          switch (feature) {
              case "customColors":
                  return false;
              case "statistics":
                  return false;
              case "export":
                  return false;
              case "eventTriggers":
                  return false;
              default:
                  return true;
          }
      }

      // Get upgrade message for a limit
      function getUpgradeMessage(limitType as String) as String {
          switch (limitType) {
              case "routines":
                  return "Free version supports " + FreemiumLimits.FREE_MAX_ROUTINES + 
                         " routines. Upgrade for unlimited!";
              case "steps":
                  return "Free version supports " + FreemiumLimits.FREE_MAX_STEPS_PER_ROUTINE + 
                         " steps per routine. Upgrade for unlimited!";
              case "scheduled":
                  return "Free version supports " + FreemiumLimits.FREE_MAX_SCHEDULED_TRIGGERS + 
                         " scheduled routine. Upgrade for unlimited!";
              default:
                  return "Upgrade to Premium for full access!";
          }
      }
  }
  ```

### Upgrade Prompt View

- [ ] Create `source/UpgradePromptView.mc`:
  ```monkeyc
  import Toybox.Graphics;
  import Toybox.WatchUi;
  import Toybox.Lang;

  class UpgradePromptView extends WatchUi.View {
      private var _limitType as String;
      private var _message as String;

      function initialize(limitType as String) {
          View.initialize();
          _limitType = limitType;
          _message = FreemiumService.getUpgradeMessage(limitType);
      }

      function onUpdate(dc as Dc) as Void {
          dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
          dc.clear();

          var centerX = dc.getWidth() / 2;
          var centerY = dc.getHeight() / 2;

          // Warning icon
          dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
          dc.drawText(centerX, centerY - 60, Graphics.FONT_MEDIUM,
              "!", Graphics.TEXT_JUSTIFY_CENTER);

          // Title
          dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
          dc.drawText(centerX, centerY - 35, Graphics.FONT_SMALL,
              "LIMIT REACHED", Graphics.TEXT_JUSTIFY_CENTER);

          // Message (wrap if needed)
          dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
          drawWrappedText(dc, centerX, centerY, _message);

          // Action hint
          dc.drawText(centerX, dc.getHeight() - 50, Graphics.FONT_XTINY,
              "View in Connect IQ Store", Graphics.TEXT_JUSTIFY_CENTER);
          dc.drawText(centerX, dc.getHeight() - 30, Graphics.FONT_XTINY,
              "for Premium upgrade", Graphics.TEXT_JUSTIFY_CENTER);
      }

      private function drawWrappedText(dc as Dc, x as Number, y as Number, text as String) as Void {
          // Simple text wrapping
          var maxWidth = dc.getWidth() * 0.8;
          var font = Graphics.FONT_XTINY;
          var lineHeight = dc.getFontHeight(font) + 2;
          
          // For simplicity, just draw centered
          // In production, implement proper word wrapping
          dc.drawText(x, y, font, text, Graphics.TEXT_JUSTIFY_CENTER);
      }
  }

  class UpgradePromptDelegate extends WatchUi.BehaviorDelegate {
      function initialize() {
          BehaviorDelegate.initialize();
      }

      function onSelect() as Boolean {
          // Could open store link if supported
          WatchUi.popView(WatchUi.SLIDE_RIGHT);
          return true;
      }

      function onBack() as Boolean {
          WatchUi.popView(WatchUi.SLIDE_RIGHT);
          return true;
      }
  }
  ```

### Integrate Freemium Checks

- [ ] Update `StorageService.mc` to enforce limits:
  ```monkeyc
  // Modify saveRoutine to check limits
  function saveRoutine(routine as Routine) as Boolean {
      var routines = loadRoutines();
      var isNew = true;
      
      // Check if updating existing
      for (var i = 0; i < routines.size(); i++) {
          if (routines[i].id.equals(routine.id)) {
              isNew = false;
              break;
          }
      }
      
      // If new, check limit
      if (isNew && !FreemiumService.canAddRoutine()) {
          return false; // Limit reached
      }
      
      // Check step limit
      if (!FreemiumService.isPremium() && 
          routine.getStepCount() > FreemiumLimits.FREE_MAX_STEPS_PER_ROUTINE) {
          return false; // Too many steps
      }
      
      // Check scheduled limit
      if (routine.triggerType == TRIGGER_SCHEDULED) {
          if (isNew && !FreemiumService.canAddScheduledTrigger()) {
              return false;
          }
      }
      
      // Proceed with save
      // ... existing save logic ...
      return true;
  }
  ```

- [ ] Update `RoutineTimersMenuView.mc` to show upgrade prompts:
  ```monkeyc
  // After menu items, show free tier status
  function loadRoutineItems() as Void {
      // ... existing code to load routines ...
      
      // Show remaining slots for free users
      if (!FreemiumService.isPremium()) {
          var remaining = FreemiumService.getRemainingRoutineSlots();
          if (remaining > 0) {
              addItem(new WatchUi.MenuItem(
                  "Add Routine",
                  remaining + " slots remaining",
                  :addRoutine,
                  {}
              ));
          } else {
              addItem(new WatchUi.MenuItem(
                  "Routine Limit Reached",
                  "Tap to upgrade",
                  :upgrade,
                  {}
              ));
          }
      }
  }
  ```

### Store Listing Assets

- [ ] Create store assets directory:
  ```
  store/
  ├── screenshots/
  │   ├── fenix7_timer_running.png
  │   ├── fenix7_routine_complete.png
  │   ├── fenix7_menu.png
  │   ├── fenix8_timer_running.png
  │   ├── fenix8_routine_complete.png
  │   └── fenix8_menu.png
  ├── icon/
  │   ├── app_icon_512x512.png
  │   └── app_icon_256x256.png
  ├── description.txt
  ├── what_is_new.txt
  └── keywords.txt
  ```

- [ ] Create `store/description.txt`:
  ```
  Routine Timers - Your Personal Routine Coach

  Stay on track with guided, sequential timers for your daily routines. 
  Perfect for morning routines, workout warm-ups, productivity blocks, 
  and any timed activity sequence.

  FEATURES:
  • Create custom routines with multiple timed steps
  • Automatic progression through your routine
  • Clear, glanceable countdown display
  • Vibration alerts at step transitions
  • Optional audio tones
  • Schedule routines to start automatically
  • Works without phone connection

  EXAMPLE USE CASES:
  • Morning routine: Scripture study (20 min) → Tidy office (5 min) → Water bottle (2 min)
  • Workout warm-up: Dynamic stretches (3 min) → Foam rolling (5 min) → Activation (2 min)  
  • Pomodoro sessions: Focus work (25 min) → Break (5 min)
  • Bedtime routine: Reading (20 min) → Meditation (10 min) → Sleep prep (5 min)

  FREE VERSION INCLUDES:
  • Up to 3 routines
  • Up to 10 steps per routine
  • 1 scheduled trigger
  • All core timer features

  PREMIUM UPGRADE:
  • Unlimited routines and steps
  • Unlimited scheduled triggers
  • Priority support

  Configure your routines easily in the Garmin Connect Mobile app.

  Questions or feedback? We'd love to hear from you!
  ```

- [ ] Create `store/what_is_new.txt`:
  ```
  Version 1.0.0 - Initial Release

  • Create and run custom timed routines
  • Automatic step progression
  • Vibration and audio alerts
  • Schedule routines to start automatically
  • Widget with glance preview
  • Supports Fenix 7 and Fenix 8 series
  ```

- [ ] Create `store/keywords.txt`:
  ```
  timer, routine, schedule, productivity, morning routine, habit tracker,
  countdown, interval, pomodoro, workout timer, daily routine, automation,
  time management, habit building, sequential timer
  ```

### Screenshot Capture

- [ ] Capture required screenshots for each device:

  | Screenshot | Description | Devices |
  |------------|-------------|---------|
  | timer_running | Active timer with time visible | All |
  | routine_complete | Completion screen with checkmark | All |
  | menu | Routine selection menu | All |
  | warning_state | Timer in orange warning state | Representative |
  | paused_state | Timer paused | Representative |

### App Metadata

- [ ] Verify `manifest.xml` metadata:
  ```xml
  <iq:application 
      id="routine-timers" 
      type="widget"
      name="@Strings.AppName"
      entry="RoutineTimersApp"
      launcherIcon="@Drawables.LauncherIcon"
      minSdkVersion="6.0.0">
      
      <!-- Ensure all products are listed -->
      <iq:products>
          <iq:product id="fenix7s"/>
          <iq:product id="fenix7"/>
          <iq:product id="fenix7x"/>
          <iq:product id="fenix843mm"/>
          <iq:product id="fenix847mm"/>
          <iq:product id="fenix851mm"/>
      </iq:products>
      
      <iq:permissions>
          <iq:uses-permission id="Background"/>
      </iq:permissions>
      
      <iq:languages>
          <iq:language>eng</iq:language>
      </iq:languages>
  </iq:application>
  ```

### Build for Release

- [ ] Create release build script or document process:
  ```bash
  # Build release version for all devices
  # From VS Code: Monkey C: Build for Device (Release)
  # Or use command line:
  
  monkeyc -o bin/RoutineTimers.iq \
          -y developer_key.der \
          -f monkey.jungle \
          -r
  ```

- [ ] Verify `.iq` package is generated
- [ ] Test the `.iq` package in simulator

### Store Submission Checklist

- [ ] Create Garmin developer account (if not done)
- [ ] Log in to [Connect IQ Developer Dashboard](https://apps.garmin.com/developer/)
- [ ] Create new app listing
- [ ] Fill in all required fields:
  - [ ] App name: "Routine Timers"
  - [ ] Category: Utilities (or Fitness if more appropriate)
  - [ ] Description (from description.txt)
  - [ ] What's new (from what_is_new.txt)
  - [ ] Keywords (from keywords.txt)
  - [ ] Support email
  - [ ] Privacy policy URL (if collecting any data)
- [ ] Upload app icon (512x512 PNG)
- [ ] Upload screenshots (at least 3)
- [ ] Upload `.iq` package
- [ ] Select supported devices
- [ ] Set pricing:
  - [ ] Free version with in-app upgrade option
  - [ ] OR paid app ($4.99 recommended)
- [ ] Submit for review

---

## Testing Checklist

### Freemium Limit Tests

- [ ] **Test F9.1: Routine Limit Enforcement**
  1. Create 3 routines (free limit)
  2. Try to create 4th routine
  3. **Expected:** Blocked, upgrade prompt shown

- [ ] **Test F9.2: Step Limit Enforcement**
  1. Create routine with 10 steps
  2. Try to add 11th step
  3. **Expected:** Blocked, upgrade prompt shown

- [ ] **Test F9.3: Scheduled Trigger Limit**
  1. Create 1 scheduled routine
  2. Try to schedule another routine
  3. **Expected:** Blocked, upgrade prompt shown

- [ ] **Test F9.4: Premium Bypasses Limits**
  1. Manually set premium flag in storage
  2. Try all limited operations
  3. **Expected:** All operations succeed

- [ ] **Test F9.5: Existing Data Preserved**
  1. If user had more than free limits before downgrade
  2. **Expected:** Existing routines still work
  3. **Expected:** Cannot add more until under limit

### Upgrade Prompt Tests

- [ ] **Test F9.6: Upgrade Prompt Display**
  1. Trigger a limit
  2. **Expected:** Upgrade prompt view appears
  3. **Expected:** Clear message about limit

- [ ] **Test F9.7: Dismiss Upgrade Prompt**
  1. View upgrade prompt
  2. Press BACK
  3. **Expected:** Returns to previous screen

### Store Asset Tests

- [ ] **Test S9.1: Icon Renders**
  1. View app in simulator app list
  2. **Expected:** Icon displays correctly

- [ ] **Test S9.2: Screenshots Accurate**
  1. Compare screenshots to actual app
  2. **Expected:** Screenshots match current UI

### Release Build Tests

- [ ] **Test R9.1: Release Build Runs**
  1. Build release .iq package
  2. Load in simulator
  3. **Expected:** App runs correctly

- [ ] **Test R9.2: No Debug Output**
  1. Run release build
  2. Check simulator console
  3. **Expected:** No debug println statements

- [ ] **Test R9.3: Side-load Test**
  1. Copy .prg to real device
  2. Launch app
  3. **Expected:** App works on real hardware

### Pre-Submission Validation

- [ ] **Test V9.1: Manifest Validation**
  1. Validate manifest.xml
  2. **Expected:** No errors

- [ ] **Test V9.2: All Devices Build**
  1. Build for each target device
  2. **Expected:** All builds succeed

- [ ] **Test V9.3: Package Size**
  1. Check .iq file size
  2. **Expected:** < 100KB (typical limit)

---

## Success Criteria

| Criteria | Requirement |
|----------|-------------|
| Freemium limits work | Free users blocked at limits |
| Upgrade prompts show | Clear messaging for upgrades |
| Premium bypass works | Premium users unrestricted |
| Screenshots ready | 3+ quality screenshots |
| Icon ready | 512x512 PNG icon |
| Description complete | Compelling store description |
| Release builds | .iq package generated |
| Manifest valid | All required fields present |

---

## Acceptance Criteria

This milestone is **COMPLETE** when:

1. ✅ All implementation checkboxes are checked
2. ✅ All tests F9.1 through V9.3 pass
3. ✅ Freemium limits enforced correctly
4. ✅ Store assets prepared and reviewed
5. ✅ Release build generated successfully
6. ✅ App submitted to Connect IQ Store

---

## Post-Submission

### While Waiting for Review (1-5 business days typically)

- [ ] Prepare support documentation
- [ ] Set up feedback email monitoring
- [ ] Plan v1.1 features based on any late discoveries
- [ ] Create social media / announcement for launch

### After Approval

- [ ] Announce launch
- [ ] Monitor reviews and ratings
- [ ] Respond to user feedback
- [ ] Track download metrics
- [ ] Plan next version based on feedback

---

## Pricing Strategy Notes

### Option A: Free + Premium IAP
- Free download with limited features
- One-time upgrade purchase ($4.99-$9.99)
- Pros: Lower barrier to entry, more downloads
- Cons: More complex implementation

### Option B: Paid App
- Single paid version ($4.99)
- All features included
- Pros: Simpler, no IAP management
- Cons: Fewer downloads

### Recommendation for v1.0
Start with **Option B (Paid App)** at $4.99:
- Simpler to implement and maintain
- Connect IQ users expect quality paid apps
- Can always add free tier later

---

## Files Created/Modified in This Milestone

```
routine-timers/
├── source/
│   ├── services/
│   │   ├── FreemiumService.mc       ✓ Created
│   │   └── StorageService.mc        ✓ Modified
│   ├── UpgradePromptView.mc         ✓ Created
│   └── RoutineTimersMenuView.mc     ✓ Modified
├── store/
│   ├── screenshots/                 ✓ Created
│   ├── icon/                        ✓ Created
│   ├── description.txt              ✓ Created
│   ├── what_is_new.txt              ✓ Created
│   └── keywords.txt                 ✓ Created
├── manifest.xml                     ✓ Verified
└── bin/
    └── RoutineTimers.iq             ✓ Generated
```

---

## 🎉 Congratulations!

If you've reached this point with all checkboxes completed, you have successfully:

1. Built a complete Garmin Connect IQ widget app
2. Implemented core timer functionality with multi-step routines
3. Created a polished, production-ready UI
4. Added persistent storage and phone integration
5. Implemented background scheduling
6. Built a freemium business model
7. Submitted to the Connect IQ Store

**Well done! Time to help people master their routines! 🏆**

---

## Future Roadmap (Post v1.0)

| Version | Features |
|---------|----------|
| v1.1 | Bug fixes, user feedback integration |
| v1.2 | Watch-based simple editing |
| v1.3 | Statistics and completion tracking |
| v2.0 | Event triggers (wake alarm integration) |
| v2.1 | Watch face complication |
| v2.2 | Additional device support (Forerunner, Venu) |

---

*End of Development Milestones*
