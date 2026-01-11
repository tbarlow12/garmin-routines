# Routine Timers

A Garmin Connect IQ widget application for executing timed routines with multiple sequential steps.

## Development Status

Currently implementing Milestone 0 (Project Setup & Scaffolding).

## Prerequisites

- **Java Runtime Environment (JRE) 8+** - Required for Connect IQ SDK tools
  - Install via Homebrew: `brew install --cask temurin` (recommended)
  - Or download from [Adoptium](https://adoptium.net/) or [Oracle](https://www.java.com/)
  - Verify: `java -version` should show Java 8 or higher

- **Garmin Connect IQ SDK 6.0+**
  - Download from: https://developer.garmin.com/connect-iq/sdk/
  - Set `CONNECT_IQ_HOME` environment variable to SDK installation path
  - Or configure SDK path in VS Code settings

- **Visual Studio Code** with Monkey C extension
  - Extension ID: `garmin.monkey-c`

## Building

Build using Visual Studio Code with the Monkey C extension, or via command line:

```bash
# Set CONNECT_IQ_HOME if not already set
export CONNECT_IQ_HOME=/path/to/connectiq-sdk

# Build for specific device
monkeyc -f monkey.jungle -o bin/RoutineTimers.prg -d fenix7

# Or build for all devices
monkeyc -f monkey.jungle -o bin/RoutineTimers.prg
```

## Testing

Launch the Connect IQ Simulator:

```bash
# If SDK is installed and CONNECT_IQ_HOME is set
$CONNECT_IQ_HOME/bin/connectiq

# Or use the SDK Manager GUI
# Then load the compiled .prg file from bin/ directory
```

## Target Devices

- Fenix 7 Series (7S, 7, 7X)
- Fenix 8 Series (43mm, 47mm, 51mm)

## Project Structure

```
RoutineTimers/
├── source/              # Monkey C source files
│   ├── models/         # Data models (Routine, Step)
│   ├── services/       # Business logic (Timer, Storage, Alerts)
│   └── utils/          # Utility functions
├── resources/          # Resources (strings, layouts, drawables)
├── manifest.xml        # App manifest
└── monkey.jungle      # Build configuration
```

For detailed specifications, see `../docs/app_spec.md`.
