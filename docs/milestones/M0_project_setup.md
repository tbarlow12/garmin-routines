# Milestone 0: Project Setup & Scaffolding

**Estimated Duration:** 1-2 days  
**Dependencies:** None  
**Deliverable:** A working Connect IQ widget project that compiles and runs on the simulator

---

## Goal

Set up the complete development environment and project structure for the Routine Timers application. By the end of this milestone, you will have a skeleton Connect IQ widget app that displays "Hello World" on all target devices.

---

## Implementation Checklist

### Environment Setup

- [ ] Install the latest Garmin Connect IQ SDK
  - Download from: https://developer.garmin.com/connect-iq/sdk/
  - Run the SDK Manager to install device support files
  - Verify SDK version is 6.0 or higher

- [ ] Install Visual Studio Code with Monkey C extension
  - Extension ID: `garmin.monkey-c`
  - Configure the extension to point to your SDK installation

- [ ] Verify simulator launches correctly
  - Open SDK Manager → Launch Simulator
  - Confirm Fenix 7 and Fenix 8 device skins are available

- [ ] Create a Garmin Developer account (if not already done)
  - Register at: https://developer.garmin.com
  - Note your Developer ID for later use

### Project Initialization

- [ ] Create new Connect IQ project using the SDK
  ```bash
  # Use the Connect IQ SDK's project generator or VS Code extension
  # Project name: RoutineTimers
  # App type: Widget
  ```

- [ ] Set up the following directory structure:
  ```
  routine-timers/
  ├── source/
  │   ├── RoutineTimersApp.mc
  │   ├── RoutineTimersView.mc
  │   ├── RoutineTimersDelegate.mc
  │   ├── RoutineTimersGlanceView.mc
  │   ├── models/
  │   │   └── .gitkeep
  │   ├── services/
  │   │   └── .gitkeep
  │   └── utils/
  │       └── .gitkeep
  ├── resources/
  │   ├── strings/
  │   │   └── strings.xml
  │   ├── layouts/
  │   │   └── layout.xml
  │   ├── drawables/
  │   │   └── drawables.xml
  │   └── settings/
  │       └── settings.xml
  ├── manifest.xml
  ├── monkey.jungle
  └── README.md
  ```

- [ ] Configure `manifest.xml` with correct metadata:
  ```xml
  <?xml version="1.0"?>
  <iq:manifest xmlns:iq="http://www.garmin.com/xml/connectiq" version="3">
      <iq:application id="routine-timers" type="widget" 
                      entry="RoutineTimersApp" 
                      launcherIcon="@Drawables.LauncherIcon"
                      name="@Strings.AppName">
          
          <iq:products>
              <!-- Fenix 7 Series -->
              <iq:product id="fenix7s"/>
              <iq:product id="fenix7"/>
              <iq:product id="fenix7x"/>
              <!-- Fenix 8 Series -->
              <iq:product id="fenix8"/>
          </iq:products>
          
          <iq:permissions>
              <iq:uses-permission id="Background"/>
          </iq:permissions>
          
          <iq:languages>
              <iq:language>eng</iq:language>
          </iq:languages>
          
          <iq:barrels/>
      </iq:application>
  </iq:manifest>
  ```

- [ ] Create minimal `strings.xml`:
  ```xml
  <strings>
      <string id="AppName">Routine Timers</string>
  </strings>
  ```

- [ ] Create minimal `RoutineTimersApp.mc`:
  ```monkeyc
  import Toybox.Application;
  import Toybox.Lang;
  import Toybox.WatchUi;

  class RoutineTimersApp extends Application.AppBase {
      function initialize() {
          AppBase.initialize();
      }

      function onStart(state as Dictionary?) as Void {
      }

      function onStop(state as Dictionary?) as Void {
      }

      function getInitialView() as [Views] or [Views, InputDelegates] {
          return [new RoutineTimersView(), new RoutineTimersDelegate()];
      }
  }
  ```

- [ ] Create minimal `RoutineTimersView.mc`:
  ```monkeyc
  import Toybox.Graphics;
  import Toybox.WatchUi;

  class RoutineTimersView extends WatchUi.View {
      function initialize() {
          View.initialize();
      }

      function onLayout(dc as Dc) as Void {
      }

      function onShow() as Void {
      }

      function onUpdate(dc as Dc) as Void {
          dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
          dc.clear();
          dc.drawText(
              dc.getWidth() / 2,
              dc.getHeight() / 2,
              Graphics.FONT_MEDIUM,
              "Routine Timers",
              Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
          );
      }

      function onHide() as Void {
      }
  }
  ```

- [ ] Create minimal `RoutineTimersDelegate.mc`:
  ```monkeyc
  import Toybox.Lang;
  import Toybox.WatchUi;

  class RoutineTimersDelegate extends WatchUi.BehaviorDelegate {
      function initialize() {
          BehaviorDelegate.initialize();
      }

      function onBack() as Boolean {
          WatchUi.popView(WatchUi.SLIDE_RIGHT);
          return true;
      }
  }
  ```

### Build Configuration

