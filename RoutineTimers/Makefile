# Makefile for RoutineTimers Garmin Connect IQ Widget
# Run from the RoutineTimers/ directory

# Detect Connect IQ SDK path
# Priority: CONNECT_IQ_HOME env var, then common macOS locations
CONNECT_IQ_HOME ?= $(shell \
	if [ -n "$$CONNECT_IQ_HOME" ]; then \
		echo "$$CONNECT_IQ_HOME"; \
	elif [ -d "$$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks" ]; then \
		JAR_PATH=$$(find "$$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks" -name "monkeybrains.jar" -type f 2>/dev/null | head -1); \
		if [ -n "$$JAR_PATH" ]; then \
			dirname "$$(dirname "$$JAR_PATH")"; \
		else \
			echo ""; \
		fi; \
	else \
		echo ""; \
	fi)

# Validate SDK path
ifeq ($(CONNECT_IQ_HOME),)
$(error CONNECT_IQ_HOME not set and SDK not found. Set CONNECT_IQ_HOME or install SDK.)
endif

MONKEYBRAINS_JAR := $(CONNECT_IQ_HOME)/bin/monkeybrains.jar
MONKEYDO := $(CONNECT_IQ_HOME)/bin/monkeydo

# Validate monkeybrains.jar exists (using shell test to handle spaces)
MONKEYBRAINS_EXISTS := $(shell test -f "$(MONKEYBRAINS_JAR)" && echo "yes" || echo "no")
ifeq ($(MONKEYBRAINS_EXISTS),no)
$(error monkeybrains.jar not found at $(MONKEYBRAINS_JAR). Check CONNECT_IQ_HOME.)
endif

# Validate monkeydo exists
MONKEYDO_EXISTS := $(shell test -f "$(MONKEYDO)" && echo "yes" || echo "no")
ifeq ($(MONKEYDO_EXISTS),no)
$(error monkeydo not found at $(MONKEYDO). Check CONNECT_IQ_HOME.)
endif

# Convert device name for monkeydo (remove _sim suffix if present)
# Handle default and convert _sim suffix
ifeq ($(DEVICE),fenix8pro47mm_sim)
    MONKEYDO_DEVICE := fenix8pro47mm
else ifneq ($(findstring _sim,$(DEVICE)),)
    MONKEYDO_DEVICE := $(patsubst %_sim,%,$(DEVICE))
else
    MONKEYDO_DEVICE := $(DEVICE)
endif

# Simulator executable
SIMULATOR := $(CONNECT_IQ_HOME)/bin/connectiq

# Check if simulator exists
SIMULATOR_EXISTS := $(shell test -f "$(SIMULATOR)" && echo "yes" || echo "no")

# Project paths (relative to RoutineTimers/)
JUNGLE_FILE := monkey.jungle
DEVELOPER_KEY := ../developer_key
OUTPUT_DIR := bin
OUTPUT_FILE := $(OUTPUT_DIR)/RoutineTimers.prg

# Default device (can be overridden: make DEVICE=fenix7)
DEVICE ?= fenix8pro47mm_sim

# Java options
JAVA_OPTS := -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true

# Build flags
BUILD_FLAGS := -w

.PHONY: all build clean help list-devices test test-build test-run run run-test run-deps open-simulator reload

# Default target
all: build

# Build the app for the specified device
build: $(OUTPUT_DIR)
	@echo "Building for device: $(DEVICE)"
	@echo "Using SDK: $(CONNECT_IQ_HOME)"
	java $(JAVA_OPTS) -jar "$(MONKEYBRAINS_JAR)" \
		-o $(OUTPUT_FILE) \
		-f $(JUNGLE_FILE) \
		-y $(DEVELOPER_KEY) \
		-d $(DEVICE) \
		$(BUILD_FLAGS)
	@echo "Build complete: $(OUTPUT_FILE)"

# Build for all devices (no -d flag)
build-all: $(OUTPUT_DIR)
	@echo "Building for all devices in manifest..."
	@echo "Using SDK: $(CONNECT_IQ_HOME)"
	java $(JAVA_OPTS) -jar "$(MONKEYBRAINS_JAR)" \
		-o $(OUTPUT_FILE) \
		-f $(JUNGLE_FILE) \
		-y $(DEVELOPER_KEY) \
		$(BUILD_FLAGS)
	@echo "Build complete: $(OUTPUT_FILE)"

# Create output directory if it doesn't exist
$(OUTPUT_DIR):
	mkdir -p $(OUTPUT_DIR)

# Clean build artifacts
clean:
	rm -rf $(OUTPUT_DIR)
	@echo "Cleaned build artifacts"

