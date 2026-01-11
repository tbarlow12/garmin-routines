# Milestone 2: Multi-Step Routine Execution

**Estimated Duration:** 2-3 days  
**Dependencies:** M1 (Core Timer Engine)  
**Deliverable:** Ability to define and execute a routine with multiple sequential steps

---

## Goal

Extend the timer engine to support routines containing multiple steps. The system should automatically advance through steps, track overall progress, and support navigation between steps.

---

## Implementation Checklist

### Data Models

- [ ] Create `source/models/Step.mc`:
  ```monkeyc
  import Toybox.Lang;

  class Step {
      var id as String;
      var name as String;
      var duration as Number;  // Duration in seconds
      var order as Number;
      var alertSound as Boolean;
      var alertVibrate as Boolean;

      function initialize(options as Dictionary) {
          id = options.hasKey(:id) ? options[:id] : generateId();
          name = options.hasKey(:name) ? options[:name] : "Step";
          duration = options.hasKey(:duration) ? options[:duration] : 60;
          order = options.hasKey(:order) ? options[:order] : 0;
          alertSound = options.hasKey(:alertSound) ? options[:alertSound] : false;
          alertVibrate = options.hasKey(:alertVibrate) ? options[:alertVibrate] : true;
      }

      // Generate a simple unique ID
      private function generateId() as String {
          var time = System.getTimer();
          return "step_" + time.toString();
      }

      // Serialize to dictionary for storage
      function toDict() as Dictionary {
          return {
              "id" => id,
              "name" => name,
              "duration" => duration,
              "order" => order,
              "alertSound" => alertSound,
              "alertVibrate" => alertVibrate
          };
      }

      // Create from dictionary (deserialization)
      static function fromDict(dict as Dictionary) as Step {
          return new Step({
              :id => dict["id"],
              :name => dict["name"],
              :duration => dict["duration"],
              :order => dict["order"],
              :alertSound => dict["alertSound"],
              :alertVibrate => dict["alertVibrate"]
          });
      }
  }
  ```

- [ ] Create `source/models/Routine.mc`:
  ```monkeyc
  import Toybox.Lang;
  import Toybox.Time;

  // Trigger types for routines
  enum TriggerType {
      TRIGGER_MANUAL,
      TRIGGER_SCHEDULED,
      TRIGGER_EVENT
  }

  class Routine {
      var id as String;
      var name as String;
      var steps as Array<Step>;
      var createdAt as Number;
      var updatedAt as Number;
      var triggerType as TriggerType;
      var scheduledTime as Number?;      // Seconds from midnight
      var scheduledDays as Array<Number>?; // 0=Sun, 1=Mon, ..., 6=Sat

      function initialize(options as Dictionary) {
          id = options.hasKey(:id) ? options[:id] : generateId();
          name = options.hasKey(:name) ? options[:name] : "New Routine";
          steps = options.hasKey(:steps) ? options[:steps] : [];
          createdAt = options.hasKey(:createdAt) ? options[:createdAt] : Time.now().value();
          updatedAt = options.hasKey(:updatedAt) ? options[:updatedAt] : Time.now().value();
          triggerType = options.hasKey(:triggerType) ? options[:triggerType] : TRIGGER_MANUAL;
          scheduledTime = options.hasKey(:scheduledTime) ? options[:scheduledTime] : null;
          scheduledDays = options.hasKey(:scheduledDays) ? options[:scheduledDays] : null;
      }

      private function generateId() as String {
          var time = System.getTimer();
          return "routine_" + time.toString();
      }

      // Get total duration of all steps in seconds
      function getTotalDuration() as Number {
          var total = 0;
          for (var i = 0; i < steps.size(); i++) {
              total += steps[i].duration;
          }
          return total;
      }

      // Get step count
      function getStepCount() as Number {
          return steps.size();
      }

      // Get step by index
      function getStep(index as Number) as Step? {
          if (index >= 0 && index < steps.size()) {
              return steps[index];
          }
          return null;
      }

      // Add a step
      function addStep(step as Step) as Void {
          step.order = steps.size();
          steps.add(step);
          updatedAt = Time.now().value();
      }

      // Remove a step by index
      function removeStep(index as Number) as Void {
          if (index >= 0 && index < steps.size()) {
              steps.remove(steps[index]);
              // Reorder remaining steps
              for (var i = 0; i < steps.size(); i++) {
                  steps[i].order = i;
              }
              updatedAt = Time.now().value();
          }
      }

      // Serialize to dictionary for storage
      function toDict() as Dictionary {
          var stepsArray = [];
          for (var i = 0; i < steps.size(); i++) {
              stepsArray.add(steps[i].toDict());
          }

          return {
              "id" => id,
              "name" => name,
              "steps" => stepsArray,
              "createdAt" => createdAt,
              "updatedAt" => updatedAt,
              "triggerType" => triggerType,
              "scheduledTime" => scheduledTime,
              "scheduledDays" => scheduledDays
          };
      }

      // Create from dictionary (deserialization)
      static function fromDict(dict as Dictionary) as Routine {
          var stepsData = dict["steps"] as Array;
          var stepObjects = [] as Array<Step>;
          
          for (var i = 0; i < stepsData.size(); i++) {
              stepObjects.add(Step.fromDict(stepsData[i]));
          }

          return new Routine({
              :id => dict["id"],
              :name => dict["name"],
              :steps => stepObjects,
              :createdAt => dict["createdAt"],
              :updatedAt => dict["updatedAt"],
              :triggerType => dict["triggerType"],
              :scheduledTime => dict.hasKey("scheduledTime") ? dict["scheduledTime"] : null,
              :scheduledDays => dict.hasKey("scheduledDays") ? dict["scheduledDays"] : null
          });
      }
  }
  ```

