# Milestone 3: Timer User Interface

**Estimated Duration:** 3-4 days  
**Dependencies:** M2 (Multi-Step Routines)  
**Deliverable:** Polished, production-ready timer display matching the spec mockups

---

## Goal

Create the complete timer user interface as specified in the app spec. This includes the main timer display with progress bar, color states (normal, warning, alert), proper typography, and responsive layout for all target screen sizes.

---

## Implementation Checklist

### Color Utilities

- [ ] Create `source/utils/ColorUtils.mc`:
  ```monkeyc
  import Toybox.Graphics;
  import Toybox.Lang;

  module ColorUtils {
      // Color constants matching the spec
      const COLOR_PRIMARY_TEXT = 0xFFFFFF;      // White
      const COLOR_SECONDARY_TEXT = 0xAAAAAA;    // Light gray
      const COLOR_ACCENT = 0x00A0DD;            // Garmin blue
      const COLOR_WARNING = 0xFF8C00;           // Orange (< 30s)
      const COLOR_ALERT = 0xFF4444;             // Red (< 10s)
      const COLOR_BACKGROUND = 0x000000;        // Black
      const COLOR_SUCCESS = 0x00DD00;           // Green
      const COLOR_PAUSED = 0xFFFF00;            // Yellow

      // Thresholds in seconds
      const WARNING_THRESHOLD = 30;
      const ALERT_THRESHOLD = 10;

      // Get timer color based on remaining seconds
      function getTimerColor(remainingSeconds as Number) as Number {
          if (remainingSeconds <= ALERT_THRESHOLD) {
              return COLOR_ALERT;
          } else if (remainingSeconds <= WARNING_THRESHOLD) {
              return COLOR_WARNING;
          }
          return COLOR_PRIMARY_TEXT;
      }

      // Get progress bar color based on remaining seconds
      function getProgressColor(remainingSeconds as Number) as Number {
          if (remainingSeconds <= ALERT_THRESHOLD) {
              return COLOR_ALERT;
          } else if (remainingSeconds <= WARNING_THRESHOLD) {
              return COLOR_WARNING;
          }
          return COLOR_ACCENT;
      }

      // Check if we should pulse (for alert state animation)
      function shouldPulse(remainingSeconds as Number) as Boolean {
          return remainingSeconds <= ALERT_THRESHOLD && remainingSeconds > 0;
      }
  }
  ```

### Layout Constants

- [ ] Create `source/utils/LayoutConstants.mc`:
  ```monkeyc
  import Toybox.Lang;
  import Toybox.Graphics;

  module LayoutConstants {
      // Calculate layout values based on screen dimensions
      // These are percentages of screen height/width
      
      const ROUTINE_NAME_Y_PERCENT = 0.10;      // 10% from top
      const TIME_CENTER_Y_PERCENT = 0.40;       // 40% from top (center of timer)
      const STEP_NAME_Y_PERCENT = 0.58;         // 58% from top
      const PROGRESS_BAR_Y_PERCENT = 0.68;      // 68% from top
      const NEXT_STEP_Y_PERCENT = 0.80;         // 80% from top
      const STEP_INDICATOR_Y_PERCENT = 0.90;    // 90% from top
      
      const PROGRESS_BAR_HEIGHT = 8;            // Fixed height in pixels
      const PROGRESS_BAR_MARGIN_PERCENT = 0.10; // 10% margin on each side
      
      // Get Y position for a given percentage
      function getY(dc as Graphics.Dc, percent as Float) as Number {
          return (dc.getHeight() * percent).toNumber();
      }
      
      // Get progress bar start X
      function getProgressBarStartX(dc as Graphics.Dc) as Number {
          return (dc.getWidth() * PROGRESS_BAR_MARGIN_PERCENT).toNumber();
      }
      
      // Get progress bar width
      function getProgressBarWidth(dc as Graphics.Dc) as Number {
          var margin = getProgressBarStartX(dc);
          return dc.getWidth() - (margin * 2);
      }
  }
  ```

### Main Timer View (Complete Redesign)

