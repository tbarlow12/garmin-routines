# Milestone 6: Background Service & Scheduling

**Estimated Duration:** 3-4 days  
**Dependencies:** M5 (Alerts & Feedback)  
**Deliverable:** Ability to schedule routines to start at specific times via background temporal events

---

## Goal

Implement the background service that enables scheduled routine starts. Users can configure routines to begin at specific times (e.g., 6:00 AM on weekdays), and the app will alert them when it's time to start.

---

## Implementation Checklist

### Background Service Delegate

- [ ] Create `source/RoutineTimersBackground.mc`:
  ```monkeyc
  import Toybox.Application;
  import Toybox.Background;
  import Toybox.Lang;
  import Toybox.System;
  import Toybox.Time;
  import Toybox.Time.Gregorian;

  (:background)
  class RoutineTimersBackground extends System.ServiceDelegate {
      function initialize() {
          ServiceDelegate.initialize();
      }

      // Called when a temporal event fires
      function onTemporalEvent() as Void {
          System.println("Background: Temporal event fired");
          
          // Find any routines scheduled for now
          var pendingRoutine = findScheduledRoutineForNow();
          
          if (pendingRoutine != null) {
              // Store the routine ID to launch when app opens
              Application.Storage.setValue("pendingRoutineId", pendingRoutine.id);
              Application.Storage.setValue("pendingRoutineTriggered", true);
              
              System.println("Background: Scheduled routine found - " + pendingRoutine.name);
              
              // Exit and pass data to foreground
              Background.exit(pendingRoutine.id);
          } else {
              // No routine scheduled, just exit
              Background.exit(null);
          }
      }

      // Find a routine that should start now
      private function findScheduledRoutineForNow() as Routine? {
          var routines = loadRoutinesInBackground();
          var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
          var currentMinutes = now.hour * 60 + now.min;
          var currentDayOfWeek = now.day_of_week; // 1=Sun, 2=Mon, ..., 7=Sat
          
          // Convert to 0-indexed (0=Sun, 1=Mon, ..., 6=Sat)
          var dayIndex = currentDayOfWeek - 1;
          
          for (var i = 0; i < routines.size(); i++) {
              var routine = routines[i];
              
              if (routine.triggerType != TRIGGER_SCHEDULED) {
                  continue;
              }
              
              if (routine.scheduledTime == null) {
                  continue;
              }
              
              // Convert scheduled time from seconds to minutes for comparison
              var scheduledMinutes = routine.scheduledTime / 60;
              
              // Check if time matches (within 5 minute window)
              var timeDiff = (currentMinutes - scheduledMinutes).abs();
              if (timeDiff > 5) {
                  continue;
              }
              
              // Check if day matches
              if (routine.scheduledDays != null) {
                  var dayMatches = false;
                  for (var j = 0; j < routine.scheduledDays.size(); j++) {
                      if (routine.scheduledDays[j] == dayIndex) {
                          dayMatches = true;
                          break;
                      }
                  }
                  if (!dayMatches) {
                      continue;
                  }
              }
              
              // Found a matching routine
              return routine;
          }
          
          return null;
      }

      // Lightweight routine loading for background (limited memory)
      private function loadRoutinesInBackground() as Array<Routine> {
          var routinesData = Application.Storage.getValue("routines");
          var routines = [] as Array<Routine>;
          
          if (routinesData == null) {
              return routines;
          }
          
          var dataArray = routinesData as Array;
          for (var i = 0; i < dataArray.size(); i++) {
              try {
                  routines.add(Routine.fromDict(dataArray[i]));
              } catch (e) {
                  // Skip corrupted data in background
              }
          }
          
          return routines;
      }
  }
  ```

### Background Registration

