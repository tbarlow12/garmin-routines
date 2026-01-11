# Milestone 4: Routine Storage & Selection

**Estimated Duration:** 2-3 days  
**Dependencies:** M3 (Timer UI)  
**Deliverable:** Persistent storage of routines and a menu to select between multiple routines

---

## Goal

Implement persistent storage for routines using Garmin's Application.Storage API and create a menu interface for users to select which routine to run. Routines must persist across app restarts and device reboots.

---

## Implementation Checklist

### Storage Service

- [ ] Create `source/services/StorageService.mc`:
  ```monkeyc
  import Toybox.Application;
  import Toybox.Application.Storage;
  import Toybox.Lang;

  module StorageService {
      // Storage keys
      const KEY_ROUTINES = "routines";
      const KEY_ACTIVE_ROUTINE_ID = "activeRoutineId";
      const KEY_ACTIVE_STEP_INDEX = "activeStepIndex";
      const KEY_REMAINING_TIME = "remainingTime";
      const KEY_STATE = "state";
      const KEY_LAST_SELECTED_ROUTINE_ID = "lastSelectedRoutineId";

      // Save all routines to storage
      function saveRoutines(routines as Array<Routine>) as Void {
          var routinesData = [] as Array<Dictionary>;
          
          for (var i = 0; i < routines.size(); i++) {
              routinesData.add(routines[i].toDict());
          }
          
          Storage.setValue(KEY_ROUTINES, routinesData);
      }

      // Load all routines from storage
      function loadRoutines() as Array<Routine> {
          var routinesData = Storage.getValue(KEY_ROUTINES);
          var routines = [] as Array<Routine>;
          
          if (routinesData == null) {
              return routines;
          }
          
          var dataArray = routinesData as Array<Dictionary>;
          for (var i = 0; i < dataArray.size(); i++) {
              try {
                  routines.add(Routine.fromDict(dataArray[i]));
              } catch (e) {
                  // Skip corrupted routine data
                  System.println("Error loading routine: " + e.getErrorMessage());
              }
          }
          
          return routines;
      }

      // Save a single routine (add or update)
      function saveRoutine(routine as Routine) as Void {
          var routines = loadRoutines();
          var found = false;
          
          // Update existing
          for (var i = 0; i < routines.size(); i++) {
              if (routines[i].id.equals(routine.id)) {
                  routines[i] = routine;
                  found = true;
                  break;
              }
          }
          
          // Add new
          if (!found) {
              routines.add(routine);
          }
          
          saveRoutines(routines);
      }

      // Delete a routine by ID
      function deleteRoutine(routineId as String) as Void {
          var routines = loadRoutines();
          
          for (var i = 0; i < routines.size(); i++) {
              if (routines[i].id.equals(routineId)) {
                  routines.remove(routines[i]);
                  break;
              }
          }
          
          saveRoutines(routines);
      }

      // Get a routine by ID
      function getRoutine(routineId as String) as Routine? {
          var routines = loadRoutines();
          
          for (var i = 0; i < routines.size(); i++) {
              if (routines[i].id.equals(routineId)) {
                  return routines[i];
              }
          }
          
          return null;
      }

      // Save active routine state (for pause/resume across app restarts)
      function saveActiveState(
          routineId as String?,
          stepIndex as Number,
          remainingTime as Number,
          state as String
      ) as Void {
          Storage.setValue(KEY_ACTIVE_ROUTINE_ID, routineId);
          Storage.setValue(KEY_ACTIVE_STEP_INDEX, stepIndex);
          Storage.setValue(KEY_REMAINING_TIME, remainingTime);
          Storage.setValue(KEY_STATE, state);
      }

      // Load active routine state
      function loadActiveState() as Dictionary? {
          var routineId = Storage.getValue(KEY_ACTIVE_ROUTINE_ID);
          
          if (routineId == null) {
              return null;
          }
          
          return {
              "routineId" => routineId,
              "stepIndex" => Storage.getValue(KEY_ACTIVE_STEP_INDEX),
              "remainingTime" => Storage.getValue(KEY_REMAINING_TIME),
              "state" => Storage.getValue(KEY_STATE)
          };
      }

      // Clear active state
      function clearActiveState() as Void {
          Storage.deleteValue(KEY_ACTIVE_ROUTINE_ID);
          Storage.deleteValue(KEY_ACTIVE_STEP_INDEX);
          Storage.deleteValue(KEY_REMAINING_TIME);
          Storage.deleteValue(KEY_STATE);
      }

      // Save last selected routine ID (for quick access)
      function saveLastSelectedRoutineId(routineId as String) as Void {
          Storage.setValue(KEY_LAST_SELECTED_ROUTINE_ID, routineId);
      }

      // Get last selected routine ID
      function getLastSelectedRoutineId() as String? {
          return Storage.getValue(KEY_LAST_SELECTED_ROUTINE_ID) as String?;
      }

      // Check if storage has any routines
      function hasRoutines() as Boolean {
          var routines = loadRoutines();
          return routines.size() > 0;
      }

      // Get routine count
      function getRoutineCount() as Number {
          var routines = loadRoutines();
          return routines.size();
      }

      // Clear all data (for testing/reset)
      function clearAllData() as Void {
          Storage.clearValues();
      }

      // Initialize with sample data if empty
      function initializeWithSampleData() as Void {
          if (!hasRoutines()) {
              saveRoutine(TestDataFactory.createMorningRoutine());
              saveRoutine(TestDataFactory.createQuickTestRoutine());
          }
      }
  }
  ```