# List available devices (requires SDK)
list-devices:
	@echo "Available devices:"
	@java $(JAVA_OPTS) -jar "$(MONKEYBRAINS_JAR)" -l 2>/dev/null | grep -E "^[a-z]" || echo "Could not list devices. Check SDK installation."

# Build test version (includes test code)
test-build: $(OUTPUT_DIR)
	@echo "Building test version for device: $(DEVICE)"
	@echo "Using SDK: $(CONNECT_IQ_HOME)"
	java $(JAVA_OPTS) -jar "$(MONKEYBRAINS_JAR)" \
		-o $(OUTPUT_DIR)/RoutineTimers-test.prg \
		-f $(JUNGLE_FILE) \
		-y $(DEVELOPER_KEY) \
		-d $(DEVICE) \
		-t \
		$(BUILD_FLAGS)
	@echo "Test build complete: $(OUTPUT_DIR)/RoutineTimers-test.prg"
	@echo ""
	@echo "To run tests:"
	@echo "  1. Launch Connect IQ Simulator"
	@echo "  2. Load $(OUTPUT_DIR)/RoutineTimers-test.prg"
	@echo "  3. Tests will run automatically and results appear in simulator console"

# Run tests (builds test version and provides instructions)
test: test-build
	@echo ""
	@echo "=========================================="
	@echo "Test build completed successfully!"
	@echo "=========================================="
	@echo ""
	@echo "Next steps:"
	@echo "  1. Open Connect IQ Simulator:"
	@echo "     $$CONNECT_IQ_HOME/bin/connectiq"
	@echo ""
	@echo "  2. Load the test build:"
	@echo "     File -> Open -> $(OUTPUT_DIR)/RoutineTimers-test.prg"
	@echo ""
	@echo "  3. Tests will run automatically"
	@echo "  4. Check simulator console for test results"
	@echo ""
	@echo "Or use: make test-run (if simulator is already open)"

# Test run instructions (assumes simulator is open)
test-run: test-build
	@echo ""
	@echo "Test build ready. Load $(OUTPUT_DIR)/RoutineTimers-test.prg in the simulator."

# Reload existing build in simulator (no rebuild)
reload: run-deps
	@if [ ! -f "$(OUTPUT_FILE)" ]; then \
		echo "Error: $(OUTPUT_FILE) not found. Run 'make build' first."; \
		exit 1; \
	fi
	@echo ""
	@echo "=========================================="
	@echo "Reloading app in simulator..."
	@echo "=========================================="
	@echo "App: $(OUTPUT_FILE)"
	@echo "Device: $(MONKEYDO_DEVICE)"
	@echo ""
	@if [ -z "$(MONKEYDO_DEVICE)" ]; then \
		"$(MONKEYDO)" "$(OUTPUT_FILE)" fenix8pro47mm || \
			(echo "" && echo "Failed. Try manually: File -> Open -> $(OUTPUT_FILE)"); \
	else \
		echo "Running: $(MONKEYDO) \"$(OUTPUT_FILE)\" $(MONKEYDO_DEVICE)"; \
		"$(MONKEYDO)" "$(OUTPUT_FILE)" $(MONKEYDO_DEVICE) || \
			(echo "" && \
			 echo "⚠️  Could not connect to simulator." && \
			 echo "   Try manually: File -> Open -> $(OUTPUT_FILE)"); \
	fi

# Open simulator location in Finder (macOS)
open-simulator:
	@if [ "$(SIMULATOR_EXISTS)" != "yes" ]; then \
		echo "Error: Simulator not found at $(SIMULATOR)"; \
		exit 1; \
	fi
	@echo "Opening simulator location in Finder..."
	@open -R "$(SIMULATOR)"
	@echo "✓ Finder window opened"
	@echo ""
	@echo "To launch simulator:"
	@echo "  Double-click 'connectiq' in the Finder window"

# Start the Connect IQ Simulator (dependency for run commands)
run-deps:
	@if [ "$(SIMULATOR_EXISTS)" != "yes" ]; then \
		echo "Error: Simulator not found at $(SIMULATOR)"; \
		exit 1; \
	fi
	@if pgrep -f "connectiq" > /dev/null 2>&1; then \
		echo "✓ Simulator is already running"; \
		echo "  Look for the Connect IQ Simulator window on your screen"; \
	else \
		echo "Starting Connect IQ Simulator..."; \
		echo "  A new window should appear shortly..."; \
		"$(SIMULATOR)" & \
		echo "Waiting for simulator to start (this may take 10-15 seconds)..."; \
		sleep 8; \
		echo ""; \
		echo "✓ Simulator should be ready now"; \
		echo "  Look for the Connect IQ Simulator window:"; \
		echo "    - It shows a watch face/screen"; \
		echo "    - You can select different devices from the menu"; \
		echo "    - The window title says 'Connect IQ Simulator'"; \
	fi