- [ ] Create `source/services/ScheduleService.mc`:
  ```monkeyc
  import Toybox.Application;
  import Toybox.Background;
  import Toybox.Lang;
  import Toybox.System;
  import Toybox.Time;
  import Toybox.Time.Gregorian;

  module ScheduleService {
      // Minimum interval between background checks (5 minutes in seconds)
      const MIN_INTERVAL = 300;
      
      // Register background temporal events for scheduled routines
      function registerScheduledEvents() as Void {
          if (!(Background has :registerForTemporalEvent)) {
              System.println("Background temporal events not supported");
              return;
          }
          
          // Find next scheduled routine time
          var nextEventTime = findNextScheduledTime();
          
          if (nextEventTime != null) {
              try {
                  Background.registerForTemporalEvent(nextEventTime);
                  System.println("Registered temporal event for: " + nextEventTime.value());
              } catch (e) {
                  System.println("Failed to register temporal event: " + e.getErrorMessage());
              }
          } else {
              System.println("No scheduled routines found");
              // Cancel any existing registration
              try {
                  Background.deleteTemporalEvent();
              } catch (e) {
                  // Ignore if nothing to delete
              }
          }
      }

      // Find the next time a scheduled routine should run
      function findNextScheduledTime() as Time.Moment? {
          var routines = StorageService.loadRoutines();
          var now = Time.now();
          var closestTime = null as Time.Moment?;
          
          for (var i = 0; i < routines.size(); i++) {
              var routine = routines[i];
              
              if (routine.triggerType != TRIGGER_SCHEDULED) {
                  continue;
              }
              
              if (routine.scheduledTime == null) {
                  continue;
              }
              
              var nextOccurrence = calculateNextOccurrence(routine, now);
              
              if (nextOccurrence != null) {
                  if (closestTime == null || nextOccurrence.lessThan(closestTime)) {
                      closestTime = nextOccurrence;
                  }
              }
          }
          
          return closestTime;
      }

      // Calculate next occurrence of a scheduled routine
      private function calculateNextOccurrence(routine as Routine, now as Time.Moment) as Time.Moment? {
          if (routine.scheduledTime == null) {
              return null;
          }
          
          var nowInfo = Gregorian.info(now, Time.FORMAT_SHORT);
          var scheduledSeconds = routine.scheduledTime;
          
          // Convert scheduled time to hours and minutes
          var scheduledHour = scheduledSeconds / 3600;
          var scheduledMin = (scheduledSeconds % 3600) / 60;
          
          // Check each of the next 7 days
          for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
              var checkMoment = now.add(new Time.Duration(dayOffset * 86400));
              var checkInfo = Gregorian.info(checkMoment, Time.FORMAT_SHORT);
              var dayIndex = checkInfo.day_of_week - 1; // 0=Sun, 6=Sat
              
              // Check if this day is scheduled
              if (routine.scheduledDays != null) {
                  var dayMatches = false;
                  for (var j = 0; j < routine.scheduledDays.size(); j++) {
                      if (routine.scheduledDays[j] == dayIndex) {
                          dayMatches = true;
                          break;
                      }
                  }
                  if (!dayMatches) {
                      continue;
                  }
              }
              
              // Build the target moment
              var targetOptions = {
                  :year => checkInfo.year,
                  :month => checkInfo.month,
                  :day => checkInfo.day,
                  :hour => scheduledHour,
                  :minute => scheduledMin,
                  :second => 0
              };
              var targetMoment = Gregorian.moment(targetOptions);
              
              // If it's today, make sure the time is in the future
              if (dayOffset == 0 && targetMoment.lessThan(now)) {
                  continue;
              }
              
              return targetMoment;
          }
          
          return null;
      }

      // Cancel all scheduled events
      function cancelScheduledEvents() as Void {
          if (Background has :deleteTemporalEvent) {
              try {
                  Background.deleteTemporalEvent();
                  System.println("Cancelled temporal events");
              } catch (e) {
                  // Ignore
              }
          }
      }

      // Check if there's a pending routine from background
      function checkPendingRoutine() as String? {
          var pending = Application.Storage.getValue("pendingRoutineId");
          var triggered = Application.Storage.getValue("pendingRoutineTriggered");
          
          if (pending != null && triggered == true) {
              // Clear the pending state
              Application.Storage.deleteValue("pendingRoutineId");
              Application.Storage.deleteValue("pendingRoutineTriggered");
              return pending as String;
          }
          
          return null;
      }

      // Get time until next scheduled routine (for display)
      function getTimeUntilNextScheduled() as Number? {
          var nextTime = findNextScheduledTime();
          
          if (nextTime == null) {
              return null;
          }
          
          var now = Time.now();
          return nextTime.subtract(now).value();
      }

      // Format scheduled time for display
      function formatScheduledTime(secondsFromMidnight as Number) as String {
          var hours = secondsFromMidnight / 3600;
          var minutes = (secondsFromMidnight % 3600) / 60;
          
          // 12-hour format
          var period = hours >= 12 ? "PM" : "AM";
          var displayHour = hours % 12;
          if (displayHour == 0) {
              displayHour = 12;
          }
          
          return displayHour.format("%d") + ":" + minutes.format("%02d") + " " + period;
      }

      // Format days array for display
      function formatScheduledDays(days as Array<Number>?) as String {
          if (days == null || days.size() == 0) {
              return "Every day";
          }
          
          if (days.size() == 7) {
              return "Every day";
          }
          
          // Check for weekdays (Mon-Fri = 1,2,3,4,5)
          if (days.size() == 5) {
              var isWeekdays = true;
              for (var i = 1; i <= 5; i++) {
                  if (days.indexOf(i) < 0) {
                      isWeekdays = false;
                      break;
                  }
              }
              if (isWeekdays) {
                  return "Weekdays";
              }
          }
          
          // Check for weekends (Sat-Sun = 0,6)
          if (days.size() == 2 && days.indexOf(0) >= 0 && days.indexOf(6) >= 0) {
              return "Weekends";
          }
          
          // Otherwise list abbreviated days
          var dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
          var result = "";
          for (var i = 0; i < days.size(); i++) {
              if (result.length() > 0) {
                  result += ", ";
              }
              result += dayNames[days[i]];
          }
          
          return result;
      }
  }
  ```