### Routine Execution Service

- [ ] Create `source/services/RoutineService.mc`:
  ```monkeyc
  import Toybox.Lang;
  import Toybox.WatchUi;

  // Routine execution states
  enum RoutineState {
      ROUTINE_IDLE,
      ROUTINE_RUNNING,
      ROUTINE_PAUSED,
      ROUTINE_COMPLETE
  }

  typedef RoutineCallback as Method() as Void;
  typedef StepChangeCallback as Method(stepIndex as Number, step as Step) as Void;

  class RoutineService {
      private var _routine as Routine?;
      private var _timerService as TimerService;
      private var _currentStepIndex as Number;
      private var _state as RoutineState;
      private var _autoAdvance as Boolean;

      // Callbacks
      private var _onStepChangeCallback as StepChangeCallback?;
      private var _onRoutineCompleteCallback as RoutineCallback?;
      private var _onTickCallback as RoutineCallback?;

      function initialize() {
          _timerService = new TimerService();
          _timerService.setOnTickCallback(method(:onTimerTick));
          _timerService.setOnCompleteCallback(method(:onStepComplete));
          
          _routine = null;
          _currentStepIndex = 0;
          _state = ROUTINE_IDLE;
          _autoAdvance = true;

          _onStepChangeCallback = null;
          _onRoutineCompleteCallback = null;
          _onTickCallback = null;
      }

      // Load a routine for execution
      function loadRoutine(routine as Routine) as Void {
          if (_state == ROUTINE_RUNNING) {
              stop();
          }
          
          _routine = routine;
          _currentStepIndex = 0;
          _state = ROUTINE_IDLE;
          
          // Load first step into timer
          var firstStep = _routine.getStep(0);
          if (firstStep != null) {
              _timerService.setDuration(firstStep.duration);
          }
      }

      // Start the routine
      function start() as Void {
          if (_routine == null || _routine.getStepCount() == 0) {
              return;
          }

          if (_state == ROUTINE_PAUSED) {
              _timerService.resume();
              _state = ROUTINE_RUNNING;
              return;
          }

          if (_state != ROUTINE_IDLE) {
              return;
          }

          _state = ROUTINE_RUNNING;
          _currentStepIndex = 0;
          
          startCurrentStep();
      }

      // Pause the routine
      function pause() as Void {
          if (_state != ROUTINE_RUNNING) {
              return;
          }
          _timerService.pause();
          _state = ROUTINE_PAUSED;
      }

      // Resume the routine
      function resume() as Void {
          if (_state != ROUTINE_PAUSED) {
              return;
          }
          _timerService.resume();
          _state = ROUTINE_RUNNING;
      }

      // Stop and reset the routine
      function stop() as Void {
          _timerService.stop();
          _currentStepIndex = 0;
          _state = ROUTINE_IDLE;
          
          // Reload first step
          if (_routine != null) {
              var firstStep = _routine.getStep(0);
              if (firstStep != null) {
                  _timerService.setDuration(firstStep.duration);
              }
          }
      }

      // Skip to next step
      function nextStep() as Void {
          if (_routine == null) {
              return;
          }

          if (_currentStepIndex < _routine.getStepCount() - 1) {
              _currentStepIndex++;
              startCurrentStep();
          } else {
              // Already on last step, complete the routine
              completeRoutine();
          }
      }

      // Go to previous step
      function previousStep() as Void {
          if (_routine == null) {
              return;
          }

          if (_currentStepIndex > 0) {
              _currentStepIndex--;
              startCurrentStep();
          }
          // If on first step, just restart it
          else {
              startCurrentStep();
          }
      }

      // Jump to a specific step
      function goToStep(index as Number) as Void {
          if (_routine == null) {
              return;
          }

          if (index >= 0 && index < _routine.getStepCount()) {
              _currentStepIndex = index;
              startCurrentStep();
          }
      }

      // Start the current step
      private function startCurrentStep() as Void {
          if (_routine == null) {
              return;
          }

          var step = _routine.getStep(_currentStepIndex);
          if (step == null) {
              return;
          }

          _timerService.stop();
          _timerService.setDuration(step.duration);
          
          if (_state == ROUTINE_RUNNING) {
              _timerService.start();
          }

          // Notify step change
          if (_onStepChangeCallback != null) {
              _onStepChangeCallback.invoke(_currentStepIndex, step);
          }
      }

      // Called when a step's timer completes
      function onStepComplete() as Void {
          if (_routine == null) {
              return;
          }

          // Check if there are more steps
          if (_currentStepIndex < _routine.getStepCount() - 1) {
              if (_autoAdvance) {
                  nextStep();
              } else {
                  _state = ROUTINE_PAUSED;
              }
          } else {
              // Last step completed
              completeRoutine();
          }
      }

      // Complete the routine
      private function completeRoutine() as Void {
          _state = ROUTINE_COMPLETE;
          _timerService.stop();

          if (_onRoutineCompleteCallback != null) {
              _onRoutineCompleteCallback.invoke();
          }
      }

      // Called on each timer tick
      function onTimerTick() as Void {
          if (_onTickCallback != null) {
              _onTickCallback.invoke();
          }
      }

      // Setters for callbacks
      function setOnStepChangeCallback(callback as StepChangeCallback?) as Void {
          _onStepChangeCallback = callback;
      }

      function setOnRoutineCompleteCallback(callback as RoutineCallback?) as Void {
          _onRoutineCompleteCallback = callback;
      }

      function setOnTickCallback(callback as RoutineCallback?) as Void {
          _onTickCallback = callback;
      }

      function setAutoAdvance(autoAdvance as Boolean) as Void {
          _autoAdvance = autoAdvance;
      }

      // Getters
      function getRoutine() as Routine? {
          return _routine;
      }

      function getCurrentStepIndex() as Number {
          return _currentStepIndex;
      }

      function getCurrentStep() as Step? {
          if (_routine != null) {
              return _routine.getStep(_currentStepIndex);
          }
          return null;
      }

      function getNextStep() as Step? {
          if (_routine != null && _currentStepIndex < _routine.getStepCount() - 1) {
              return _routine.getStep(_currentStepIndex + 1);
          }
          return null;
      }

      function getRemainingSeconds() as Number {
          return _timerService.getRemainingSeconds();
      }

      function getCurrentStepProgress() as Float {
          return _timerService.getProgressPercent();
      }

      function getState() as RoutineState {
          return _state;
      }

      function isRunning() as Boolean {
          return _state == ROUTINE_RUNNING;
      }

      function isPaused() as Boolean {
          return _state == ROUTINE_PAUSED;
      }

      function isComplete() as Boolean {
          return _state == ROUTINE_COMPLETE;
      }

      function isIdle() as Boolean {
          return _state == ROUTINE_IDLE;
      }

      // Calculate total elapsed time across all completed steps + current step progress
      function getTotalElapsedSeconds() as Number {
          if (_routine == null) {
              return 0;
          }

          var elapsed = 0;
          
          // Add durations of completed steps
          for (var i = 0; i < _currentStepIndex; i++) {
              var step = _routine.getStep(i);
              if (step != null) {
                  elapsed += step.duration;
              }
          }

          // Add elapsed time in current step
          var currentStep = getCurrentStep();
          if (currentStep != null) {
              elapsed += currentStep.duration - _timerService.getRemainingSeconds();
          }

          return elapsed;
      }

      // Get overall routine progress (0.0 to 1.0)
      function getOverallProgress() as Float {
          if (_routine == null) {
              return 0.0f;
          }

          var total = _routine.getTotalDuration();
          if (total == 0) {
              return 0.0f;
          }

          return getTotalElapsedSeconds().toFloat() / total.toFloat();
      }
  }
  ```

