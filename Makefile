# Speedometer iOS CLI workflow
#
# This Makefile standardizes local and automated commands so both humans and
# Copilot can use one predictable interface.

PROJECT := Speedometer.xcodeproj
SCHEME := Speedometer
BUNDLE_ID := com.aaronbbrown.speedometer
DERIVED_DATA := .build
APP_PATH := $(DERIVED_DATA)/Build/Products/Debug-iphonesimulator/Speedometer.app

# Defaults are overridable, for example:
# make build SIM_DEVICE="iPhone 17"
SIM_DEVICE ?= iPhone 17 Pro
DESTINATION ?= platform=iOS Simulator,name=$(SIM_DEVICE)

XCODEBUILD := xcodebuild
XCODEGEN := xcodegen
SIMCTL := xcrun simctl

.PHONY: help doctor generate open-xcode list-sims list-runtimes build build-clean test warnings clean sim-open sim-boot sim-install sim-launch sim-run sim-uninstall reset

help:
	@echo "Speedometer Make targets"
	@echo "  make doctor        - Check required local tools"
	@echo "  make generate      - Generate Xcode project from project.yml"
	@echo "  make build         - Build app for simulator"
	@echo "  make build-clean   - Clean + build for simulator"
	@echo "  make test          - Run unit tests on simulator"
	@echo "  make warnings      - Build and print warning/deprecation lines"
	@echo "  make sim-run       - Build, install, and launch in simulator"
	@echo "  make sim-install   - Install built app into booted simulator"
	@echo "  make sim-launch    - Launch app in booted simulator"
	@echo "  make sim-uninstall - Remove app from booted simulator"
	@echo "  make list-sims     - List available simulator devices"
	@echo "  make clean         - Remove derived data and clean build artifacts"
	@echo ""
	@echo "Overrides: SIM_DEVICE='iPhone 17 Pro' DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro'"

doctor:
	@echo "Checking required tools..."
	@command -v $(XCODEBUILD) >/dev/null || (echo "Missing: xcodebuild" && exit 1)
	@command -v $(XCODEGEN) >/dev/null || (echo "Missing: xcodegen" && exit 1)
	@command -v xcrun >/dev/null || (echo "Missing: xcrun" && exit 1)
	@echo "xcodebuild: $$($(XCODEBUILD) -version | head -n 1)"
	@echo "xcodegen: $$($(XCODEGEN) --version | head -n 1)"

generate:
	$(XCODEGEN) generate

open-xcode: generate
	open $(PROJECT)

list-sims:
	$(SIMCTL) list devices available

list-runtimes:
	$(SIMCTL) list runtimes

build: generate
	$(XCODEBUILD) build \
	  -project $(PROJECT) \
	  -scheme $(SCHEME) \
	  -destination '$(DESTINATION)' \
	  -derivedDataPath $(DERIVED_DATA)

build-clean: generate
	$(XCODEBUILD) clean build \
	  -project $(PROJECT) \
	  -scheme $(SCHEME) \
	  -destination '$(DESTINATION)' \
	  -derivedDataPath $(DERIVED_DATA)

test: generate
	$(XCODEBUILD) test \
	  -project $(PROJECT) \
	  -scheme $(SCHEME) \
	  -destination '$(DESTINATION)' \
	  -derivedDataPath $(DERIVED_DATA)

warnings: generate
	@$(XCODEBUILD) build \
	  -project $(PROJECT) \
	  -scheme $(SCHEME) \
	  -destination '$(DESTINATION)' \
	  -derivedDataPath $(DERIVED_DATA) \
	  2>&1 | grep -Ei 'warning:|deprecated|obsoleted|will be removed' || echo "No warnings matched warning/deprecation filter."

sim-open:
	open -a Simulator

sim-boot:
	$(SIMCTL) boot "$(SIM_DEVICE)" || true

sim-install: build sim-boot
	$(SIMCTL) install booted $(APP_PATH)

sim-launch: sim-boot
	$(SIMCTL) launch booted $(BUNDLE_ID)

sim-run: sim-install sim-launch

sim-uninstall: sim-boot
	$(SIMCTL) uninstall booted $(BUNDLE_ID) || true

clean:
	$(XCODEBUILD) clean \
	  -project $(PROJECT) \
	  -scheme $(SCHEME) \
	  -destination '$(DESTINATION)' \
	  -derivedDataPath $(DERIVED_DATA) || true
	rm -rf $(DERIVED_DATA)

reset: clean sim-uninstall