### Update Manifest for Background

- [ ] Update `manifest.xml`:
  ```xml
  <?xml version="1.0"?>
  <iq:manifest xmlns:iq="http://www.garmin.com/xml/connectiq" version="3">
      <iq:application id="routine-timers" type="widget" 
                      entry="RoutineTimersApp" 
                      launcherIcon="@Drawables.LauncherIcon"
                      name="@Strings.AppName">
          
          <iq:products>
              <iq:product id="fenix7s"/>
              <iq:product id="fenix7"/>
              <iq:product id="fenix7x"/>
              <iq:product id="fenix8"/>
          </iq:products>
          
          <iq:permissions>
              <iq:uses-permission id="Background"/>
          </iq:permissions>
          
          <iq:languages>
              <iq:language>eng</iq:language>
          </iq:languages>
          
          <!-- Background service delegate -->
          <iq:background-delegate entry="RoutineTimersBackground"/>
          
          <iq:barrels/>
      </iq:application>
  </iq:manifest>
  ```

### Update App to Handle Background Wake

- [ ] Update `RoutineTimersApp.mc`:
  ```monkeyc
  import Toybox.Application;
  import Toybox.Lang;
  import Toybox.WatchUi;
  import Toybox.Background;

  class RoutineTimersApp extends Application.AppBase {
      function initialize() {
          AppBase.initialize();
      }

      function onStart(state as Dictionary?) as Void {
          // Initialize sample data if first run
          StorageService.initializeWithSampleData();
          
          // Register for scheduled events
          ScheduleService.registerScheduledEvents();
      }

      function onStop(state as Dictionary?) as Void {
          // Re-register events when app closes (to ensure they persist)
          ScheduleService.registerScheduledEvents();
      }

      // Called when background service returns data
      function onBackgroundData(data) as Void {
          System.println("Received background data: " + data);
          
          if (data != null && data instanceof String) {
              var routineId = data as String;
              // Store for next launch
              Application.Storage.setValue("pendingRoutineId", routineId);
              Application.Storage.setValue("pendingRoutineTriggered", true);
          }
          
          // Re-register for next event
          ScheduleService.registerScheduledEvents();
      }

      function getInitialView() as [Views] or [Views, InputDelegates] {
          // Check for pending routine from scheduled trigger
          var pendingRoutineId = ScheduleService.checkPendingRoutine();
          
          if (pendingRoutineId != null) {
              var routine = StorageService.getRoutine(pendingRoutineId);
              if (routine != null) {
                  // Launch directly into the scheduled routine
                  var view = new RoutineTimersView();
                  view.getRoutineService().loadRoutine(routine);
                  
                  // Alert user that scheduled routine is starting
                  AlertService.alertRoutineStart();
                  
                  return [view, new RoutineTimersDelegate(view)];
              }
          }
          
          // Normal startup flow
          var routines = StorageService.loadRoutines();
          
          if (routines.size() == 1) {
              var view = new RoutineTimersView();
              view.getRoutineService().loadRoutine(routines[0]);
              return [view, new RoutineTimersDelegate(view)];
          }
          
          return [
              new RoutineTimersMenuView(),
              new RoutineTimersMenuDelegate()
          ];
      }

      // Return the service delegate for background execution
      function getServiceDelegate() as [System.ServiceDelegate] {
          return [new RoutineTimersBackground()];
      }
  }
  ```

