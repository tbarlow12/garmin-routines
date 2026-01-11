# Milestone 5: Alerts & Haptic Feedback

**Estimated Duration:** 1-2 days  
**Dependencies:** M4 (Storage & Selection)  
**Deliverable:** Vibration and audio alerts at step transitions with configurable settings

---

## Goal

Implement tactile (vibration) and audio feedback to notify users of step transitions, warnings, and routine completion. Users should be able to feel/hear when a step is about to end and when the next step begins, even without looking at the watch.

---

## Implementation Checklist

### Alert Service

- [ ] Create `source/services/AlertService.mc`:
  ```monkeyc
  import Toybox.Attention;
  import Toybox.Lang;
  import Toybox.System;

  // Alert types for different events
  enum AlertType {
      ALERT_STEP_START,       // New step beginning
      ALERT_STEP_WARNING,     // Approaching step end (30s)
      ALERT_STEP_ENDING,      // About to end (10s)
      ALERT_STEP_COMPLETE,    // Step finished
      ALERT_ROUTINE_COMPLETE, // All steps done
      ALERT_ROUTINE_START,    // Routine beginning
      ALERT_PAUSE,            // Routine paused
      ALERT_RESUME            // Routine resumed
  }

  module AlertService {
      // Settings (will be loaded from properties later)
      private var _vibrateEnabled = true;
      private var _soundEnabled = false;

      // Initialize with current settings
      function initialize() as Void {
          // Load from properties in future
          _vibrateEnabled = true;
          _soundEnabled = false;
      }

      // Enable/disable vibration
      function setVibrateEnabled(enabled as Boolean) as Void {
          _vibrateEnabled = enabled;
      }

      // Enable/disable sound
      function setSoundEnabled(enabled as Boolean) as Void {
          _soundEnabled = enabled;
      }

      // Check if vibration is supported
      function canVibrate() as Boolean {
          return Attention has :vibrate;
      }

      // Check if tones are supported
      function canPlayTone() as Boolean {
          return Attention has :playTone;
      }

      // Main alert function - handles both vibration and sound
      function alert(alertType as AlertType) as Void {
          if (_vibrateEnabled && canVibrate()) {
              vibrateForAlert(alertType);
          }
          
          if (_soundEnabled && canPlayTone()) {
              playToneForAlert(alertType);
          }
      }

      // Vibration patterns for different alert types
      private function vibrateForAlert(alertType as AlertType) as Void {
          var vibeProfile;
          
          switch (alertType) {
              case ALERT_ROUTINE_START:
                  // Strong double pulse - routine beginning
                  vibeProfile = [
                      new Attention.VibeProfile(100, 200),
                      new Attention.VibeProfile(0, 100),
                      new Attention.VibeProfile(100, 200)
                  ];
                  break;
                  
              case ALERT_STEP_START:
                  // Medium single pulse - new step
                  vibeProfile = [
                      new Attention.VibeProfile(75, 150)
                  ];
                  break;
                  
              case ALERT_STEP_WARNING:
                  // Gentle pulse - 30 second warning
                  vibeProfile = [
                      new Attention.VibeProfile(50, 100)
                  ];
                  break;
                  
              case ALERT_STEP_ENDING:
                  // Quick pulses - 10 second warning
                  vibeProfile = [
                      new Attention.VibeProfile(75, 75),
                      new Attention.VibeProfile(0, 50),
                      new Attention.VibeProfile(75, 75)
                  ];
                  break;
                  
              case ALERT_STEP_COMPLETE:
                  // Step done - similar to step start
                  vibeProfile = [
                      new Attention.VibeProfile(75, 150)
                  ];
                  break;
                  
              case ALERT_ROUTINE_COMPLETE:
                  // Celebration pattern - routine done!
                  vibeProfile = [
                      new Attention.VibeProfile(100, 200),
                      new Attention.VibeProfile(0, 100),
                      new Attention.VibeProfile(100, 200),
                      new Attention.VibeProfile(0, 100),
                      new Attention.VibeProfile(100, 300)
                  ];
                  break;
                  
              case ALERT_PAUSE:
                  // Short single pulse
                  vibeProfile = [
                      new Attention.VibeProfile(50, 100)
                  ];
                  break;
                  
              case ALERT_RESUME:
                  // Short single pulse
                  vibeProfile = [
                      new Attention.VibeProfile(50, 100)
                  ];
                  break;
                  
              default:
                  vibeProfile = [
                      new Attention.VibeProfile(50, 100)
                  ];
          }
          
          try {
              Attention.vibrate(vibeProfile);
          } catch (e) {
              System.println("Vibration error: " + e.getErrorMessage());
          }
      }

      // Tone types for different alerts
      private function playToneForAlert(alertType as AlertType) as Void {
          var toneType;
          
          switch (alertType) {
              case ALERT_ROUTINE_START:
                  toneType = Attention.TONE_START;
                  break;
                  
              case ALERT_STEP_START:
                  toneType = Attention.TONE_KEY;
                  break;
                  
              case ALERT_STEP_WARNING:
                  toneType = Attention.TONE_ALERT_LO;
                  break;
                  
              case ALERT_STEP_ENDING:
                  toneType = Attention.TONE_ALERT_HI;
                  break;
                  
              case ALERT_STEP_COMPLETE:
                  toneType = Attention.TONE_KEY;
                  break;
                  
              case ALERT_ROUTINE_COMPLETE:
                  toneType = Attention.TONE_SUCCESS;
                  break;
                  
              case ALERT_PAUSE:
                  toneType = Attention.TONE_STOP;
                  break;
                  
              case ALERT_RESUME:
                  toneType = Attention.TONE_START;
                  break;
                  
              default:
                  toneType = Attention.TONE_KEY;
          }
          
          try {
              Attention.playTone(toneType);
          } catch (e) {
              System.println("Tone error: " + e.getErrorMessage());
          }
      }

      // Convenience methods for specific alerts
      function alertRoutineStart() as Void {
          alert(ALERT_ROUTINE_START);
      }

      function alertStepStart() as Void {
          alert(ALERT_STEP_START);
      }

      function alertStepWarning() as Void {
          alert(ALERT_STEP_WARNING);
      }

      function alertStepEnding() as Void {
          alert(ALERT_STEP_ENDING);
      }

      function alertStepComplete() as Void {
          alert(ALERT_STEP_COMPLETE);
      }

      function alertRoutineComplete() as Void {
          alert(ALERT_ROUTINE_COMPLETE);
      }

      function alertPause() as Void {
          alert(ALERT_PAUSE);
      }

      function alertResume() as Void {
          alert(ALERT_RESUME);
      }
  }
  ```