### Test Routine Factory

- [ ] Create `source/utils/TestDataFactory.mc` for development/testing:
  ```monkeyc
  import Toybox.Lang;

  module TestDataFactory {
      // Create a sample morning routine for testing
      function createMorningRoutine() as Routine {
          var routine = new Routine({
              :id => "test_morning",
              :name => "Morning Routine"
          });

          routine.addStep(new Step({
              :name => "Scripture Study",
              :duration => 20 * 60  // 20 minutes (use 20 seconds for testing: 20)
          }));

          routine.addStep(new Step({
              :name => "Tidy up office",
              :duration => 5 * 60   // 5 minutes (use 5 seconds for testing: 5)
          }));

          routine.addStep(new Step({
              :name => "Fill water bottle",
              :duration => 2 * 60   // 2 minutes (use 2 seconds for testing: 2)
          }));

          return routine;
      }

      // Create a quick test routine with short durations
      function createQuickTestRoutine() as Routine {
          var routine = new Routine({
              :id => "test_quick",
              :name => "Quick Test"
          });

          routine.addStep(new Step({
              :name => "Step One",
              :duration => 5  // 5 seconds
          }));

          routine.addStep(new Step({
              :name => "Step Two",
              :duration => 5  // 5 seconds
          }));

          routine.addStep(new Step({
              :name => "Step Three",
              :duration => 5  // 5 seconds
          }));

          return routine;
      }

      // Create a single-step routine
      function createSingleStepRoutine() as Routine {
          var routine = new Routine({
              :id => "test_single",
              :name => "Single Step"
          });

          routine.addStep(new Step({
              :name => "Only Step",
              :duration => 10
          }));

          return routine;
      }
  }
  ```

