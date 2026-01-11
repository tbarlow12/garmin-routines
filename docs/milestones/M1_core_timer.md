# Milestone 1: Core Timer Engine

**Estimated Duration:** 2-3 days  
**Dependencies:** M0 (Project Setup)  
**Deliverable:** A working countdown timer that can count down from a specified duration

---

## Goal

Build the core timer engine that powers the entire application. This is a headless service (logic only, no UI changes yet) that manages countdown state, supports pause/resume, and emits events when the timer completes.

---

## Implementation Checklist

### Timer Service

- [ ] Create `source/services/TimerService.mc`:
  ```monkeyc
  import Toybox.Lang;
  import Toybox.Timer;
  import Toybox.System;

  // Timer states
  enum TimerState {
      TIMER_IDLE,
      TIMER_RUNNING,
      TIMER_PAUSED,
      TIMER_COMPLETE
  }

  // Callback interface for timer events
  typedef TimerCallback as Method() as Void;

  class TimerService {
      private var _timer as Timer.Timer?;
      private var _remainingSeconds as Number;
      private var _totalSeconds as Number;
      private var _state as TimerState;
      private var _onTickCallback as TimerCallback?;
      private var _onCompleteCallback as TimerCallback?;

      function initialize() {
          _timer = null;
          _remainingSeconds = 0;
          _totalSeconds = 0;
          _state = TIMER_IDLE;
          _onTickCallback = null;
          _onCompleteCallback = null;
      }

      // Configure the timer with a duration in seconds
      function setDuration(seconds as Number) as Void {
          if (_state == TIMER_RUNNING) {
              throw new Lang.InvalidValueException("Cannot set duration while running");
          }
          _totalSeconds = seconds;
          _remainingSeconds = seconds;
          _state = TIMER_IDLE;
      }

      // Start or resume the timer
      function start() as Void {
          if (_state == TIMER_RUNNING) {
              return; // Already running
          }
          if (_remainingSeconds <= 0) {
              return; // Nothing to count
          }
          
          _state = TIMER_RUNNING;
          _timer = new Timer.Timer();
          _timer.start(method(:onTimerTick), 1000, true); // 1 second interval
      }

      // Pause the timer
      function pause() as Void {
          if (_state != TIMER_RUNNING) {
              return;
          }
          _state = TIMER_PAUSED;
          if (_timer != null) {
              _timer.stop();
              _timer = null;
          }
      }

      // Resume from pause
      function resume() as Void {
          if (_state != TIMER_PAUSED) {
              return;
          }
          start();
      }

      // Stop and reset the timer
      function stop() as Void {
          if (_timer != null) {
              _timer.stop();
              _timer = null;
          }
          _remainingSeconds = _totalSeconds;
          _state = TIMER_IDLE;
      }

      // Reset to initial duration
      function reset() as Void {
          stop();
      }

      // Timer tick handler (called every second)
      function onTimerTick() as Void {
          if (_state != TIMER_RUNNING) {
              return;
          }

          _remainingSeconds -= 1;

          // Notify tick listener
          if (_onTickCallback != null) {
              _onTickCallback.invoke();
          }

          // Check for completion
          if (_remainingSeconds <= 0) {
              _remainingSeconds = 0;
              _state = TIMER_COMPLETE;
              
              if (_timer != null) {
                  _timer.stop();
                  _timer = null;
              }

              if (_onCompleteCallback != null) {
                  _onCompleteCallback.invoke();
              }
          }
      }

      // Register callback for each tick
      function setOnTickCallback(callback as TimerCallback?) as Void {
          _onTickCallback = callback;
      }

      // Register callback for timer completion
      function setOnCompleteCallback(callback as TimerCallback?) as Void {
          _onCompleteCallback = callback;
      }

      // Getters
      function getRemainingSeconds() as Number {
          return _remainingSeconds;
      }

      function getTotalSeconds() as Number {
          return _totalSeconds;
      }

      function getElapsedSeconds() as Number {
          return _totalSeconds - _remainingSeconds;
      }

      function getState() as TimerState {
          return _state;
      }

      function isRunning() as Boolean {
          return _state == TIMER_RUNNING;
      }

      function isPaused() as Boolean {
          return _state == TIMER_PAUSED;
      }

      function isComplete() as Boolean {
          return _state == TIMER_COMPLETE;
      }

      function getProgressPercent() as Float {
          if (_totalSeconds == 0) {
              return 0.0f;
          }
          return (_totalSeconds - _remainingSeconds).toFloat() / _totalSeconds.toFloat();
      }
  }
  ```

- [ ] Verify TimerService compiles without errors

### Time Formatting Utility