### Integrate Alerts with RoutineService

- [ ] Update `RoutineService.mc` to trigger alerts:
  ```monkeyc
  // Add these alert triggers in the appropriate methods:

  // In start() method, after _state = ROUTINE_RUNNING:
  function start() as Void {
      // ... existing code ...
      _state = ROUTINE_RUNNING;
      
      // Alert on routine start
      if (_currentStepIndex == 0) {
          AlertService.alertRoutineStart();
      }
      
      startCurrentStep();
  }

  // In startCurrentStep(), after setting up the step:
  private function startCurrentStep() as Void {
      // ... existing code ...
      
      // Alert on step start (but not on first start - that uses routine start)
      if (_state == ROUTINE_RUNNING && _currentStepIndex > 0) {
          AlertService.alertStepStart();
      }
      
      // ... existing callback code ...
  }

  // In pause() method:
  function pause() as Void {
      if (_state != ROUTINE_RUNNING) {
          return;
      }
      _timerService.pause();
      _state = ROUTINE_PAUSED;
      
      AlertService.alertPause();
  }

  // In resume() method:
  function resume() as Void {
      if (_state != ROUTINE_PAUSED) {
          return;
      }
      _timerService.resume();
      _state = ROUTINE_RUNNING;
      
      AlertService.alertResume();
  }

  // In completeRoutine() method:
  private function completeRoutine() as Void {
      _state = ROUTINE_COMPLETE;
      _timerService.stop();
      
      AlertService.alertRoutineComplete();
      
      // ... existing callback code ...
  }

  // In onStepComplete() method, before nextStep():
  function onStepComplete() as Void {
      AlertService.alertStepComplete();
      
      // ... existing code ...
  }
  ```

### Warning Alerts During Countdown