### Update View and Delegate

- [ ] Update `RoutineTimersView.mc` to use RoutineService:
  ```monkeyc
  import Toybox.Graphics;
  import Toybox.WatchUi;
  import Toybox.Lang;

  class RoutineTimersView extends WatchUi.View {
      private var _routineService as RoutineService;

      function initialize() {
          View.initialize();
          _routineService = new RoutineService();
          
          // Load test routine
          var testRoutine = TestDataFactory.createQuickTestRoutine();
          _routineService.loadRoutine(testRoutine);
          
          // Set up callbacks
          _routineService.setOnTickCallback(method(:onTick));
          _routineService.setOnStepChangeCallback(method(:onStepChange));
          _routineService.setOnRoutineCompleteCallback(method(:onRoutineComplete));
      }

      function onTick() as Void {
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
          dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
          dc.clear();

          var routine = _routineService.getRoutine();
          if (routine == null) {
              dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2,
                  Graphics.FONT_MEDIUM, "No Routine",
                  Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
              return;
          }

          var centerX = dc.getWidth() / 2;
          var centerY = dc.getHeight() / 2;

          // Routine name (top)
          dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
          dc.drawText(centerX, 30, Graphics.FONT_XTINY,
              routine.name.toUpper(),
              Graphics.TEXT_JUSTIFY_CENTER);

          // Time remaining (large, center)
          dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
          var timeText = TimeFormatter.formatSmart(_routineService.getRemainingSeconds());
          dc.drawText(centerX, centerY - 20, Graphics.FONT_NUMBER_MEDIUM,
              timeText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

          // Current step name
          var currentStep = _routineService.getCurrentStep();
          if (currentStep != null) {
              dc.drawText(centerX, centerY + 30, Graphics.FONT_SMALL,
                  currentStep.name,
                  Graphics.TEXT_JUSTIFY_CENTER);
          }

          // Step indicator (bottom)
          var stepText = "Step " + (_routineService.getCurrentStepIndex() + 1) + 
                        " of " + routine.getStepCount();
          dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
          dc.drawText(centerX, dc.getHeight() - 30, Graphics.FONT_XTINY,
              stepText, Graphics.TEXT_JUSTIFY_CENTER);

          // Next step (if available)
          var nextStep = _routineService.getNextStep();
          if (nextStep != null) {
              var nextText = "NEXT: " + nextStep.name + " " + 
                            TimeFormatter.formatSmart(nextStep.duration);
              dc.drawText(centerX, dc.getHeight() - 50, Graphics.FONT_XTINY,
                  nextText, Graphics.TEXT_JUSTIFY_CENTER);
          }

          // State indicator
          if (_routineService.isPaused()) {
              dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
              dc.drawText(centerX, 50, Graphics.FONT_TINY,
                  "PAUSED", Graphics.TEXT_JUSTIFY_CENTER);
          } else if (_routineService.isComplete()) {
              dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
              dc.drawText(centerX, centerY, Graphics.FONT_MEDIUM,
                  "COMPLETE!", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
          } else if (_routineService.isIdle()) {
              dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
              dc.drawText(centerX, dc.getHeight() - 50, Graphics.FONT_XTINY,
                  "Press START to begin", Graphics.TEXT_JUSTIFY_CENTER);
          }
      }
  }
  ```