- [ ] Create `source/utils/TimeFormatter.mc`:
  ```monkeyc
  import Toybox.Lang;

  module TimeFormatter {
      // Format seconds as "MM:SS"
      function formatMinutesSeconds(totalSeconds as Number) as String {
          if (totalSeconds < 0) {
              totalSeconds = 0;
          }
          
          var minutes = totalSeconds / 60;
          var seconds = totalSeconds % 60;
          
          var minutesStr = minutes.format("%d");
          var secondsStr = seconds.format("%02d");
          
          return minutesStr + ":" + secondsStr;
      }

      // Format seconds as "H:MM:SS" for durations over 1 hour
      function formatHoursMinutesSeconds(totalSeconds as Number) as String {
          if (totalSeconds < 0) {
              totalSeconds = 0;
          }
          
          var hours = totalSeconds / 3600;
          var remaining = totalSeconds % 3600;
          var minutes = remaining / 60;
          var seconds = remaining % 60;
          
          if (hours > 0) {
              return hours.format("%d") + ":" + 
                     minutes.format("%02d") + ":" + 
                     seconds.format("%02d");
          } else {
              return formatMinutesSeconds(totalSeconds);
          }
      }

      // Smart format: uses H:MM:SS only when needed
      function formatSmart(totalSeconds as Number) as String {
          if (totalSeconds >= 3600) {
              return formatHoursMinutesSeconds(totalSeconds);
          }
          return formatMinutesSeconds(totalSeconds);
      }
  }
  ```

- [ ] Verify TimeFormatter compiles without errors

### Integration with View (Temporary Display)

- [ ] Update `RoutineTimersView.mc` to display timer:
  ```monkeyc
  import Toybox.Graphics;
  import Toybox.WatchUi;
  import Toybox.Lang;

  class RoutineTimersView extends WatchUi.View {
      private var _timerService as TimerService;

      function initialize() {
          View.initialize();
          _timerService = new TimerService();
          _timerService.setDuration(120); // 2 minutes for testing
          _timerService.setOnTickCallback(method(:onTimerTick));
          _timerService.setOnCompleteCallback(method(:onTimerComplete));
      }

      function onTimerTick() as Void {
          WatchUi.requestUpdate();
      }

      function onTimerComplete() as Void {
          WatchUi.requestUpdate();
      }

      function getTimerService() as TimerService {
          return _timerService;
      }

      function onLayout(dc as Dc) as Void {
      }

      function onShow() as Void {
      }

      function onUpdate(dc as Dc) as Void {
          dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
          dc.clear();

          var timeText = TimeFormatter.formatSmart(_timerService.getRemainingSeconds());
          var stateText = "";

          var state = _timerService.getState();
          if (state == TIMER_IDLE) {
              stateText = "Press START";
          } else if (state == TIMER_RUNNING) {
              stateText = "Running";
          } else if (state == TIMER_PAUSED) {
              stateText = "Paused";
          } else if (state == TIMER_COMPLETE) {
              stateText = "Complete!";
          }

          // Draw time
          dc.drawText(
              dc.getWidth() / 2,
              dc.getHeight() / 2 - 20,
              Graphics.FONT_NUMBER_MEDIUM,
              timeText,
              Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
          );

          // Draw state
          dc.drawText(
              dc.getWidth() / 2,
              dc.getHeight() / 2 + 40,
              Graphics.FONT_SMALL,
              stateText,
              Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
          );
      }

      function onHide() as Void {
      }
  }
  ```

- [ ] Update `RoutineTimersDelegate.mc` to handle button presses:
  ```monkeyc
  import Toybox.Lang;
  import Toybox.WatchUi;
  import Toybox.System;

  class RoutineTimersDelegate extends WatchUi.BehaviorDelegate {
      private var _view as RoutineTimersView;

      function initialize(view as RoutineTimersView) {
          BehaviorDelegate.initialize();
          _view = view;
      }

      function onSelect() as Boolean {
          // START/STOP button pressed
          var timer = _view.getTimerService();
          
          if (timer.isRunning()) {
              timer.pause();
          } else if (timer.isPaused()) {
              timer.resume();
          } else if (timer.isComplete()) {
              timer.reset();
          } else {
              timer.start();
          }
          
          WatchUi.requestUpdate();
          return true;
      }

      function onBack() as Boolean {
          var timer = _view.getTimerService();
          
          // If running or paused, stop and reset
          if (timer.isRunning() || timer.isPaused()) {
              timer.stop();
              WatchUi.requestUpdate();
              return true;
          }
          
          // Otherwise, exit the widget
          WatchUi.popView(WatchUi.SLIDE_RIGHT);
          return true;
      }
  }
  ```

- [ ] Update `RoutineTimersApp.mc` to pass view to delegate:
  ```monkeyc
  function getInitialView() as [Views] or [Views, InputDelegates] {
      var view = new RoutineTimersView();
      return [view, new RoutineTimersDelegate(view)];
  }
  ```

---

## Testing Checklist

### Unit Tests (Manual Verification in Simulator)

- [ ] **Test T1.1: Timer Initialization**
  1. Launch the app in simulator
  2. **Expected:** Display shows "2:00" (initial duration)
  3. **Expected:** Display shows "Press START"

