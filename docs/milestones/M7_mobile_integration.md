# Milestone 7: Garmin Connect Mobile Integration

**Estimated Duration:** 3-4 days  
**Dependencies:** M6 (Background Scheduling)  
**Deliverable:** Full routine management through Garmin Connect Mobile app settings

---

## Goal

Enable users to create, edit, and configure routines through the Garmin Connect Mobile app on their phone. This is the primary interface for routine management since watch-based editing is cumbersome.

---

## Implementation Checklist

### Settings Schema

- [ ] Create `resources/settings/settings.xml`:
  ```xml
  <settings>
      <!-- Global Settings Section -->
      <setting propertyKey="@Properties.enableVibration" 
               title="@Strings.SettingVibration">
          <settingConfig type="boolean" />
      </setting>
      
      <setting propertyKey="@Properties.enableSound" 
               title="@Strings.SettingSound">
          <settingConfig type="boolean" />
      </setting>
      
      <setting propertyKey="@Properties.autoAdvance" 
               title="@Strings.SettingAutoAdvance">
          <settingConfig type="boolean" />
      </setting>
      
      <setting propertyKey="@Properties.showNextStep" 
               title="@Strings.SettingShowNext">
          <settingConfig type="boolean" />
      </setting>
      
      <setting propertyKey="@Properties.warningThreshold" 
               title="@Strings.SettingWarningThreshold">
          <settingConfig type="list">
              <listEntry value="15">15 seconds</listEntry>
              <listEntry value="30">30 seconds</listEntry>
              <listEntry value="60">1 minute</listEntry>
          </settingConfig>
      </setting>
      
      <!-- Routines are managed via JSON property -->
      <setting propertyKey="@Properties.routineData"
               title="@Strings.SettingRoutines">
          <settingConfig type="string" />
      </setting>
  </settings>
  ```

### Properties Definition

- [ ] Create `resources/properties/properties.xml`:
  ```xml
  <properties>
      <property id="enableVibration" type="boolean">true</property>
      <property id="enableSound" type="boolean">false</property>
      <property id="autoAdvance" type="boolean">true</property>
      <property id="showNextStep" type="boolean">true</property>
      <property id="warningThreshold" type="number">30</property>
      <property id="routineData" type="string"></property>
  </properties>
  ```

### Strings for Settings

- [ ] Update `resources/strings/strings.xml`:
  ```xml
  <strings>
      <string id="AppName">Routine Timers</string>
      
      <!-- Settings Labels -->
      <string id="SettingVibration">Vibration Alerts</string>
      <string id="SettingSound">Sound Alerts</string>
      <string id="SettingAutoAdvance">Auto-Advance Steps</string>
      <string id="SettingShowNext">Show Next Step</string>
      <string id="SettingWarningThreshold">Warning Time</string>
      <string id="SettingRoutines">Routine Data</string>
      
      <!-- UI Strings -->
      <string id="NoRoutines">No Routines</string>
      <string id="ConfigureInConnect">Configure in Garmin Connect</string>
      <string id="SelectRoutine">Select Routine</string>
      <string id="PressStart">Press START to begin</string>
      <string id="RoutineComplete">ROUTINE COMPLETE</string>
      <string id="Paused">PAUSED</string>
      <string id="Step">Step</string>
      <string id="Of">of</string>
      <string id="Next">NEXT:</string>
      <string id="Target">Target:</string>
      <string id="ExitHint">Press any button to exit</string>
      
      <!-- Day names -->
      <string id="Sunday">Sun</string>
      <string id="Monday">Mon</string>
      <string id="Tuesday">Tue</string>
      <string id="Wednesday">Wed</string>
      <string id="Thursday">Thu</string>
      <string id="Friday">Fri</string>
      <string id="Saturday">Sat</string>
      <string id="Weekdays">Weekdays</string>
      <string id="Weekends">Weekends</string>
      <string id="EveryDay">Every day</string>
  </strings>
  ```

### Settings Service