### Routine Selection Menu

- [ ] Create `source/RoutineTimersMenuView.mc`:
  ```monkeyc
  import Toybox.Graphics;
  import Toybox.WatchUi;
  import Toybox.Lang;

  class RoutineTimersMenuView extends WatchUi.Menu2 {
      function initialize() {
          Menu2.initialize({:title => "Select Routine"});
          loadRoutineItems();
      }

      function loadRoutineItems() as Void {
          var routines = StorageService.loadRoutines();
          
          if (routines.size() == 0) {
              // Add placeholder item
              addItem(new WatchUi.MenuItem(
                  "No Routines",
                  "Configure in Garmin Connect",
                  :noRoutines,
                  {}
              ));
              return;
          }
          
          for (var i = 0; i < routines.size(); i++) {
              var routine = routines[i];
              var subtitle = routine.getStepCount() + " steps • " + 
                            TimeFormatter.formatSmart(routine.getTotalDuration());
              
              addItem(new WatchUi.MenuItem(
                  routine.name,
                  subtitle,
                  routine.id,
                  {}
              ));
          }
      }
  }

  class RoutineTimersMenuDelegate extends WatchUi.Menu2InputDelegate {
      function initialize() {
          Menu2InputDelegate.initialize();
      }

      function onSelect(item as WatchUi.MenuItem) as Void {
          var itemId = item.getId();
          
          if (itemId == :noRoutines) {
              // Just go back, nothing to select
              WatchUi.popView(WatchUi.SLIDE_RIGHT);
              return;
          }
          
          // Get the routine ID (stored as item ID)
          var routineId = itemId as String;
          var routine = StorageService.getRoutine(routineId);
          
          if (routine != null) {
              // Save as last selected
              StorageService.saveLastSelectedRoutineId(routineId);
              
              // Launch timer view with this routine
              var timerView = new RoutineTimersView();
              timerView.getRoutineService().loadRoutine(routine);
              
              WatchUi.switchToView(
                  timerView,
                  new RoutineTimersDelegate(timerView),
                  WatchUi.SLIDE_LEFT
              );
          }
      }

      function onBack() as Void {
          WatchUi.popView(WatchUi.SLIDE_RIGHT);
      }
  }
  ```

### Update App Entry Point

- [ ] Update `RoutineTimersApp.mc` to show menu or auto-load:
  ```monkeyc
  import Toybox.Application;
  import Toybox.Lang;
  import Toybox.WatchUi;

  class RoutineTimersApp extends Application.AppBase {
      function initialize() {
          AppBase.initialize();
      }

      function onStart(state as Dictionary?) as Void {
          // Initialize sample data if first run
          StorageService.initializeWithSampleData();
      }

      function onStop(state as Dictionary?) as Void {
      }

      function getInitialView() as [Views] or [Views, InputDelegates] {
          var routines = StorageService.loadRoutines();
          
          // If only one routine, go directly to timer
          if (routines.size() == 1) {
              var view = new RoutineTimersView();
              view.getRoutineService().loadRoutine(routines[0]);
              return [view, new RoutineTimersDelegate(view)];
          }
          
          // If last selected routine exists, could auto-load it
          // For now, always show menu if multiple routines
          
          // Show routine selection menu
          return [
              new RoutineTimersMenuView(),
              new RoutineTimersMenuDelegate()
          ];
      }
  }
  ```

### Glance View (Widget Preview)