### Schedule Configuration UI

- [ ] Create `source/ScheduleConfigView.mc` (simple display for now, full config via phone):
  ```monkeyc
  import Toybox.Graphics;
  import Toybox.WatchUi;
  import Toybox.Lang;

  class ScheduleConfigView extends WatchUi.View {
      private var _routine as Routine;

      function initialize(routine as Routine) {
          View.initialize();
          _routine = routine;
      }

      function onUpdate(dc as Dc) as Void {
          dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
          dc.clear();

          var centerX = dc.getWidth() / 2;
          var y = 30;

          // Title
          dc.drawText(centerX, y, Graphics.FONT_SMALL,
              "Schedule", Graphics.TEXT_JUSTIFY_CENTER);
          y += 30;

          // Routine name
          dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
          dc.drawText(centerX, y, Graphics.FONT_XTINY,
              _routine.name, Graphics.TEXT_JUSTIFY_CENTER);
          y += 25;

          dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

          if (_routine.triggerType == TRIGGER_SCHEDULED && _routine.scheduledTime != null) {
              // Show scheduled time
              var timeStr = ScheduleService.formatScheduledTime(_routine.scheduledTime);
              dc.drawText(centerX, y, Graphics.FONT_MEDIUM,
                  timeStr, Graphics.TEXT_JUSTIFY_CENTER);
              y += 35;

              // Show days
              var daysStr = ScheduleService.formatScheduledDays(_routine.scheduledDays);
              dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
              dc.drawText(centerX, y, Graphics.FONT_SMALL,
                  daysStr, Graphics.TEXT_JUSTIFY_CENTER);
          } else {
              dc.drawText(centerX, y, Graphics.FONT_SMALL,
                  "Not Scheduled", Graphics.TEXT_JUSTIFY_CENTER);
              y += 30;
              
              dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
              dc.drawText(centerX, y, Graphics.FONT_XTINY,
                  "Configure in", Graphics.TEXT_JUSTIFY_CENTER);
              y += 18;
              dc.drawText(centerX, y, Graphics.FONT_XTINY,
                  "Garmin Connect Mobile", Graphics.TEXT_JUSTIFY_CENTER);
          }

          // Next occurrence
          var nextTime = ScheduleService.findNextScheduledTime();
          if (nextTime != null) {
              var secondsUntil = ScheduleService.getTimeUntilNextScheduled();
              if (secondsUntil != null) {
                  y = dc.getHeight() - 50;
                  dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                  dc.drawText(centerX, y, Graphics.FONT_XTINY,
                      "Next in: " + formatDuration(secondsUntil),
                      Graphics.TEXT_JUSTIFY_CENTER);
              }
          }
      }

      private function formatDuration(seconds as Number) as String {
          if (seconds < 3600) {
              return (seconds / 60) + " min";
          } else if (seconds < 86400) {
              return (seconds / 3600) + " hr";
          } else {
              return (seconds / 86400) + " days";
          }
      }
  }

  class ScheduleConfigDelegate extends WatchUi.BehaviorDelegate {
      function initialize() {
          BehaviorDelegate.initialize();
      }

      function onBack() as Boolean {
          WatchUi.popView(WatchUi.SLIDE_RIGHT);
          return true;
      }
  }
  ```

