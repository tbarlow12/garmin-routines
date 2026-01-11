# Testing Guide

This document describes how to run automated tests for the Routine Timers Connect IQ application.

## Overview

The project uses Monkey C's built-in test framework, which allows you to write unit tests that run in the Connect IQ Simulator. Tests are written using the `(:test)` annotation and can verify logic, state management, and utility functions.

## What Can Be Tested

### ✅ Automated Testing (Unit Tests)
- **TimerService logic** - State transitions, duration management, pause/resume
- **TimeFormatter utilities** - Time formatting functions (MM:SS, H:MM:SS)
- **Business logic** - Any pure functions or services without UI dependencies
- **Data models** - Validation, serialization, state management

### ⚠️ Limited Automation (Manual Testing Required)
- **UI interactions** - Button presses, screen transitions
- **Visual rendering** - Layout, colors, fonts
- **Timer accuracy** - Requires real-time execution
- **Device-specific behavior** - Screen sizes, button layouts

## Running Tests

### Method 1: Using Makefile (Recommended)

```bash
# Build test version and get instructions
make test

# Or just build test version
make test-build
```

This will:
1. Compile the app with test code included (`-t` flag)
2. Generate `bin/RoutineTimers-test.prg`
3. Provide instructions for running in simulator

### Method 2: Manual Build

```bash
cd RoutineTimers

# Build with test flag
java -jar "$CONNECT_IQ_HOME/bin/monkeybrains.jar" \
    -o bin/RoutineTimers-test.prg \
    -f monkey.jungle \
    -y ../developer_key \
    -d fenix8pro47mm_sim \
    -t \
    -w
```

### Running Tests in Simulator

1. **Launch Connect IQ Simulator:**
   ```bash
   $CONNECT_IQ_HOME/bin/connectiq
   ```

2. **Load the test build:**
   - File → Open
   - Select `bin/RoutineTimers-test.prg`

3. **View test results:**
   - Tests run automatically when the app loads
   - Check the simulator console for test output
   - Green = pass, Red = fail

## Test Structure

Tests are located in `source/tests/`:

```
source/tests/
├── TimerServiceTest.mc    # Tests for TimerService class
└── TimeFormatterTest.mc    # Tests for TimeFormatter module
```

### Writing a Test

```monkeyc
import Toybox.Lang;
import Toybox.Test;

(:test)
function testMyFunction(logger as Logger) as Boolean {
    // Arrange
    var input = 42;
    
    // Act
    var result = myFunction(input);
    
    // Assert
    return result == expectedValue;
}
```

### Test Function Requirements

- Must be annotated with `(:test)`
- Must accept `logger as Logger` parameter
- Must return `Boolean` (true = pass, false = fail)
- Use `logger.debug()` or `logger.error()` for output

## Current Test Coverage

### TimerService Tests (20 tests)
- ✅ Initialization
- ✅ Duration setting
- ✅ Start/pause/resume/stop
- ✅ State transitions
- ✅ Elapsed time calculation
- ✅ Progress percentage
- ✅ Edge cases (zero duration, invalid states)

### TimeFormatter Tests (18 tests)
- ✅ MM:SS formatting
- ✅ H:MM:SS formatting
- ✅ Smart formatting (auto-selects format)
- ✅ Edge cases (zero, negative, large values)
- ✅ Leading zeros

## Limitations

### Timer Accuracy Testing
Timer accuracy tests require real-time execution and cannot be fully automated. For accuracy verification:

1. Start a timer with known duration
2. Use external stopwatch
3. Verify completion within ±1 second tolerance

### UI Testing
UI tests require manual verification:
- Visual layout
- Button responsiveness
- Screen transitions
- Color/contrast

### Integration Testing
Some integration tests need manual setup:
- Storage persistence
- Background service triggers
- Settings synchronization

## Continuous Integration

For CI/CD pipelines:

```bash
# Build test version
make test-build

# Load in headless simulator (if available)
# Note: Full CI requires simulator automation, which may not be available
```

## Best Practices

1. **Write tests for new features** - Add tests when implementing new services or utilities
2. **Test edge cases** - Zero values, negative values, boundary conditions
3. **Keep tests fast** - Avoid long-running operations
4. **Use descriptive names** - Test names should describe what they verify
5. **Test one thing per test** - Each test should verify a single behavior

## Troubleshooting

### Tests don't appear in simulator
- Ensure you built with `-t` flag
- Check that test files are in `source/tests/`
- Verify `monkey.jungle` includes test source path

### Test fails unexpectedly
- Check simulator console for error messages
- Verify test logic is correct
- Ensure dependencies are imported correctly

### Build errors with tests
- Make sure test functions follow the required signature
- Check that all imports are available
- Verify `(:test)` annotation is present

## Future Enhancements

Potential improvements to testing:
- [ ] Mock framework for testing UI interactions
- [ ] Automated timer accuracy testing with time manipulation
- [ ] Visual regression testing
- [ ] Performance benchmarking
- [ ] Memory leak detection automation