- [ ] Update `RoutineTimersDelegate.mc`:
  ```monkeyc
  import Toybox.Lang;
  import Toybox.WatchUi;

  class RoutineTimersDelegate extends WatchUi.BehaviorDelegate {
      private var _view as RoutineTimersView;

      function initialize(view as RoutineTimersView) {
          BehaviorDelegate.initialize();
          _view = view;
      }

      // START/SELECT button
      function onSelect() as Boolean {
          var service = _view.getRoutineService();
          
          if (service.isRunning()) {
              service.pause();
          } else if (service.isPaused()) {
              service.resume();
          } else if (service.isComplete()) {
              service.stop(); // Reset
          } else {
              service.start();
          }
          
          WatchUi.requestUpdate();
          return true;
      }

      // UP button - previous step
      function onPreviousPage() as Boolean {
          var service = _view.getRoutineService();
          if (service.isRunning() || service.isPaused()) {
              service.previousStep();
              WatchUi.requestUpdate();
              return true;
          }
          return false;
      }

      // DOWN button - next step
      function onNextPage() as Boolean {
          var service = _view.getRoutineService();
          if (service.isRunning() || service.isPaused()) {
              service.nextStep();
              WatchUi.requestUpdate();
              return true;
          }
          return false;
      }

      // BACK button
      function onBack() as Boolean {
          var service = _view.getRoutineService();
          
          if (service.isRunning() || service.isPaused()) {
              service.stop();
              WatchUi.requestUpdate();
              return true;
          }
          
          WatchUi.popView(WatchUi.SLIDE_RIGHT);
          return true;
      }
  }
  ```

---

## Testing Checklist

### Routine Creation Tests

- [ ] **Test R2.1: Create Routine with Steps**
  1. Run app with TestDataFactory.createQuickTestRoutine()
  2. **Expected:** Routine has 3 steps
  3. **Expected:** Total duration is 15 seconds

- [ ] **Test R2.2: Step Order**
  1. Verify steps are in order: Step One, Step Two, Step Three
  2. **Expected:** Steps display in correct order

### Routine Execution Tests

- [ ] **Test R2.3: Start Routine**
  1. Launch app
  2. Press START
  3. **Expected:** First step begins counting down
  4. **Expected:** Step shows "Step 1 of 3"