- [ ] Configure `monkey.jungle` for all target devices:
  ```
  project.manifest = manifest.xml
  
  # Base source files
  base.sourcePath = source
  base.resourcePath = resources
  
  # Device-specific configurations (if needed later)
  fenix7.resourcePath = $(fenix7.resourcePath);resources-fenix7
  fenix8.resourcePath = $(fenix8.resourcePath);resources-fenix8
  ```

- [ ] Build the project successfully for Fenix 7
  ```bash
  # From VS Code: Monkey C: Build for Device → fenix7
  # Or via command line using the SDK
  ```

- [ ] Build the project successfully for Fenix 8
  ```bash
  # Same process, select fenix8 as target
  ```

- [ ] Verify no compiler warnings or errors

### Version Control

- [ ] Initialize Git repository (if not already done)
  ```bash
  git init
  ```

- [ ] Create `.gitignore` file:
  ```
  # Build outputs
  bin/
  *.prg
  
  # IDE settings
  .vscode/
  *.code-workspace
  
  # OS files
  .DS_Store
  Thumbs.db
  
  # SDK generated
  .connectiq/
  ```

- [ ] Create initial commit
  ```bash
  git add .
  git commit -m "Initial project scaffold"
  ```

---

## Testing Checklist

### Simulator Tests

- [ ] **Test S0.1: Fenix 7 Launch**
  1. Open Connect IQ Simulator
  2. Select Fenix 7 device
  3. Load the compiled `.prg` file
  4. **Expected:** App appears in widget carousel
  5. **Expected:** Opening widget shows "Routine Timers" text centered on screen

- [ ] **Test S0.2: Fenix 7S Launch**
  1. Repeat Test S0.1 with Fenix 7S device skin
  2. **Expected:** Text is still centered and readable (smaller screen)

- [ ] **Test S0.3: Fenix 7X Launch**
  1. Repeat Test S0.1 with Fenix 7X device skin
  2. **Expected:** Text is centered with appropriate margins (larger screen)

- [ ] **Test S0.4: Fenix 8 Launch**
  1. Repeat Test S0.1 with Fenix 8 device skin
  2. **Expected:** Text renders clearly on AMOLED simulation

- [ ] **Test S0.5: Back Button**
  1. Launch widget on any device
  2. Press BACK button
  3. **Expected:** Widget closes, returns to widget carousel

- [ ] **Test S0.6: No Memory Leaks**
  1. Launch widget
  2. Exit widget
  3. Repeat 5 times
  4. **Expected:** No memory warnings in simulator console

### Build Verification

- [ ] **Test B0.1: Clean Build**
  1. Delete `bin/` directory
  2. Rebuild for all target devices
  3. **Expected:** All builds complete without errors

- [ ] **Test B0.2: Device Compatibility**
  1. Open manifest.xml
  2. Verify all Phase 1 devices are listed
  3. **Expected:** fenix7s, fenix7, fenix7x, fenix8 are present

---

## Success Criteria

| Criteria | Requirement |
|----------|-------------|
| SDK Installed | Connect IQ SDK 6.0+ installed and configured |
| Project Compiles | Zero errors for all target devices |
| Simulator Runs | App launches in simulator for all target devices |
| Text Displays | "Routine Timers" text visible and centered |
| Back Button Works | Pressing BACK exits the widget |
| Git Repository | Initial commit with proper .gitignore |

---

## Acceptance Criteria

This milestone is **COMPLETE** when:

1. ✅ A team member can clone the repository and build successfully within 15 minutes
2. ✅ The app runs on the simulator for Fenix 7 and Fenix 8
3. ✅ All checkboxes above are checked
4. ✅ All tests pass

---

## Common Issues & Troubleshooting

### Issue: "Unable to find SDK"
**Solution:** Ensure the `CONNECT_IQ_HOME` environment variable is set, or configure the SDK path in VS Code settings.

### Issue: "Device not supported"
**Solution:** Run SDK Manager and download the device files for Fenix 7/8 series.

### Issue: "Manifest validation failed"
**Solution:** Check that the `id` attribute in manifest.xml is lowercase and contains only alphanumeric characters and hyphens.

### Issue: "Simulator shows black screen"
**Solution:** Ensure `onUpdate()` calls `dc.clear()` before drawing.

---

## Files Created in This Milestone

```
routine-timers/
├── source/
│   ├── RoutineTimersApp.mc         ✓ Created
│   ├── RoutineTimersView.mc        ✓ Created
│   ├── RoutineTimersDelegate.mc    ✓ Created
│   ├── models/
│   │   └── .gitkeep                ✓ Created
│   ├── services/
│   │   └── .gitkeep                ✓ Created
│   └── utils/
│       └── .gitkeep                ✓ Created
├── resources/
│   └── strings/
│       └── strings.xml             ✓ Created
├── manifest.xml                    ✓ Created
├── monkey.jungle                   ✓ Created
├── .gitignore                      ✓ Created
└── README.md                       ✓ Created
```

---

## Next Milestone

Once all criteria are met, proceed to **[M1: Core Timer Engine](./M1_core_timer.md)**