- [ ] Create `source/services/SettingsService.mc`:
  ```monkeyc
  import Toybox.Application;
  import Toybox.Application.Properties;
  import Toybox.Lang;
  import Toybox.System;

  module SettingsService {
      // Cache for settings
      private var _vibrationEnabled as Boolean?;
      private var _soundEnabled as Boolean?;
      private var _autoAdvance as Boolean?;
      private var _showNextStep as Boolean?;
      private var _warningThreshold as Number?;

      // Initialize settings cache
      function initialize() as Void {
          loadSettings();
      }

      // Load all settings from properties
      function loadSettings() as Void {
          try {
              _vibrationEnabled = Properties.getValue("enableVibration") as Boolean;
          } catch (e) {
              _vibrationEnabled = true;
          }

          try {
              _soundEnabled = Properties.getValue("enableSound") as Boolean;
          } catch (e) {
              _soundEnabled = false;
          }

          try {
              _autoAdvance = Properties.getValue("autoAdvance") as Boolean;
          } catch (e) {
              _autoAdvance = true;
          }

          try {
              _showNextStep = Properties.getValue("showNextStep") as Boolean;
          } catch (e) {
              _showNextStep = true;
          }

          try {
              _warningThreshold = Properties.getValue("warningThreshold") as Number;
          } catch (e) {
              _warningThreshold = 30;
          }

          // Apply settings to services
          applySettings();
      }

      // Apply loaded settings to relevant services
      private function applySettings() as Void {
          AlertService.setVibrateEnabled(_vibrationEnabled);
          AlertService.setSoundEnabled(_soundEnabled);
          ColorUtils.setWarningThreshold(_warningThreshold);
      }

      // Getters
      function isVibrationEnabled() as Boolean {
          return _vibrationEnabled != null ? _vibrationEnabled : true;
      }

      function isSoundEnabled() as Boolean {
          return _soundEnabled != null ? _soundEnabled : false;
      }

      function isAutoAdvanceEnabled() as Boolean {
          return _autoAdvance != null ? _autoAdvance : true;
      }

      function isShowNextStepEnabled() as Boolean {
          return _showNextStep != null ? _showNextStep : true;
      }

      function getWarningThreshold() as Number {
          return _warningThreshold != null ? _warningThreshold : 30;
      }

      // Handle properties change event
      function onSettingsChanged() as Void {
          loadSettings();
          System.println("Settings reloaded from properties");
      }
  }
  ```

### Routine Data Sync from Properties

- [ ] Create `source/services/SyncService.mc`:
  ```monkeyc
  import Toybox.Application;
  import Toybox.Application.Properties;
  import Toybox.Lang;
  import Toybox.System;

  module SyncService {
      // Sync routines from Properties to Storage
      // Properties come from Garmin Connect Mobile, Storage is local
      function syncRoutinesFromProperties() as Void {
          try {
              var routineDataStr = Properties.getValue("routineData") as String?;
              
              if (routineDataStr == null || routineDataStr.length() == 0) {
                  System.println("No routine data in properties");
                  return;
              }

              // Parse JSON-like routine data
              // Note: Monkey C doesn't have native JSON parsing
              // We'll use a simple format or rely on structured data
              var routines = parseRoutineData(routineDataStr);
              
              if (routines != null && routines.size() > 0) {
                  StorageService.saveRoutines(routines);
                  System.println("Synced " + routines.size() + " routines from properties");
              }
          } catch (e) {
              System.println("Error syncing routines: " + e.getErrorMessage());
          }
      }

      // Parse routine data string into Routine objects
      // Format: JSON-style data passed from Connect Mobile
      private function parseRoutineData(dataStr as String) as Array<Routine>? {
          // In practice, Garmin Connect Mobile will send structured data
          // that can be parsed. For complex JSON, consider a barrel/library.
          
          // Simple parsing approach for demo purposes:
          // The data is expected to be passed as a JSON string which we
          // need to parse carefully given Monkey C limitations.
          
          // For MVP, we'll use Application.Storage directly from phone sync
          // and this serves as a placeholder for future enhancement
          
          return null;
      }

      // Export routines to a format the phone can read
      function exportRoutinesToProperties() as Void {
          var routines = StorageService.loadRoutines();
          
          // Convert to a string format
          // This would be picked up by the companion phone app
          var dataStr = "";
          for (var i = 0; i < routines.size(); i++) {
              // Simple serialization
              if (dataStr.length() > 0) {
                  dataStr += "|";
              }
              dataStr += routines[i].id + "," + routines[i].name;
          }
          
          try {
              Properties.setValue("routineData", dataStr);
          } catch (e) {
              System.println("Error exporting routines: " + e.getErrorMessage());
          }
      }
  }
  ```