- [ ] Update `RoutineTimersView.mc` with full UI implementation:
  ```monkeyc
  import Toybox.Graphics;
  import Toybox.WatchUi;
  import Toybox.Lang;
  import Toybox.System;

  class RoutineTimersView extends WatchUi.View {
      private var _routineService as RoutineService;
      private var _pulseState as Boolean;  // For pulsing animation

      function initialize() {
          View.initialize();
          _routineService = new RoutineService();
          _pulseState = false;
          
          // Load test routine
          var testRoutine = TestDataFactory.createQuickTestRoutine();
          _routineService.loadRoutine(testRoutine);
          
          // Set up callbacks
          _routineService.setOnTickCallback(method(:onTick));
          _routineService.setOnStepChangeCallback(method(:onStepChange));
          _routineService.setOnRoutineCompleteCallback(method(:onRoutineComplete));
      }

      function onTick() as Void {
          _pulseState = !_pulseState; // Toggle pulse state each second
          WatchUi.requestUpdate();
      }

      function onStepChange(stepIndex as Number, step as Step) as Void {
          WatchUi.requestUpdate();
      }

      function onRoutineComplete() as Void {
          WatchUi.requestUpdate();
      }

      function getRoutineService() as RoutineService {
          return _routineService;
      }

      function onUpdate(dc as Dc) as Void {
          // Clear background
          dc.setColor(ColorUtils.COLOR_PRIMARY_TEXT, ColorUtils.COLOR_BACKGROUND);
          dc.clear();

          var routine = _routineService.getRoutine();
          if (routine == null) {
              drawNoRoutine(dc);
              return;
          }

          if (_routineService.isComplete()) {
              drawCompleteScreen(dc, routine);
              return;
          }

          drawActiveRoutine(dc, routine);
      }

      private function drawNoRoutine(dc as Dc) as Void {
          dc.setColor(ColorUtils.COLOR_SECONDARY_TEXT, Graphics.COLOR_TRANSPARENT);
          dc.drawText(
              dc.getWidth() / 2,
              dc.getHeight() / 2,
              Graphics.FONT_MEDIUM,
              "No Routine Loaded",
              Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
          );
      }

      private function drawActiveRoutine(dc as Dc, routine as Routine) as Void {
          var centerX = dc.getWidth() / 2;
          var remainingSeconds = _routineService.getRemainingSeconds();

          // 1. Routine name (top, small, gray)
          dc.setColor(ColorUtils.COLOR_SECONDARY_TEXT, Graphics.COLOR_TRANSPARENT);
          dc.drawText(
              centerX,
              LayoutConstants.getY(dc, LayoutConstants.ROUTINE_NAME_Y_PERCENT),
              Graphics.FONT_XTINY,
              routine.name.toUpper(),
              Graphics.TEXT_JUSTIFY_CENTER
          );

          // 2. Paused indicator (if paused)
          if (_routineService.isPaused()) {
              dc.setColor(ColorUtils.COLOR_PAUSED, Graphics.COLOR_TRANSPARENT);
              dc.drawText(
                  centerX,
                  LayoutConstants.getY(dc, LayoutConstants.ROUTINE_NAME_Y_PERCENT) + 18,
                  Graphics.FONT_XTINY,
                  "⏸ PAUSED",
                  Graphics.TEXT_JUSTIFY_CENTER
              );
          }

          // 3. Time remaining (large, center, colored by state)
          var timerColor = ColorUtils.getTimerColor(remainingSeconds);
          
          // Apply pulse effect in alert state
          if (ColorUtils.shouldPulse(remainingSeconds) && _pulseState) {
              timerColor = ColorUtils.COLOR_PRIMARY_TEXT; // Flash between red and white
          }
          
          dc.setColor(timerColor, Graphics.COLOR_TRANSPARENT);
          var timeText = TimeFormatter.formatSmart(remainingSeconds);
          dc.drawText(
              centerX,
              LayoutConstants.getY(dc, LayoutConstants.TIME_CENTER_Y_PERCENT),
              Graphics.FONT_NUMBER_HOT,
              timeText,
              Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
          );

          // 4. Current step name
          var currentStep = _routineService.getCurrentStep();
          if (currentStep != null) {
              dc.setColor(ColorUtils.COLOR_PRIMARY_TEXT, Graphics.COLOR_TRANSPARENT);
              dc.drawText(
                  centerX,
                  LayoutConstants.getY(dc, LayoutConstants.STEP_NAME_Y_PERCENT),
                  Graphics.FONT_SMALL,
                  currentStep.name,
                  Graphics.TEXT_JUSTIFY_CENTER
              );
          }

          // 5. Progress bar
          drawProgressBar(dc, remainingSeconds);

          // 6. Next step info
          drawNextStepInfo(dc, routine);

          // 7. Step indicator
          drawStepIndicator(dc, routine);

          // 8. Idle state hint
          if (_routineService.isIdle()) {
              dc.setColor(ColorUtils.COLOR_SECONDARY_TEXT, Graphics.COLOR_TRANSPARENT);
              dc.drawText(
                  centerX,
                  LayoutConstants.getY(dc, LayoutConstants.NEXT_STEP_Y_PERCENT),
                  Graphics.FONT_XTINY,
                  "Press START to begin",
                  Graphics.TEXT_JUSTIFY_CENTER
              );
          }
      }

      private function drawProgressBar(dc as Dc, remainingSeconds as Number) as Void {
          var startX = LayoutConstants.getProgressBarStartX(dc);
          var barWidth = LayoutConstants.getProgressBarWidth(dc);
          var barY = LayoutConstants.getY(dc, LayoutConstants.PROGRESS_BAR_Y_PERCENT);
          var barHeight = LayoutConstants.PROGRESS_BAR_HEIGHT;

          // Background track (dark gray)
          dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
          dc.fillRectangle(startX, barY, barWidth, barHeight);

          // Progress fill
          var progress = _routineService.getCurrentStepProgress();
          var fillWidth = (barWidth * progress).toNumber();
          
          if (fillWidth > 0) {
              var progressColor = ColorUtils.getProgressColor(remainingSeconds);
              dc.setColor(progressColor, Graphics.COLOR_TRANSPARENT);
              dc.fillRectangle(startX, barY, fillWidth, barHeight);
          }
      }

      private function drawNextStepInfo(dc as Dc, routine as Routine) as Void {
          if (_routineService.isIdle()) {
              return; // Don't show next step hint in idle state
          }

          var nextStep = _routineService.getNextStep();
          if (nextStep != null) {
              var centerX = dc.getWidth() / 2;
              var nextY = LayoutConstants.getY(dc, LayoutConstants.NEXT_STEP_Y_PERCENT);

              // Separator line
              var lineWidth = dc.getWidth() * 0.6;
              var lineStartX = (dc.getWidth() - lineWidth) / 2;
              dc.setColor(0x444444, Graphics.COLOR_TRANSPARENT);
              dc.drawLine(lineStartX, nextY - 10, lineStartX + lineWidth, nextY - 10);

              // Next step text
              dc.setColor(ColorUtils.COLOR_SECONDARY_TEXT, Graphics.COLOR_TRANSPARENT);
              var nextText = "NEXT: " + nextStep.name + "  " + 
                            TimeFormatter.formatSmart(nextStep.duration);
              dc.drawText(
                  centerX,
                  nextY,
                  Graphics.FONT_XTINY,
                  nextText,
                  Graphics.TEXT_JUSTIFY_CENTER
              );
          }
      }

      private function drawStepIndicator(dc as Dc, routine as Routine) as Void {
          var centerX = dc.getWidth() / 2;
          var indicatorY = LayoutConstants.getY(dc, LayoutConstants.STEP_INDICATOR_Y_PERCENT);

          dc.setColor(ColorUtils.COLOR_SECONDARY_TEXT, Graphics.COLOR_TRANSPARENT);
          var stepText = "Step " + (_routineService.getCurrentStepIndex() + 1) + 
                        " of " + routine.getStepCount();
          dc.drawText(
              centerX,
              indicatorY,
              Graphics.FONT_XTINY,
              stepText,
              Graphics.TEXT_JUSTIFY_CENTER
          );
      }

      private function drawCompleteScreen(dc as Dc, routine as Routine) as Void {
          var centerX = dc.getWidth() / 2;
          var centerY = dc.getHeight() / 2;

          // Large checkmark
          dc.setColor(ColorUtils.COLOR_SUCCESS, Graphics.COLOR_TRANSPARENT);
          dc.drawText(
              centerX,
              centerY - 50,
              Graphics.FONT_NUMBER_THAI_HOT,
              "✓",
              Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
          );

          // "ROUTINE COMPLETE" text
          dc.setColor(ColorUtils.COLOR_PRIMARY_TEXT, Graphics.COLOR_TRANSPARENT);
          dc.drawText(
              centerX,
              centerY,
              Graphics.FONT_MEDIUM,
              "ROUTINE COMPLETE",
              Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
          );

          // Routine name
          dc.setColor(ColorUtils.COLOR_SECONDARY_TEXT, Graphics.COLOR_TRANSPARENT);
          dc.drawText(
              centerX,
              centerY + 30,
              Graphics.FONT_SMALL,
              routine.name,
              Graphics.TEXT_JUSTIFY_CENTER
          );

          // Total time info
          var totalTime = routine.getTotalDuration();
          dc.drawText(
              centerX,
              centerY + 60,
              Graphics.FONT_XTINY,
              "Target: " + TimeFormatter.formatSmart(totalTime),
              Graphics.TEXT_JUSTIFY_CENTER
          );

          // Exit hint
          dc.drawText(
              centerX,
              dc.getHeight() - 30,
              Graphics.FONT_XTINY,
              "Press any button to exit",
              Graphics.TEXT_JUSTIFY_CENTER
          );
      }
  }
  ```