### Update Menu to Show Schedule Option

- [ ] Add schedule info to menu items in `RoutineTimersMenuView.mc`:
  ```monkeyc
  function loadRoutineItems() as Void {
      var routines = StorageService.loadRoutines();
      
      if (routines.size() == 0) {
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
          
          // Add schedule indicator if scheduled
          if (routine.triggerType == TRIGGER_SCHEDULED && routine.scheduledTime != null) {
              subtitle += " • ⏰ " + ScheduleService.formatScheduledTime(routine.scheduledTime);
          }
          
          addItem(new WatchUi.MenuItem(
              routine.name,
              subtitle,
              routine.id,
              {}
          ));
      }
  }
  ```

### Update TestDataFactory with Scheduled Routine

- [ ] Add scheduled routine example in `TestDataFactory.mc`:
  ```monkeyc
  // Add to TestDataFactory module:

  // Create a scheduled morning routine (6:00 AM weekdays)
  function createScheduledMorningRoutine() as Routine {
      var routine = new Routine({
          :id => "scheduled_morning",
          :name => "Morning Routine",
          :triggerType => TRIGGER_SCHEDULED,
          :scheduledTime => 6 * 3600,  // 6:00 AM in seconds from midnight
          :scheduledDays => [1, 2, 3, 4, 5]  // Mon-Fri
      });

      routine.addStep(new Step({
          :name => "Scripture Study",
          :duration => 20 * 60
      }));

      routine.addStep(new Step({
          :name => "Tidy up office",
          :duration => 5 * 60
      }));

      routine.addStep(new Step({
          :name => "Fill water bottle",
          :duration => 2 * 60
      }));

      return routine;
  }
  ```

---

## Testing Checklist

### Background Service Tests

- [ ] **Test B6.1: Background Delegate Registration**
  1. Build and deploy app
  2. Check manifest includes `<iq:background-delegate>`
  3. **Expected:** App compiles without errors

- [ ] **Test B6.2: Temporal Event Registration**
  1. Create scheduled routine (6:00 AM)
  2. Launch app, then exit
  3. Check simulator's Background menu
  4. **Expected:** Temporal event is registered

- [ ] **Test B6.3: Simulate Temporal Event**
  1. In simulator: Simulation → Temporal Event
  2. Trigger the event
  3. **Expected:** Background delegate runs
  4. **Expected:** Pending routine stored if time matches

### Schedule Calculation Tests

- [ ] **Test B6.4: Next Occurrence - Later Today**
  1. Create routine scheduled for 2 hours from now
  2. Call ScheduleService.findNextScheduledTime()
  3. **Expected:** Returns time today

- [ ] **Test B6.5: Next Occurrence - Tomorrow**
  1. Create routine scheduled for 2 hours ago today
  2. Call findNextScheduledTime()
  3. **Expected:** Returns tomorrow's time (or next scheduled day)

- [ ] **Test B6.6: Weekday Filter**
  1. Create routine for weekdays only
  2. Test on Saturday
  3. **Expected:** Next occurrence is Monday

- [ ] **Test B6.7: Weekend Filter**
  1. Create routine for weekends only
  2. Test on Wednesday
  3. **Expected:** Next occurrence is Saturday

### Pending Routine Tests

- [ ] **Test B6.8: Pending Routine Launch**
  1. Manually set pendingRoutineId in storage
  2. Set pendingRoutineTriggered to true
  3. Launch app
  4. **Expected:** Goes directly to timer view
  5. **Expected:** Correct routine is loaded

- [ ] **Test B6.9: Pending State Cleared**
  1. After pending routine launches
  2. Check storage
  3. **Expected:** pendingRoutineId is cleared
  4. **Expected:** Won't re-trigger on next launch

- [ ] **Test B6.10: Alert on Scheduled Start**
  1. Launch via scheduled trigger
  2. **Expected:** Routine start alert (vibration) fires