### Update App to Handle Settings Changes

- [ ] Update `RoutineTimersApp.mc`:
  ```monkeyc
  import Toybox.Application;
  import Toybox.Lang;
  import Toybox.WatchUi;
  import Toybox.Background;
  import Toybox.System;

  class RoutineTimersApp extends Application.AppBase {
      function initialize() {
          AppBase.initialize();
      }

      function onStart(state as Dictionary?) as Void {
          // Initialize settings
          SettingsService.initialize();
          
          // Initialize sample data if first run
          StorageService.initializeWithSampleData();
          
          // Sync routines from properties (from phone)
          SyncService.syncRoutinesFromProperties();
          
          // Register for scheduled events
          ScheduleService.registerScheduledEvents();
      }

      function onStop(state as Dictionary?) as Void {
          // Re-register events when app closes
          ScheduleService.registerScheduledEvents();
      }

      // Called when settings are changed via Garmin Connect Mobile
      function onSettingsChanged() as Void {
          System.println("Settings changed via Garmin Connect");
          
          // Reload settings
          SettingsService.onSettingsChanged();
          
          // Sync any routine data changes
          SyncService.syncRoutinesFromProperties();
          
          // Re-register scheduled events in case schedules changed
          ScheduleService.registerScheduledEvents();
          
          // Refresh the UI if it's showing
          WatchUi.requestUpdate();
      }

      function onBackgroundData(data) as Void {
          System.println("Received background data: " + data);
          
          if (data != null && data instanceof String) {
              var routineId = data as String;
              Application.Storage.setValue("pendingRoutineId", routineId);
              Application.Storage.setValue("pendingRoutineTriggered", true);
          }
          
          ScheduleService.registerScheduledEvents();
      }

      function getInitialView() as [Views] or [Views, InputDelegates] {
          // Check for pending routine from scheduled trigger
          var pendingRoutineId = ScheduleService.checkPendingRoutine();
          
          if (pendingRoutineId != null) {
              var routine = StorageService.getRoutine(pendingRoutineId);
              if (routine != null) {
                  var view = new RoutineTimersView();
                  view.getRoutineService().loadRoutine(routine);
                  AlertService.alertRoutineStart();
                  return [view, new RoutineTimersDelegate(view)];
              }
          }
          
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

      function getServiceDelegate() as [System.ServiceDelegate] {
          return [new RoutineTimersBackground()];
      }
  }
  ```

### Update ColorUtils to Use Settings

- [ ] Modify `ColorUtils.mc`:
  ```monkeyc
  module ColorUtils {
      // ... existing constants ...
      
      // Configurable thresholds (defaults)
      private var _warningThreshold = 30;
      private var _alertThreshold = 10;

      // Setter for warning threshold
      function setWarningThreshold(seconds as Number) as Void {
          _warningThreshold = seconds;
          // Alert threshold is typically 1/3 of warning
          _alertThreshold = seconds / 3;
          if (_alertThreshold < 5) {
              _alertThreshold = 5;
          }
      }

      // Get timer color based on remaining seconds
      function getTimerColor(remainingSeconds as Number) as Number {
          if (remainingSeconds <= _alertThreshold) {
              return COLOR_ALERT;
          } else if (remainingSeconds <= _warningThreshold) {
              return COLOR_WARNING;
          }
          return COLOR_PRIMARY_TEXT;
      }

      // ... rest of existing code ...
  }
  ```

### Update RoutineService to Use Settings

- [ ] Modify `RoutineService.mc`:
  ```monkeyc
  // In initialize():
  function initialize() {
      // ... existing code ...
      
      // Apply auto-advance setting
      _autoAdvance = SettingsService.isAutoAdvanceEnabled();
  }

  // Update method to refresh from settings:
  function refreshSettings() as Void {
      _autoAdvance = SettingsService.isAutoAdvanceEnabled();
  }
  ```

### Update View to Use Settings

- [ ] Modify `RoutineTimersView.mc` to respect showNextStep setting:
  ```monkeyc
  private function drawNextStepInfo(dc as Dc, routine as Routine) as Void {
      // Check setting
      if (!SettingsService.isShowNextStepEnabled()) {
          return;
      }
      
      if (_routineService.isIdle()) {
          return;
      }

      // ... rest of existing code ...
  }
  ```