- [ ] **Test R2.4: Auto-Advance to Next Step**
  1. Start routine
  2. Wait for first step to complete (5 seconds)
  3. **Expected:** Automatically advances to "Step Two"
  4. **Expected:** Timer resets to step 2's duration
  5. **Expected:** Step shows "Step 2 of 3"

- [ ] **Test R2.5: Complete All Steps**
  1. Start routine
  2. Wait for all 3 steps to complete
  3. **Expected:** Screen shows "COMPLETE!"
  4. **Expected:** State is ROUTINE_COMPLETE

- [ ] **Test R2.6: Pause During Routine**
  1. Start routine
  2. Press START to pause
  3. **Expected:** Timer pauses
  4. **Expected:** "PAUSED" indicator shows
  5. Press START again
  6. **Expected:** Timer resumes

- [ ] **Test R2.7: Stop Routine (BACK)**
  1. Start routine, let it run a few seconds
  2. Press BACK
  3. **Expected:** Routine stops
  4. **Expected:** Resets to first step
  5. **Expected:** Shows "Press START to begin"

### Navigation Tests

- [ ] **Test R2.8: Skip to Next Step (DOWN)**
  1. Start routine
  2. Press DOWN button
  3. **Expected:** Jumps to Step Two immediately
  4. **Expected:** Timer resets to Step Two's duration

- [ ] **Test R2.9: Go to Previous Step (UP)**
  1. Start routine
  2. Skip to Step Two
  3. Press UP button
  4. **Expected:** Returns to Step One
  5. **Expected:** Timer resets to Step One's duration

- [ ] **Test R2.10: Navigation at Boundaries**
  1. On first step, press UP
  2. **Expected:** Restarts first step
  3. Skip to last step, press DOWN
  4. **Expected:** Routine completes

- [ ] **Test R2.11: Navigation While Paused**
  1. Start routine, then pause
  2. Press UP/DOWN to navigate
  3. **Expected:** Navigation works while paused
  4. **Expected:** Remains paused on new step

### Edge Cases

- [ ] **Test R2.12: Single-Step Routine**
  1. Load TestDataFactory.createSingleStepRoutine()
  2. Start routine
  3. Wait for completion
  4. **Expected:** Shows "COMPLETE!" after single step

- [ ] **Test R2.13: Reset After Complete**
  1. Complete a routine
  2. Press START
  3. **Expected:** Routine resets to first step
  4. **Expected:** Ready to start again

- [ ] **Test R2.14: Next Step Display**
  1. On Step 1, verify "NEXT: Step Two" shows
  2. On Step 2, verify "NEXT: Step Three" shows
  3. On Step 3, verify no "NEXT" shows (last step)

---

## Success Criteria

| Criteria | Requirement |
|----------|-------------|
| Step model works | Can create, serialize, deserialize Steps |
| Routine model works | Can create Routine with multiple Steps |
| Sequential execution | Steps execute in order |
| Auto-advance | Automatically moves to next step |
| Manual navigation | UP/DOWN skip between steps |
| Pause/Resume | Works correctly mid-routine |
| Completion detection | Detects when all steps done |
| Progress tracking | Correct step count displayed |

---

## Acceptance Criteria

This milestone is **COMPLETE** when:

1. ✅ All implementation checkboxes are checked
2. ✅ All tests R2.1 through R2.14 pass
3. ✅ A 3-step routine runs to completion with auto-advance
4. ✅ Manual step navigation works in both directions
5. ✅ Pause/resume works at any point in the routine

---

## Files Created/Modified in This Milestone

```
routine-timers/
├── source/
│   ├── RoutineTimersView.mc        ✓ Modified
│   ├── RoutineTimersDelegate.mc    ✓ Modified
│   ├── models/
│   │   ├── Step.mc                 ✓ Created
│   │   └── Routine.mc              ✓ Created
│   ├── services/
│   │   └── RoutineService.mc       ✓ Created
│   └── utils/
│       └── TestDataFactory.mc      ✓ Created
```

---

## Next Milestone

Once all criteria are met, proceed to **[M3: Timer User Interface](./M3_timer_ui.md)**