- [ ] Update `RoutineService.mc` to track warning states:
  ```monkeyc
  // Add instance variables:
  private var _hasTriggeredWarning as Boolean;
  private var _hasTriggeredEnding as Boolean;

  // In initialize():
  function initialize() {
      // ... existing code ...
      _hasTriggeredWarning = false;
      _hasTriggeredEnding = false;
  }

  // In startCurrentStep():
  private function startCurrentStep() as Void {
      // Reset alert flags for new step
      _hasTriggeredWarning = false;
      _hasTriggeredEnding = false;
      
      // ... rest of existing code ...
  }

  // In onTimerTick():
  function onTimerTick() as Void {
      var remaining = _timerService.getRemainingSeconds();
      
      // Check for warning threshold (30 seconds)
      if (!_hasTriggeredWarning && remaining <= 30 && remaining > 10) {
          _hasTriggeredWarning = true;
          AlertService.alertStepWarning();
      }
      
      // Check for ending threshold (10 seconds)
      if (!_hasTriggeredEnding && remaining <= 10 && remaining > 0) {
          _hasTriggeredEnding = true;
          AlertService.alertStepEnding();
      }
      
      if (_onTickCallback != null) {
          _onTickCallback.invoke();
      }
  }
  ```

### Per-Step Alert Settings

- [ ] Update `Step.mc` model to use alert settings:
  ```monkeyc
  class Step {
      // ... existing fields ...
      var alertSound as Boolean;
      var alertVibrate as Boolean;
      
      // These should already be in the model, just ensure they're used
  }
  ```

- [ ] Update `AlertService.mc` to check per-step settings:
  ```monkeyc
  // Add overload that accepts step settings
  function alertForStep(alertType as AlertType, step as Step?) as Void {
      if (step == null) {
          alert(alertType);
          return;
      }
      
      if (step.alertVibrate && canVibrate()) {
          vibrateForAlert(alertType);
      }
      
      if (step.alertSound && canPlayTone()) {
          playToneForAlert(alertType);
      }
  }
  ```

### Backlight Control (Optional Enhancement)

- [ ] Add backlight flash for alerts:
  ```monkeyc
  // In AlertService.mc

  // Flash backlight on alert (helpful for notifications)
  function flashBacklight() as Void {
      if (Attention has :backlight) {
          try {
              Attention.backlight(true);
              // Backlight will auto-off based on device settings
          } catch (e) {
              // Ignore backlight errors
          }
      }
  }

  // Update alert() to optionally flash backlight
  function alertWithBacklight(alertType as AlertType) as Void {
      flashBacklight();
      alert(alertType);
  }
  ```

---

## Testing Checklist

### Vibration Tests

Run on actual device if possible, as simulator may not show vibration.

- [ ] **Test A5.1: Routine Start Vibration**
  1. Start a routine
  2. **Expected:** Double pulse vibration
  3. **Expected:** Feels distinct from other alerts

- [ ] **Test A5.2: Step Transition Vibration**
  1. Let a step complete and advance to next
  2. **Expected:** Single pulse vibration
  3. **Expected:** Indicates new step started

- [ ] **Test A5.3: Warning Vibration (30s)**
  1. Wait until step has 30 seconds remaining
  2. **Expected:** Gentle single pulse
  3. **Expected:** Only triggers once

- [ ] **Test A5.4: Ending Vibration (10s)**
  1. Wait until step has 10 seconds remaining
  2. **Expected:** Quick double pulse
  3. **Expected:** Only triggers once

- [ ] **Test A5.5: Routine Complete Vibration**
  1. Complete all steps
  2. **Expected:** Celebration pattern (3 pulses)
  3. **Expected:** Distinctly different from other alerts

- [ ] **Test A5.6: Pause Vibration**
  1. Pause a running routine
  2. **Expected:** Short single pulse

- [ ] **Test A5.7: Resume Vibration**
  1. Resume a paused routine
  2. **Expected:** Short single pulse

### Audio Tests (if enabled)

- [ ] **Test A5.8: Sound on Step Start**
  1. Enable sound in settings
  2. Start routine, advance to second step
  3. **Expected:** Audible tone plays

- [ ] **Test A5.9: Sound on Routine Complete**
  1. Enable sound
  2. Complete routine
  3. **Expected:** Success tone plays