### Device-Specific Resources (Optional but Recommended)

- [ ] Create device-specific resource directories if needed:
  ```
  resources/
  ├── resources-fenix7/
  │   └── layouts/
  │       └── layout.xml
  └── resources-fenix8/
      └── layouts/
          └── layout.xml
  ```

- [ ] Consider font size adjustments for different resolutions:
  - Fenix 7 (260×260): Standard fonts
  - Fenix 8 (454×454): May need larger fonts for AMOLED

### Circular Progress Indicator (Enhancement)

- [ ] Create `source/utils/CircularProgress.mc` for round display support:
  ```monkeyc
  import Toybox.Graphics;
  import Toybox.Lang;
  import Toybox.Math;

  module CircularProgress {
      // Draw a circular arc progress indicator
      // progress: 0.0 to 1.0
      function drawArc(
          dc as Graphics.Dc,
          centerX as Number,
          centerY as Number,
          radius as Number,
          thickness as Number,
          progress as Float,
          color as Number
      ) as Void {
          // Background arc (full circle, dimmed)
          dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
          dc.setPenWidth(thickness);
          dc.drawArc(centerX, centerY, radius, Graphics.ARC_CLOCKWISE, 90, 90);
          
          if (progress <= 0) {
              return;
          }
          
          // Progress arc
          dc.setColor(color, Graphics.COLOR_TRANSPARENT);
          
          // Calculate degrees (start from top, go clockwise)
          var degrees = (progress * 360).toNumber();
          var startAngle = 90; // Top of circle
          var endAngle = startAngle - degrees;
          
          if (endAngle < 0) {
              endAngle += 360;
          }
          
          dc.drawArc(centerX, centerY, radius, Graphics.ARC_CLOCKWISE, startAngle, endAngle);
          dc.setPenWidth(1); // Reset pen width
      }
  }
  ```

