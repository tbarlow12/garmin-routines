# Milestone 8: Multi-Device Testing & Polish

**Estimated Duration:** 3-5 days  
**Dependencies:** M7 (Mobile Integration)  
**Deliverable:** Production-ready app tested on all target devices with polished UI and fixed edge cases

---

## Goal

Thoroughly test the app on all target devices (Fenix 7 series and Fenix 8 series), fix any device-specific issues, optimize performance, and polish the user experience for release.

---

## Implementation Checklist

### Device-Specific Resource Directories

- [ ] Create resolution-specific layouts:
  ```
  resources/
  ├── resources-round-240x240/    # Fenix 7S
  ├── resources-round-260x260/    # Fenix 7
  ├── resources-round-280x280/    # Fenix 7X
  ├── resources-round-416x416/    # Fenix 8 43mm
  ├── resources-round-454x454/    # Fenix 8 47mm
  └── resources-round-484x484/    # Fenix 8 51mm
  ```

- [ ] Create device-specific `layout.xml` if needed:
  ```xml
  <!-- Example: resources-round-240x240/layouts/layout.xml -->
  <layouts>
      <layout id="MainLayout">
          <label id="routineName" x="center" y="8%" font="Xtiny"/>
          <label id="timerDisplay" x="center" y="38%" font="NumberHot"/>
          <label id="stepName" x="center" y="58%" font="Small"/>
      </layout>
  </layouts>
  ```

### Font Size Optimization

- [ ] Create `source/utils/FontHelper.mc`:
  ```monkeyc
  import Toybox.Graphics;
  import Toybox.Lang;
  import Toybox.System;

  module FontHelper {
      // Get appropriate timer font based on screen size
      function getTimerFont(dc as Graphics.Dc) as Graphics.FontType {
          var height = dc.getHeight();
          
          if (height >= 450) {
              // High-res AMOLED (Fenix 8)
              return Graphics.FONT_NUMBER_THAI_HOT;
          } else if (height >= 260) {
              // Medium res (Fenix 7, 7X)
              return Graphics.FONT_NUMBER_HOT;
          } else {
              // Small screen (Fenix 7S)
              return Graphics.FONT_NUMBER_MEDIUM;
          }
      }

      // Get appropriate label font
      function getLabelFont(dc as Graphics.Dc) as Graphics.FontType {
          var height = dc.getHeight();
          
          if (height >= 450) {
              return Graphics.FONT_MEDIUM;
          } else if (height >= 260) {
              return Graphics.FONT_SMALL;
          } else {
              return Graphics.FONT_TINY;
          }
      }

      // Get appropriate tiny font
      function getTinyFont(dc as Graphics.Dc) as Graphics.FontType {
          var height = dc.getHeight();
          
          if (height >= 450) {
              return Graphics.FONT_SMALL;
          } else {
              return Graphics.FONT_XTINY;
          }
      }
  }
  ```

### Update View to Use Dynamic Fonts

- [ ] Modify `RoutineTimersView.mc` to use FontHelper:
  ```monkeyc
  // Replace hardcoded fonts with:
  var timerFont = FontHelper.getTimerFont(dc);
  var labelFont = FontHelper.getLabelFont(dc);
  var tinyFont = FontHelper.getTinyFont(dc);

  // Use these fonts in draw calls
  dc.drawText(centerX, timerY, timerFont, timeText, ...);
  dc.drawText(centerX, stepY, labelFont, stepName, ...);
  dc.drawText(centerX, nextY, tinyFont, nextText, ...);
  ```

### Progress Bar Scaling

- [ ] Update `LayoutConstants.mc` for dynamic sizing:
  ```monkeyc
  module LayoutConstants {
      // Progress bar height scales with screen
      function getProgressBarHeight(dc as Graphics.Dc) as Number {
          var height = dc.getHeight();
          if (height >= 450) {
              return 12;  // Thicker on AMOLED
          } else if (height >= 260) {
              return 8;
          } else {
              return 6;   // Thinner on small screens
          }
      }
      
      // ... rest of module
  }
  ```

### Error Handling Polish