### Companion App Data Format Documentation

- [ ] Create `docs/companion_app_data_format.md`:
  ```markdown
  # Routine Timers - Companion App Data Format
  
  This document describes the data format used to sync routines between
  the Garmin Connect Mobile app and the watch.
  
  ## Properties Schema
  
  ### Global Settings
  
  | Property Key | Type | Default | Description |
  |--------------|------|---------|-------------|
  | enableVibration | boolean | true | Enable vibration alerts |
  | enableSound | boolean | false | Enable audio alerts |
  | autoAdvance | boolean | true | Auto-advance to next step |
  | showNextStep | boolean | true | Display upcoming step |
  | warningThreshold | number | 30 | Seconds before warning state |
  | routineData | string | "" | JSON-encoded routine data |
  
  ### Routine Data Format (routineData property)
  
  The routineData property contains a JSON-encoded array of routines:
  
  ```json
  [
    {
      "id": "uuid-string",
      "name": "Morning Routine",
      "triggerType": "MANUAL",
      "scheduledTime": null,
      "scheduledDays": null,
      "steps": [
        {
          "id": "step-uuid",
          "name": "Scripture Study",
          "duration": 1200,
          "alertSound": false,
          "alertVibrate": true
        },
        {
          "id": "step-uuid-2",
          "name": "Tidy up office",
          "duration": 300,
          "alertSound": false,
          "alertVibrate": true
        }
      ]
    }
  ]
  ```
  
  ### Trigger Types
  
  - `MANUAL` - User starts routine manually
  - `SCHEDULED` - Routine starts at scheduled time
  - `EVENT` - Future: triggered by system event
  
  ### Time Format
  
  - `scheduledTime` - Seconds from midnight (0-86399)
    - Example: 6:00 AM = 21600 (6 × 3600)
    - Example: 2:30 PM = 52200 (14 × 3600 + 30 × 60)
  
  ### Days Format
  
  - `scheduledDays` - Array of day indices
    - 0 = Sunday
    - 1 = Monday
    - 2 = Tuesday
    - 3 = Wednesday
    - 4 = Thursday
    - 5 = Friday
    - 6 = Saturday
    - Example: Weekdays = [1, 2, 3, 4, 5]
  
  ### Duration Format
  
  - All durations in seconds
  - Example: 20 minutes = 1200 seconds
  
  ## Sync Flow
  
  1. User edits routine in Garmin Connect Mobile
  2. Connect IQ syncs properties to watch
  3. Watch app receives `onSettingsChanged()` callback
  4. `SyncService` parses new routine data
  5. Routines saved to local `Storage`
  6. UI refreshes to show updated data
  ```

---

## Testing Checklist

### Settings Tests

- [ ] **Test M7.1: Default Settings Load**
  1. Fresh install (clear all data)
  2. Launch app
  3. **Expected:** Vibration enabled, sound disabled, auto-advance enabled

- [ ] **Test M7.2: Settings Change Detection**
  1. Launch app
  2. In simulator: File → Trigger Settings Changed
  3. **Expected:** onSettingsChanged() called
  4. **Expected:** Settings reloaded

- [ ] **Test M7.3: Vibration Setting**
  1. Disable vibration in settings
  2. Trigger settings changed
  3. Start routine
  4. **Expected:** No vibration alerts

- [ ] **Test M7.4: Sound Setting**
  1. Enable sound in settings
  2. Trigger settings changed
  3. Start routine
  4. **Expected:** Audio alerts play

- [ ] **Test M7.5: Auto-Advance Setting**
  1. Disable auto-advance in settings
  2. Trigger settings changed
  3. Start routine, wait for step to end
  4. **Expected:** Pauses at step end instead of advancing

- [ ] **Test M7.6: Show Next Step Setting**
  1. Disable show next step in settings
  2. Trigger settings changed
  3. View active timer
  4. **Expected:** "NEXT:" section hidden

- [ ] **Test M7.7: Warning Threshold Setting**
  1. Change warning threshold to 60 seconds
  2. Trigger settings changed
  3. Start step with 90 seconds
  4. **Expected:** Warning state at 60 seconds

### Properties Sync Tests

- [ ] **Test M7.8: Settings File Validation**
  1. Build project
  2. Verify settings.xml is valid
  3. **Expected:** No XML errors