---

## Testing Checklist

### Visual Layout Tests

Run each test on BOTH Fenix 7 simulator AND Fenix 8 simulator.

- [ ] **Test U3.1: Element Positioning**
  1. Launch app with test routine
  2. **Expected:** Routine name visible at top
  3. **Expected:** Time centered vertically
  4. **Expected:** Step name below time
  5. **Expected:** Progress bar below step name
  6. **Expected:** Next step info near bottom
  7. **Expected:** Step indicator at bottom

- [ ] **Test U3.2: Text Readability - Fenix 7 (MIP)**
  1. Launch on Fenix 7 simulator
  2. **Expected:** All text is readable
  3. **Expected:** High contrast (white on black)
  4. **Expected:** No text overlapping

- [ ] **Test U3.3: Text Readability - Fenix 8 (AMOLED)**
  1. Launch on Fenix 8 simulator
  2. **Expected:** All text is readable
  3. **Expected:** Colors render correctly
  4. **Expected:** True blacks maintained

- [ ] **Test U3.4: Timer Font Size**
  1. Verify timer uses large number font
  2. **Expected:** Time is the most prominent element
  3. **Expected:** Easily readable at a glance

### Color State Tests

- [ ] **Test U3.5: Normal State Colors**
  1. Start routine with step > 30 seconds remaining
  2. **Expected:** Timer text is white
  3. **Expected:** Progress bar is Garmin blue (#00A0DD)

- [ ] **Test U3.6: Warning State Colors (< 30s)**
  1. Wait until timer shows < 30 seconds
  2. **Expected:** Timer text turns orange (#FF8C00)
  3. **Expected:** Progress bar turns orange

- [ ] **Test U3.7: Alert State Colors (< 10s)**
  1. Wait until timer shows < 10 seconds
  2. **Expected:** Timer text turns red (#FF4444)
  3. **Expected:** Progress bar turns red

- [ ] **Test U3.8: Alert State Pulsing**
  1. Watch timer during last 10 seconds
  2. **Expected:** Timer text pulses/flashes each second

### Progress Bar Tests

- [ ] **Test U3.9: Progress Bar Start**
  1. At step start (0% progress)
  2. **Expected:** Progress bar shows minimal or no fill

- [ ] **Test U3.10: Progress Bar Mid-Point**
  1. At 50% through a step
  2. **Expected:** Progress bar is approximately half filled

- [ ] **Test U3.11: Progress Bar Complete**
  1. At step end (100% progress)
  2. **Expected:** Progress bar is fully filled

- [ ] **Test U3.12: Progress Bar Resets**
  1. When step advances
  2. **Expected:** Progress bar resets to empty for new step

### State Display Tests

- [ ] **Test U3.13: Idle State Display**
  1. Launch app, don't start
  2. **Expected:** Shows "Press START to begin"
  3. **Expected:** Timer shows first step's duration

- [ ] **Test U3.14: Paused State Display**
  1. Start routine, then pause
  2. **Expected:** "⏸ PAUSED" indicator visible
  3. **Expected:** Timer frozen at current time

- [ ] **Test U3.15: Complete Screen**
  1. Complete all steps of routine
  2. **Expected:** Shows checkmark
  3. **Expected:** Shows "ROUTINE COMPLETE"
  4. **Expected:** Shows routine name
  5. **Expected:** Shows target time
  6. **Expected:** Shows exit hint

### Responsive Layout Tests

- [ ] **Test U3.16: Fenix 7S (240×240)**
  1. Run on smallest target device
  2. **Expected:** All elements visible
  3. **Expected:** No text clipping
  4. **Expected:** Appropriate spacing

- [ ] **Test U3.17: Fenix 7X (280×280)**
  1. Run on largest Fenix 7 variant
  2. **Expected:** Layout scales appropriately
  3. **Expected:** No excessive empty space

- [ ] **Test U3.18: Fenix 8 (454×454)**
  1. Run on high-res AMOLED device
  2. **Expected:** Text is appropriately sized
  3. **Expected:** Progress bar visible
  4. **Expected:** Colors vibrant on AMOLED

### Edge Cases

- [ ] **Test U3.19: Long Routine Name**
  1. Create routine with 32-character name
  2. **Expected:** Name truncates or wraps gracefully
  3. **Expected:** No UI breakage

- [ ] **Test U3.20: Long Step Name**
  1. Create step with 24-character name
  2. **Expected:** Name displays or truncates gracefully

- [ ] **Test U3.21: Many Steps**
  1. Create routine with 10+ steps
  2. **Expected:** Step indicator shows correct count
  3. **Expected:** UI remains stable

---

## Success Criteria

| Criteria | Requirement |
|----------|-------------|
| Matches spec mockups | UI layout matches ASCII art from app_spec.md |
| Color states work | Normal → Warning → Alert transitions work |
| Progress bar accurate | Reflects actual step progress |
| Responsive layout | Works on all 6 target devices |
| State indicators | Idle, Running, Paused, Complete all displayed correctly |
| Typography hierarchy | Time is most prominent, step name secondary |
| No overlapping elements | All text and graphics properly spaced |

---

## Acceptance Criteria

This milestone is **COMPLETE** when:

1. ✅ All implementation checkboxes are checked
2. ✅ All tests U3.1 through U3.21 pass
3. ✅ UI matches the spec mockups from app_spec.md
4. ✅ Color transitions work correctly at 30s and 10s thresholds
5. ✅ Layout works on all target devices (verified in simulator)
6. ✅ Complete screen displays with all required elements

---

## Design Reference

Refer to the ASCII mockups in `../app_spec.md` section "User Interface Design" for the exact layout specification:

- Main Timer Screen (Active Routine)
- Timer Screen (Warning State)
- Timer Screen (Alert State)
- Paused State
- Routine Complete Screen

---

## Files Created/Modified in This Milestone

```
routine-timers/
├── source/
│   ├── RoutineTimersView.mc        ✓ Modified (major rewrite)
│   └── utils/
│       ├── ColorUtils.mc           ✓ Created
│       ├── LayoutConstants.mc      ✓ Created
│       └── CircularProgress.mc     ✓ Created (optional)
├── resources/
│   ├── resources-fenix7/           ✓ Created (optional)
│   └── resources-fenix8/           ✓ Created (optional)
```

---

## Next Milestone

Once all criteria are met, proceed to **[M4: Routine Storage & Selection](./M4_storage_selection.md)**