- [ ] Create `source/RoutineTimersGlanceView.mc`:
  ```monkeyc
  import Toybox.Graphics;
  import Toybox.WatchUi;
  import Toybox.Lang;
  import Toybox.Time;
  import Toybox.Time.Gregorian;

  class RoutineTimersGlanceView extends WatchUi.GlanceView {
      function initialize() {
          GlanceView.initialize();
      }

      function onUpdate(dc as Dc) as Void {
          dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
          dc.clear();

          var routines = StorageService.loadRoutines();
          var y = 10;

          // App title
          dc.drawText(0, y, Graphics.FONT_GLANCE, "Routine Timers", Graphics.TEXT_JUSTIFY_LEFT);
          y += 25;

          if (routines.size() == 0) {
              dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
              dc.drawText(0, y, Graphics.FONT_GLANCE_NUMBER, "No routines", Graphics.TEXT_JUSTIFY_LEFT);
              return;
          }

          // Show next scheduled routine or last used
          var lastRoutineId = StorageService.getLastSelectedRoutineId();
          var displayRoutine = null as Routine?;
          
          if (lastRoutineId != null) {
              displayRoutine = StorageService.getRoutine(lastRoutineId);
          }
          
          if (displayRoutine == null && routines.size() > 0) {
              displayRoutine = routines[0];
          }

          if (displayRoutine != null) {
              dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
              dc.drawText(0, y, Graphics.FONT_GLANCE_NUMBER, displayRoutine.name, Graphics.TEXT_JUSTIFY_LEFT);
              y += 20;
              
              dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
              var info = displayRoutine.getStepCount() + " steps • " + 
                        TimeFormatter.formatSmart(displayRoutine.getTotalDuration());
              dc.drawText(0, y, Graphics.FONT_GLANCE, info, Graphics.TEXT_JUSTIFY_LEFT);
          }
      }
  }
  ```

- [ ] Update `manifest.xml` to include glance view:
  ```xml
  <iq:application ...>
      ...
      <iq:glance-view entry="RoutineTimersGlanceView" />
  </iq:application>
  ```

### Update RoutineTimersView to Accept Routine

- [ ] Modify `RoutineTimersView.mc` constructor:
  ```monkeyc
  function initialize() {
      View.initialize();
      _routineService = new RoutineService();
      _pulseState = false;
      
      // Set up callbacks (routine loaded separately now)
      _routineService.setOnTickCallback(method(:onTick));
      _routineService.setOnStepChangeCallback(method(:onStepChange));
      _routineService.setOnRoutineCompleteCallback(method(:onRoutineComplete));
      
      // Don't auto-load test routine anymore - it's loaded from menu selection
  }
  ```

### State Persistence on Exit

- [ ] Update `RoutineTimersDelegate.mc` to save state:
  ```monkeyc
  function onBack() as Boolean {
      var service = _view.getRoutineService();
      var routine = service.getRoutine();
      
      if (service.isRunning() || service.isPaused()) {
          // Save current state for resume
          if (routine != null) {
              var stateStr = service.isPaused() ? "PAUSED" : "RUNNING";
              StorageService.saveActiveState(
                  routine.id,
                  service.getCurrentStepIndex(),
                  service.getRemainingSeconds(),
                  stateStr
              );
          }
          
          // Stop timer but preserve saved state
          service.pause();
      } else if (service.isComplete() || service.isIdle()) {
          // Clear any saved state
          StorageService.clearActiveState();
      }
      
      WatchUi.popView(WatchUi.SLIDE_RIGHT);
      return true;
  }
  ```

---

## Testing Checklist

### Storage Tests

- [ ] **Test S4.1: Save and Load Routine**
  1. Create a routine programmatically
  2. Call StorageService.saveRoutine()
  3. Restart app (or clear view and reload)
  4. Call StorageService.loadRoutines()
  5. **Expected:** Routine is retrieved with all data intact

- [ ] **Test S4.2: Multiple Routines**
  1. Save 3 different routines
  2. Reload from storage
  3. **Expected:** All 3 routines present
  4. **Expected:** Each has correct name, steps, durations

- [ ] **Test S4.3: Update Existing Routine**
  1. Save a routine
  2. Modify its name
  3. Save again (same ID)
  4. Reload
  5. **Expected:** Only one copy exists with new name

- [ ] **Test S4.4: Delete Routine**
  1. Save 2 routines
  2. Delete one by ID
  3. Reload
  4. **Expected:** Only 1 routine remains

- [ ] **Test S4.5: Persistence Across App Restart**
  1. Save a routine
  2. Close app completely (exit widget)
  3. Relaunch app
  4. **Expected:** Routine still present

- [ ] **Test S4.6: Empty Storage**
  1. Clear all data
  2. Call loadRoutines()
  3. **Expected:** Returns empty array, no crash