- [ ] Create `source/utils/ErrorHandler.mc`:
  ```monkeyc
  import Toybox.Lang;
  import Toybox.System;

  module ErrorHandler {
      // Log error without crashing
      function logError(context as String, error as Exception) as Void {
          System.println("ERROR [" + context + "]: " + error.getErrorMessage());
      }

      // Log warning
      function logWarning(context as String, message as String) as Void {
          System.println("WARN [" + context + "]: " + message);
      }

      // Safely execute a callback
      function safeExecute(callback as Method() as Void, context as String) as Void {
          try {
              callback.invoke();
          } catch (e instanceof Exception) {
              logError(context, e);
          }
      }
  }
  ```

### Memory Optimization

- [ ] Review and optimize string allocations:
  ```monkeyc
  // BAD: Creates new string every tick
  var text = "Step " + step + " of " + total;

  // GOOD: Only update when values change
  if (_cachedStepText == null || _lastStepIndex != stepIndex) {
      _cachedStepText = "Step " + stepIndex + " of " + total;
      _lastStepIndex = stepIndex;
  }
  ```

- [ ] Add memory debugging:
  ```monkeyc
  // Add to RoutineTimersView.onUpdate():
  function debugMemory(dc as Dc) as Void {
      var stats = System.getSystemStats();
      var usedMemory = stats.usedMemory;
      var totalMemory = stats.totalMemory;
      
      // Draw in corner during development
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.drawText(5, dc.getHeight() - 15, Graphics.FONT_XTINY,
          usedMemory + "/" + totalMemory, Graphics.TEXT_JUSTIFY_LEFT);
  }
  ```

### Localization Verification

- [ ] Verify all user-facing strings are in strings.xml
- [ ] Test with different languages in simulator
- [ ] Ensure text doesn't overflow on translated strings (German is typically 30% longer)

### Touch Screen Support (for Fenix 8)

- [ ] Update `RoutineTimersDelegate.mc` for touch:
  ```monkeyc
  // Add touch handlers
  function onTap(evt as WatchUi.ClickEvent) as Boolean {
      // Tap anywhere to toggle pause/play
      var service = _view.getRoutineService();
      
      if (service.isRunning()) {
          service.pause();
      } else if (service.isPaused()) {
          service.resume();
      } else if (service.isIdle()) {
          service.start();
      }
      
      WatchUi.requestUpdate();
      return true;
  }

  function onSwipe(evt as WatchUi.SwipeEvent) as Boolean {
      var direction = evt.getDirection();
      var service = _view.getRoutineService();
      
      if (direction == WatchUi.SWIPE_UP) {
          // Previous step
          if (service.isRunning() || service.isPaused()) {
              service.previousStep();
              WatchUi.requestUpdate();
              return true;
          }
      } else if (direction == WatchUi.SWIPE_DOWN) {
          // Next step
          if (service.isRunning() || service.isPaused()) {
              service.nextStep();
              WatchUi.requestUpdate();
              return true;
          }
      }
      
      return false;
  }
  ```

### AMOLED-Specific Optimizations

- [ ] Create `source/utils/DisplayUtils.mc`:
  ```monkeyc
  import Toybox.System;
  import Toybox.Lang;

  module DisplayUtils {
      // Check if device has AMOLED display
      function isAmoled() as Boolean {
          var deviceSettings = System.getDeviceSettings();
          // Fenix 8 uses AMOLED (higher resolution)
          return deviceSettings.screenHeight >= 416;
      }

      // Get recommended update rate
      // AMOLED can update less frequently to save battery
      function getRecommendedUpdateRate() as Number {
          if (isAmoled()) {
              return 1000; // 1 second
          }
          return 1000; // 1 second for all
      }

      // Check if we should use anti-aliasing
      function shouldUseAntiAliasing() as Boolean {
          return isAmoled(); // AMOLED benefits from AA
      }
  }
  ```

### App Icon & Branding

- [ ] Create launcher icons for different resolutions:
  ```
  resources/drawables/
  ├── launcher_icon.png         # Default icon
  ├── launcher_icon_30x30.png   # For smaller devices
  ├── launcher_icon_40x40.png   # For medium devices  
  └── launcher_icon_60x60.png   # For high-res devices
  ```