- [ ] **Test T1.2: Timer Start**
  1. Press the SELECT/START button
  2. **Expected:** Timer starts counting down
  3. **Expected:** State shows "Running"
  4. Wait 5 seconds
  5. **Expected:** Display shows "1:55"

- [ ] **Test T1.3: Timer Pause**
  1. While timer is running, press SELECT/START
  2. **Expected:** Timer pauses
  3. **Expected:** State shows "Paused"
  4. **Expected:** Time does NOT continue to decrease

- [ ] **Test T1.4: Timer Resume**
  1. While timer is paused, press SELECT/START
  2. **Expected:** Timer resumes counting down
  3. **Expected:** State shows "Running"

- [ ] **Test T1.5: Timer Reset (via BACK)**
  1. Start the timer
  2. Wait a few seconds
  3. Press BACK button
  4. **Expected:** Timer resets to "2:00"
  5. **Expected:** State shows "Press START"

- [ ] **Test T1.6: Timer Completion**
  1. Set a short duration (modify code to use 5 seconds)
  2. Start the timer
  3. Wait for completion
  4. **Expected:** Display shows "0:00"
  5. **Expected:** State shows "Complete!"

- [ ] **Test T1.7: Reset After Completion**
  1. After timer completes, press SELECT/START
  2. **Expected:** Timer resets to initial duration
  3. **Expected:** State shows "Press START"

### Time Formatting Tests

- [ ] **Test T1.8: MM:SS Format**
  1. Set duration to 90 seconds (1:30)
  2. **Expected:** Displays "1:30"
  3. After 30 seconds: "1:00"
  4. After 60 seconds: "0:30"
  5. After 85 seconds: "0:05"

- [ ] **Test T1.9: Leading Zero Seconds**
  1. Observe time at 2:05, 1:03, 0:09
  2. **Expected:** Seconds always show two digits (05, 03, 09)

- [ ] **Test T1.10: H:MM:SS Format**
  1. Modify code to set duration to 3661 seconds (1:01:01)
  2. **Expected:** Displays "1:01:01"

### Edge Cases

- [ ] **Test T1.11: Rapid Start/Pause**
  1. Start the timer
  2. Immediately pause
  3. Immediately resume
  4. Repeat 5 times quickly
  5. **Expected:** No crashes, timer behaves correctly

- [ ] **Test T1.12: Double Start**
  1. Start the timer
  2. Call start() again (modify code temporarily)
  3. **Expected:** Timer continues normally, does not restart or double-speed

- [ ] **Test T1.13: Pause When Not Running**
  1. With timer in IDLE state, call pause()
  2. **Expected:** Nothing happens, no crash

- [ ] **Test T1.14: Zero Duration**
  1. Set duration to 0
  2. Call start()
  3. **Expected:** Timer does not start, or immediately completes

---

## Success Criteria

| Criteria | Requirement |
|----------|-------------|
| TimerService compiles | Zero errors |
| TimeFormatter compiles | Zero errors |
| Timer counts down | Decrements by 1 every second |
| Pause works | Timer stops decrementing when paused |
| Resume works | Timer continues from paused time |
| Reset works | Timer returns to initial duration |
| Completion detected | State changes to COMPLETE at 0 |
| Callbacks fire | onTick and onComplete are invoked |
| Time formatting | MM:SS and H:MM:SS display correctly |

---

## Acceptance Criteria

This milestone is **COMPLETE** when:

1. ✅ All implementation checkboxes are checked
2. ✅ All tests T1.1 through T1.14 pass
3. ✅ TimerService can be instantiated with any duration
4. ✅ Timer accuracy is within ±1 second over a 2-minute period
5. ✅ No memory leaks after starting/stopping timer 10 times

---

## Technical Notes

### Timer Resolution
The Garmin `Timer.Timer` class fires with approximately 1-second resolution. For most use cases this is sufficient. Do NOT attempt sub-second precision as it drains battery and is not needed for routine timing.

### Memory Considerations
- Create the `Timer.Timer` object only when starting
- Set it to `null` when stopping to allow garbage collection
- Avoid creating new objects in `onTimerTick()` to prevent GC pressure

### Thread Safety
Monkey C is single-threaded. The timer callback runs on the same thread as UI updates. Avoid long-running operations in callbacks.

---

## Files Created/Modified in This Milestone

```
routine-timers/
├── source/
│   ├── RoutineTimersApp.mc         ✓ Modified
│   ├── RoutineTimersView.mc        ✓ Modified
│   ├── RoutineTimersDelegate.mc    ✓ Modified
│   ├── services/
│   │   └── TimerService.mc         ✓ Created
│   └── utils/
│       └── TimeFormatter.mc        ✓ Created
```

---

## Next Milestone

Once all criteria are met, proceed to **[M2: Multi-Step Routine Execution](./M2_multi_step_routines.md)**