# Build and run the app in simulator
run: build run-deps
	@echo ""
	@echo "=========================================="
	@echo "Launching app in simulator..."
	@echo "=========================================="
	@echo "App: $(OUTPUT_FILE)"
	@echo "Device: $(MONKEYDO_DEVICE)"
	@echo ""
	@if [ -z "$(MONKEYDO_DEVICE)" ]; then \
		echo "⚠️  Error: Device name is empty!"; \
		echo "   Using default: fenix8pro47mm"; \
		"$(MONKEYDO)" "$(OUTPUT_FILE)" fenix8pro47mm || \
			(echo "" && echo "Failed. Try manually: File -> Open -> $(OUTPUT_FILE)"); \
	else \
		echo "Running: $(MONKEYDO) \"$(OUTPUT_FILE)\" $(MONKEYDO_DEVICE)"; \
		"$(MONKEYDO)" "$(OUTPUT_FILE)" $(MONKEYDO_DEVICE) || \
			(echo "" && \
			 echo "⚠️  Could not connect to simulator." && \
			 echo "" && \
			 echo "Try:" && \
			 echo "  1. Make sure simulator window is open and ready" && \
			 echo "  2. Check that device '$(MONKEYDO_DEVICE)' is selected in simulator" && \
			 echo "  3. Wait a few more seconds and run: make run (again)" && \
			 echo "  4. Or manually: File -> Open -> $(OUTPUT_FILE)"); \
	fi

# Build test version and run in simulator
run-test: test-build run-deps
	@echo ""
	@echo "=========================================="
	@echo "Launching test build in simulator..."
	@echo "=========================================="
	@echo "App: $(OUTPUT_DIR)/RoutineTimers-test.prg"
	@echo "Device: $(MONKEYDO_DEVICE)"
	@echo ""
	@if [ -z "$(MONKEYDO_DEVICE)" ]; then \
		echo "⚠️  Error: Device name is empty!"; \
		echo "   Using default: fenix8pro47mm"; \
		"$(MONKEYDO)" "$(OUTPUT_DIR)/RoutineTimers-test.prg" fenix8pro47mm || \
			(echo "" && echo "Failed. Try manually: File -> Open -> $(OUTPUT_DIR)/RoutineTimers-test.prg"); \
	else \
		echo "Running: $(MONKEYDO) \"$(OUTPUT_DIR)/RoutineTimers-test.prg\" $(MONKEYDO_DEVICE)"; \
		"$(MONKEYDO)" "$(OUTPUT_DIR)/RoutineTimers-test.prg" $(MONKEYDO_DEVICE) || \
			(echo "" && \
			 echo "⚠️  Could not connect to simulator." && \
			 echo "" && \
			 echo "Try:" && \
			 echo "  1. Make sure simulator window is open and ready" && \
			 echo "  2. Check that device '$(MONKEYDO_DEVICE)' is selected in simulator" && \
			 echo "  3. Wait a few more seconds and run: make run-test (again)" && \
			 echo "  4. Or manually: File -> Open -> $(OUTPUT_DIR)/RoutineTimers-test.prg"); \
	fi

# Help target
help:
	@echo "RoutineTimers Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make              Build for default device (fenix8pro47mm_sim)"
	@echo "  make DEVICE=fenix7  Build for specific device"
	@echo "  make build-all    Build for all devices in manifest"
	@echo "  make clean        Remove build artifacts"
	@echo "  make list-devices List available devices"
	@echo "  make run-deps     Start Connect IQ Simulator (if not running)"
	@echo "  make open-simulator Open simulator location in Finder"
	@echo "  make run          Build and launch app in simulator"
	@echo "  make reload       Reload existing build in simulator (no rebuild)"
	@echo "  make run-test     Build test version and launch in simulator"
	@echo "  make test         Build test version and show instructions"
	@echo "  make test-build   Build test version only"
	@echo "  make help         Show this help"
	@echo ""
	@echo "Environment:"
	@echo "  CONNECT_IQ_HOME  Path to Connect IQ SDK (auto-detected if not set)"
	@echo ""
	@echo "Current settings:"
	@echo "  SDK: $(CONNECT_IQ_HOME)"
	@echo "  Device: $(DEVICE)"
	@echo "  Output: $(OUTPUT_FILE)"