### Menu Tests

- [ ] **Test S4.7: Menu Displays Routines**
  1. Save 3 routines with distinct names
  2. Launch app
  3. **Expected:** Menu shows all 3 routines
  4. **Expected:** Each shows name, step count, total time

- [ ] **Test S4.8: Select Routine from Menu**
  1. Open menu
  2. Select a routine
  3. **Expected:** Timer view opens
  4. **Expected:** Correct routine is loaded

- [ ] **Test S4.9: Empty Menu**
  1. Clear all routines
  2. Launch app
  3. **Expected:** Shows "No Routines" message
  4. **Expected:** Subtitle mentions "Configure in Garmin Connect"

- [ ] **Test S4.10: Back from Menu**
  1. Open menu
  2. Press BACK
  3. **Expected:** Returns to widget carousel

- [ ] **Test S4.11: Single Routine Auto-Load**
  1. Ensure only 1 routine exists
  2. Launch app
  3. **Expected:** Goes directly to timer (no menu)
  4. **Expected:** The single routine is loaded

### Glance View Tests

- [ ] **Test S4.12: Glance Shows Routine Info**
  1. Add widget to glance carousel (on device or simulator)
  2. Scroll to widget glance
  3. **Expected:** Shows "Routine Timers" title
  4. **Expected:** Shows routine name
  5. **Expected:** Shows step count and duration

- [ ] **Test S4.13: Glance with No Routines**
  1. Clear all routines
  2. View glance
  3. **Expected:** Shows "No routines" message

### State Persistence Tests

- [ ] **Test S4.14: Save Running State on Exit**
  1. Start a routine
  2. Wait a few seconds
  3. Press BACK to exit
  4. **Expected:** State saved (can verify via debug logging)

- [ ] **Test S4.15: Resume Saved State**
  1. Start routine, let it run
  2. Exit with BACK
  3. Relaunch app, select same routine
  4. **Expected:** (For now) Routine starts fresh
  5. **(Future enhancement)** Could prompt to resume

### Edge Cases

- [ ] **Test S4.16: Corrupted Data Handling**
  1. Manually corrupt storage data (if possible in simulator)
  2. Launch app
  3. **Expected:** App handles gracefully, shows empty or partial data

- [ ] **Test S4.17: Storage Limits**
  1. Create 10 routines with 20 steps each
  2. Save all
  3. Reload
  4. **Expected:** All data loads correctly

- [ ] **Test S4.18: Special Characters in Names**
  1. Create routine with name: "Morning's Routine & More"
  2. Create step with emoji in name (if supported)
  3. Save and reload
  4. **Expected:** Names preserved correctly

---

## Success Criteria

| Criteria | Requirement |
|----------|-------------|
| Routines persist | Saved routines survive app restart |
| Serialization works | Routine ↔ Dictionary conversion is lossless |
| Menu displays | All saved routines show in menu |
| Selection works | Tapping menu item loads correct routine |
| Glance works | Widget preview shows routine info |
| Single-routine shortcut | Auto-loads if only one routine |
| State saves on exit | Running state preserved when exiting |

---

## Acceptance Criteria

This milestone is **COMPLETE** when:

1. ✅ All implementation checkboxes are checked
2. ✅ All tests S4.1 through S4.18 pass
3. ✅ Routines persist across app restart
4. ✅ Menu correctly displays and allows selection of routines
5. ✅ Glance view shows useful preview information
6. ✅ Storage handles edge cases without crashing

---

## Storage Schema Reference

```
Application.Storage keys:
├── "routines"              → Array of serialized Routine dictionaries
├── "activeRoutineId"       → String (ID of running routine)
├── "activeStepIndex"       → Number (current step index)
├── "remainingTime"         → Number (seconds remaining in step)
├── "state"                 → String ("IDLE", "RUNNING", "PAUSED")
└── "lastSelectedRoutineId" → String (for quick access)
```

---

## Files Created/Modified in This Milestone

```
routine-timers/
├── source/
│   ├── RoutineTimersApp.mc          ✓ Modified
│   ├── RoutineTimersView.mc         ✓ Modified
│   ├── RoutineTimersDelegate.mc     ✓ Modified
│   ├── RoutineTimersMenuView.mc     ✓ Created
│   ├── RoutineTimersGlanceView.mc   ✓ Created
│   └── services/
│       └── StorageService.mc        ✓ Created
├── manifest.xml                     ✓ Modified (glance-view)
```

---

## Next Milestone

Once all criteria are met, proceed to **[M5: Alerts & Haptic Feedback](./M5_alerts_feedback.md)**