- [ ] Update `drawables.xml`:
  ```xml
  <drawables>
      <bitmap id="LauncherIcon" filename="launcher_icon.png"/>
  </drawables>
  ```

### Code Cleanup

- [ ] Remove all debug logging (or wrap in DEBUG flag):
  ```monkeyc
  // Define in a config module
  const DEBUG = false;

  // Use throughout code
  if (DEBUG) {
      System.println("Debug: " + message);
  }
  ```

- [ ] Remove TestDataFactory references from production code
- [ ] Review and remove unused imports
- [ ] Add documentation comments to all public methods

---

## Testing Checklist

### Device Matrix Testing

For EACH device, run the complete test suite:

#### Fenix 7S (240×240 MIP)

- [ ] **Test D8.1: Layout Verification**
  - All UI elements visible
  - No text clipping
  - Progress bar centered
  - Fonts readable

- [ ] **Test D8.2: Full Routine Execution**
  - Start routine
  - Run through all steps
  - Verify alerts
  - Complete routine

- [ ] **Test D8.3: Button Mapping**
  - START: pause/resume
  - BACK: exit/stop
  - UP: previous step
  - DOWN: next step

#### Fenix 7 (260×260 MIP)

- [ ] **Test D8.4: Layout Verification**
- [ ] **Test D8.5: Full Routine Execution**
- [ ] **Test D8.6: Button Mapping**

#### Fenix 7X (280×280 MIP)

- [ ] **Test D8.7: Layout Verification**
- [ ] **Test D8.8: Full Routine Execution**
- [ ] **Test D8.9: Button Mapping**

#### Fenix 8 43mm (416×416 AMOLED)

- [ ] **Test D8.10: Layout Verification**
- [ ] **Test D8.11: Full Routine Execution**
- [ ] **Test D8.12: Button Mapping**
- [ ] **Test D8.13: Touch Tap to Pause**
- [ ] **Test D8.14: Touch Swipe Navigation**

#### Fenix 8 47mm (454×454 AMOLED)

- [ ] **Test D8.15: Layout Verification**
- [ ] **Test D8.16: Full Routine Execution**
- [ ] **Test D8.17: Button Mapping**
- [ ] **Test D8.18: Touch Interaction**

#### Fenix 8 51mm (484×484 AMOLED)

- [ ] **Test D8.19: Layout Verification**
- [ ] **Test D8.20: Full Routine Execution**
- [ ] **Test D8.21: Button/Touch Mapping**

### Performance Tests

- [ ] **Test P8.1: Memory Usage - Idle**
  1. Launch app, don't start routine
  2. Check memory stats
  3. **Expected:** < 20KB used

- [ ] **Test P8.2: Memory Usage - Running**
  1. Start a 5-step routine
  2. Check memory stats during execution
  3. **Expected:** < 25KB used, stable

- [ ] **Test P8.3: Memory Leak Detection**
  1. Start routine
  2. Run through all steps
  3. Complete routine
  4. Return to menu
  5. Repeat 5 times
  6. **Expected:** Memory returns to baseline each time

- [ ] **Test P8.4: Timer Accuracy**
  1. Start 2-minute step
  2. Time with external stopwatch
  3. **Expected:** Within ±2 seconds over 2 minutes

- [ ] **Test P8.5: UI Responsiveness**
  1. While timer running, rapidly press buttons
  2. **Expected:** UI responds within 100ms

### Edge Case Tests

- [ ] **Test E8.1: Very Long Routine Name (32 chars)**
  - Routine name: "Morning Meditation Practice !!!"
  - **Expected:** Truncates or scrolls gracefully

- [ ] **Test E8.2: Very Long Step Name (24 chars)**
  - Step name: "Stretching & warm-up!!"
  - **Expected:** Truncates gracefully

- [ ] **Test E8.3: Many Steps (20 steps)**
  - Create routine with 20 steps
  - **Expected:** All steps execute, step counter accurate

- [ ] **Test E8.4: Very Short Steps (3 seconds)**
  - Create 5 steps, each 3 seconds
  - **Expected:** Auto-advance works rapidly

- [ ] **Test E8.5: Very Long Step (60 minutes)**
  - Create step with 3600 seconds
  - **Expected:** Displays "60:00" correctly