- [ ] **Test M7.9: Properties Defaults**
  1. Check properties.xml
  2. **Expected:** All properties have sensible defaults

### Localization Tests

- [ ] **Test M7.10: String Resources**
  1. Verify all UI strings are in strings.xml
  2. **Expected:** No hardcoded strings in code

### Companion App Integration Tests

- [ ] **Test M7.11: Routine Data from Properties**
  1. Manually set routineData property with valid JSON
  2. Trigger settings changed
  3. **Expected:** Routines parsed and stored

- [ ] **Test M7.12: Empty Routine Data**
  1. Set routineData to empty string
  2. Trigger settings changed
  3. **Expected:** No error, existing routines preserved

- [ ] **Test M7.13: Invalid Routine Data**
  1. Set routineData to invalid format
  2. Trigger settings changed
  3. **Expected:** Error logged, app doesn't crash

### UI Refresh Tests

- [ ] **Test M7.14: Menu Refresh After Sync**
  1. Add routine via properties
  2. Trigger settings changed
  3. **Expected:** New routine appears in menu

- [ ] **Test M7.15: Timer View Refresh**
  1. Change setting while timer is showing
  2. Trigger settings changed
  3. **Expected:** View updates with new settings

### Edge Cases

- [ ] **Test M7.16: Settings Change During Active Routine**
  1. Start a routine
  2. Change auto-advance setting
  3. Trigger settings changed
  4. **Expected:** New setting applies to next step

- [ ] **Test M7.17: Large Routine Data**
  1. Create 10 routines with 15 steps each
  2. Sync via properties
  3. **Expected:** All routines sync correctly

- [ ] **Test M7.18: Unicode in Routine Names**
  1. Create routine with emoji/unicode name
  2. Sync via properties
  3. **Expected:** Name displays correctly (or gracefully fails)

---

## Success Criteria

| Criteria | Requirement |
|----------|-------------|
| Settings load | All properties load with defaults |
| Settings apply | Changing settings affects behavior |
| Sync callback | onSettingsChanged() triggers correctly |
| Routine sync | Routines from properties appear in app |
| UI updates | Views refresh after settings change |
| Data format | Companion app format documented |
| No crashes | Invalid data handled gracefully |

---

## Acceptance Criteria

This milestone is **COMPLETE** when:

1. ✅ All implementation checkboxes are checked
2. ✅ All tests M7.1 through M7.18 pass
3. ✅ Settings are configurable via Garmin Connect Mobile
4. ✅ Routine data syncs from phone to watch
5. ✅ Settings changes apply immediately
6. ✅ Companion app data format is documented

---

## Garmin Connect Mobile Settings Preview

When users open the app settings in Garmin Connect Mobile, they will see:

```
┌─────────────────────────────────────┐
│ Routine Timers Settings             │
├─────────────────────────────────────┤
│                                     │
│ Alerts                              │
│ ┌─────────────────────────────────┐ │
│ │ Vibration Alerts          [ON] │ │
│ │ Sound Alerts             [OFF] │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Behavior                            │
│ ┌─────────────────────────────────┐ │
│ │ Auto-Advance Steps        [ON] │ │
│ │ Show Next Step            [ON] │ │
│ │ Warning Time         [30 sec]  │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Routine Data                        │
│ ┌─────────────────────────────────┐ │
│ │ [Configure Routines...]        │ │
│ └─────────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

---

## Files Created/Modified in This Milestone

```
routine-timers/
├── source/
│   ├── RoutineTimersApp.mc             ✓ Modified
│   ├── RoutineTimersView.mc            ✓ Modified
│   ├── services/
│   │   ├── SettingsService.mc          ✓ Created
│   │   ├── SyncService.mc              ✓ Created
│   │   └── RoutineService.mc           ✓ Modified
│   └── utils/
│       └── ColorUtils.mc               ✓ Modified
├── resources/
│   ├── settings/
│   │   └── settings.xml                ✓ Created
│   ├── properties/
│   │   └── properties.xml              ✓ Created
│   └── strings/
│       └── strings.xml                 ✓ Modified
└── docs/
    └── companion_app_data_format.md    ✓ Created
```

---

## Next Milestone

Once all criteria are met, proceed to **[M8: Multi-Device Testing & Polish](./M8_testing_polish.md)**