### Schedule Display Tests

- [ ] **Test B6.11: Format Time - Morning**
  1. formatScheduledTime(6 * 3600) // 6 AM
  2. **Expected:** "6:00 AM"

- [ ] **Test B6.12: Format Time - Afternoon**
  1. formatScheduledTime(14 * 3600 + 30 * 60) // 2:30 PM
  2. **Expected:** "2:30 PM"

- [ ] **Test B6.13: Format Days - Weekdays**
  1. formatScheduledDays([1,2,3,4,5])
  2. **Expected:** "Weekdays"

- [ ] **Test B6.14: Format Days - Weekends**
  1. formatScheduledDays([0,6])
  2. **Expected:** "Weekends"

- [ ] **Test B6.15: Format Days - Every Day**
  1. formatScheduledDays([0,1,2,3,4,5,6])
  2. **Expected:** "Every day"

- [ ] **Test B6.16: Format Days - Specific**
  1. formatScheduledDays([1,3,5])
  2. **Expected:** "Mon, Wed, Fri"

### Menu Integration Tests

- [ ] **Test B6.17: Schedule Indicator in Menu**
  1. Create scheduled routine
  2. View menu
  3. **Expected:** Shows ⏰ and time in subtitle

- [ ] **Test B6.18: Non-Scheduled Routine in Menu**
  1. Create manual-only routine
  2. View menu
  3. **Expected:** No schedule indicator shown

### Edge Cases

- [ ] **Test B6.19: No Scheduled Routines**
  1. Create only manual routines
  2. Call registerScheduledEvents()
  3. **Expected:** No error, no event registered

- [ ] **Test B6.20: Multiple Scheduled Routines**
  1. Create 3 routines scheduled at different times
  2. Call findNextScheduledTime()
  3. **Expected:** Returns earliest upcoming time

- [ ] **Test B6.21: Background Memory Limits**
  1. Create many routines (10+)
  2. Trigger background event
  3. **Expected:** No memory errors in background

---

## Success Criteria

| Criteria | Requirement |
|----------|-------------|
| Background compiles | `:background` annotation works |
| Temporal events register | Events scheduled correctly |
| Schedule calculation | Correctly finds next occurrence |
| Day filtering | Weekday/weekend filters work |
| Pending routine works | App launches to scheduled routine |
| Alerts fire | Vibration on scheduled start |
| Menu shows schedule | ⏰ indicator visible |
| Re-registration | Events re-registered on app close |

---

## Acceptance Criteria

This milestone is **COMPLETE** when:

1. ✅ All implementation checkboxes are checked
2. ✅ All tests B6.1 through B6.21 pass
3. ✅ Background service registers and fires temporal events
4. ✅ Scheduled routines launch at configured times
5. ✅ Schedule information displays in menu and glance
6. ✅ Multiple scheduled routines handled correctly

---

## Technical Notes

### Background Memory Constraints
- Background services have ~8KB heap limit
- Keep data loading minimal
- Use lightweight Routine parsing
- Exit quickly with `Background.exit()`

### Temporal Event Timing
- Minimum resolution is ~5 minutes
- System may delay events slightly
- Don't rely on exact second precision
- Register for earliest upcoming event only

### Re-Registration Pattern
- Events must be re-registered after they fire
- Re-register in `onStop()` and `onBackgroundData()`
- Always call `registerScheduledEvents()` on app launch

---

## Files Created/Modified in This Milestone

```
routine-timers/
├── source/
│   ├── RoutineTimersApp.mc          ✓ Modified
│   ├── RoutineTimersBackground.mc   ✓ Created
│   ├── RoutineTimersMenuView.mc     ✓ Modified
│   ├── ScheduleConfigView.mc        ✓ Created
│   ├── services/
│   │   └── ScheduleService.mc       ✓ Created
│   └── utils/
│       └── TestDataFactory.mc       ✓ Modified
├── manifest.xml                     ✓ Modified
```

---

## Next Milestone

Once all criteria are met, proceed to **[M7: Garmin Connect Mobile Integration](./M7_mobile_integration.md)**