- [ ] **Test E8.6: Rapid Pause/Resume**
  - Press START 20 times in 10 seconds
  - **Expected:** No crash, state correct

- [ ] **Test E8.7: Low Memory Condition**
  - Create maximum routines/steps
  - **Expected:** App handles gracefully or shows limit message

### Background Service Tests

- [ ] **Test B8.1: Background on All Devices**
  - Schedule routine
  - Simulate temporal event on each device
  - **Expected:** Works on all devices

- [ ] **Test B8.2: Background Memory**
  - Check background delegate memory usage
  - **Expected:** < 8KB

### UI Polish Verification

- [ ] **Test UI8.1: Complete Screen Checkmark**
  - Verify checkmark renders correctly on all resolutions
  - **Expected:** Centered, appropriately sized

- [ ] **Test UI8.2: Progress Bar Smoothness**
  - Watch progress bar fill during 30-second step
  - **Expected:** Smooth animation, no jumps

- [ ] **Test UI8.3: Color Transitions**
  - Watch timer during last 30 and 10 seconds
  - **Expected:** Clean color change, no flicker

- [ ] **Test UI8.4: Paused State Clarity**
  - Pause routine
  - **Expected:** "PAUSED" clearly visible, time frozen

### Glance View Tests

- [ ] **Test G8.1: Glance on All Devices**
  - View widget glance on each device
  - **Expected:** Shows routine info correctly

- [ ] **Test G8.2: Glance with Long Name**
  - Routine with long name in glance
  - **Expected:** Truncates appropriately

### Accessibility Considerations

- [ ] **Test A8.1: High Contrast**
  - View in bright light simulation
  - **Expected:** All text readable

- [ ] **Test A8.2: Vibration Only Mode**
  - Disable sound, enable vibration
  - Use app through full routine
  - **Expected:** Vibrations provide adequate feedback

---

## Success Criteria

| Criteria | Requirement |
|----------|-------------|
| All devices tested | 6 target devices pass full test suite |
| Memory optimized | < 25KB during operation |
| Timer accurate | Within ±2 seconds over 2 minutes |
| No crashes | Zero crashes across all tests |
| Touch works | Touch gestures work on Fenix 8 |
| Icons present | Launcher icon shows on all devices |
| UI scales | Text/elements sized appropriately |

---

## Acceptance Criteria

This milestone is **COMPLETE** when:

1. ✅ All implementation checkboxes are checked
2. ✅ All device tests (D8.1-D8.21) pass
3. ✅ All performance tests (P8.1-P8.5) pass
4. ✅ All edge case tests (E8.1-E8.7) pass
5. ✅ Memory usage is stable with no leaks
6. ✅ App is polished and release-ready

---

## Real Device Testing Notes

Simulator testing is valuable but not sufficient. Before proceeding to M9:

### Recommended Real Device Tests

- [ ] Test on actual Fenix 7 (if available)
- [ ] Test on actual Fenix 8 (if available)
- [ ] Verify vibration patterns feel correct
- [ ] Verify readability in real lighting conditions
- [ ] Test scheduled trigger overnight
- [ ] Test battery impact over 1-hour usage

### How to Side-Load for Testing

1. Build `.prg` file for specific device
2. Connect watch via USB
3. Copy `.prg` to `GARMIN/Apps/` folder
4. Disconnect and launch from widget menu

---

## Files Created/Modified in This Milestone

```
routine-timers/
├── source/
│   ├── RoutineTimersView.mc        ✓ Modified
│   ├── RoutineTimersDelegate.mc    ✓ Modified
│   └── utils/
│       ├── FontHelper.mc           ✓ Created
│       ├── DisplayUtils.mc         ✓ Created
│       ├── ErrorHandler.mc         ✓ Created
│       └── LayoutConstants.mc      ✓ Modified
├── resources/
│   ├── drawables/
│   │   └── launcher_icon.png       ✓ Created
│   ├── resources-round-240x240/    ✓ Created
│   ├── resources-round-260x260/    ✓ Created
│   └── ...                         ✓ Created
```

---

## Next Milestone

Once all criteria are met, proceed to **[M9: Freemium & Store Submission](./M9_freemium_store.md)**