### Alert Timing Tests

- [ ] **Test A5.10: Warning Only Once**
  1. Start a step with > 30 seconds
  2. Wait past 30 second mark
  3. **Expected:** Warning alert triggers once at 30s
  4. Wait past 10 second mark
  5. **Expected:** Ending alert triggers once at 10s
  6. **Expected:** No duplicate alerts

- [ ] **Test A5.11: Short Step (< 30s)**
  1. Create step with 15 second duration
  2. Start step
  3. **Expected:** No 30s warning (step is too short)
  4. **Expected:** 10s warning still triggers at 10s

- [ ] **Test A5.12: Very Short Step (< 10s)**
  1. Create step with 5 second duration
  2. Start step
  3. **Expected:** No warnings (step too short for thresholds)
  4. **Expected:** Step complete alert still triggers

### Step-Specific Settings Tests

- [ ] **Test A5.13: Step with Vibrate Disabled**
  1. Create step with alertVibrate = false
  2. Advance to that step
  3. **Expected:** No vibration for that step
  4. **Expected:** Next step (if enabled) vibrates

- [ ] **Test A5.14: Step with Sound Enabled**
  1. Create step with alertSound = true
  2. Advance to that step
  3. **Expected:** Tone plays
  4. **Expected:** Other steps follow global setting

### Edge Cases

- [ ] **Test A5.15: Skip Step Alerts**
  1. Start routine
  2. Immediately skip to next step (DOWN button)
  3. **Expected:** Appropriate step start alert
  4. **Expected:** No lingering alerts from previous step

- [ ] **Test A5.16: Rapid Navigation**
  1. Skip through steps quickly (up/down)
  2. **Expected:** Alerts fire for each step entered
  3. **Expected:** No crashes or overlapping alerts

- [ ] **Test A5.17: Pause During Warning Period**
  1. Wait until < 30 seconds remaining
  2. Pause the routine
  3. Resume the routine
  4. **Expected:** No duplicate warning alerts

### Device Compatibility

- [ ] **Test A5.18: Vibration on Fenix 7**
  1. Test on Fenix 7 device or simulator
  2. **Expected:** Vibration patterns work correctly

- [ ] **Test A5.19: Vibration on Fenix 8**
  1. Test on Fenix 8 device or simulator
  2. **Expected:** Vibration patterns work correctly

---

## Success Criteria

| Criteria | Requirement |
|----------|-------------|
| Vibration works | All alert types produce distinct vibration |
| Sound works | Tones play when enabled |
| Timing correct | Warnings trigger at 30s and 10s thresholds |
| No duplicates | Each threshold alert fires only once |
| Per-step settings | Individual step alert preferences honored |
| Graceful fallback | Works on devices without vibration/sound |
| No crashes | Rapid navigation doesn't cause issues |

---

## Acceptance Criteria

This milestone is **COMPLETE** when:

1. ✅ All implementation checkboxes are checked
2. ✅ All tests A5.1 through A5.19 pass
3. ✅ Vibration alerts are distinct and timely
4. ✅ Audio alerts work when enabled
5. ✅ Warning alerts trigger at correct thresholds
6. ✅ Alerts respect per-step settings

---

## Vibration Pattern Reference

| Alert Type | Pattern | Description |
|------------|---------|-------------|
| Routine Start | ▓▓░▓▓ | Strong double pulse |
| Step Start | ▓▓ | Medium single pulse |
| 30s Warning | ▒ | Gentle pulse |
| 10s Ending | ▓░▓ | Quick double pulse |
| Step Complete | ▓▓ | Medium single pulse |
| Routine Complete | ▓▓░▓▓░▓▓▓ | Celebration pattern |
| Pause/Resume | ▒ | Short pulse |

*▓ = strong (100%), ▒ = gentle (50%), ░ = gap*

---

## Files Created/Modified in This Milestone

```
routine-timers/
├── source/
│   ├── services/
│   │   ├── AlertService.mc        ✓ Created
│   │   └── RoutineService.mc      ✓ Modified
```

---

## Next Milestone

Once all criteria are met, proceed to **[M6: Background Service & Scheduling](./M6_background_scheduling.md)**
