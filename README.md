# Speedometer

Simple native iPhone speedometer app built with SwiftUI and Core Location.

## What It Does

- Shows current speed as a large live number alongside an analog gauge.
- Lets you start and stop tracking.
- Lets you switch between MPH and KPH.
- Uses locale measurement defaults on first launch.
- Lets you choose the gauge's max range, with an Auto mode that scales to your current speed.

## Configuration Options

The app exposes two pickers above the Start/Stop button. Both selections are remembered between launches.

### Units

Toggle between **MPH** and **KPH**. The default follows your device locale on first launch.

### Gauge Range

Choose how high the analog dial reads. Tick spacing adapts automatically to the chosen range.

| Preset | MPH range | KPH range | Use case |
| ------ | --------- | --------- | -------- |
| Auto   | dynamic   | dynamic   | Default. Picks the smallest preset that comfortably fits your current speed (with ~30% headroom). |
| Walk   | 0–10      | 0–15      | Walking, jogging. |
| Bike   | 0–30      | 0–50      | Cycling, scooters. |
| City   | 0–60      | 0–100     | Surface-street driving. |
| Hwy    | 0–120     | 0–200     | Highway / motorway driving. |

Auto mode is the recommended default — leave it on and the gauge will rescale itself as you speed up or slow down.

### Speed Smoothing

Raw GPS speed is noisy, so the displayed value is filtered:

- An exponential moving average (alpha = 0.5) smooths out jitter while staying responsive to changes.
- When the raw GPS speed drops below ~1 mph the displayed value snaps to 0 immediately, so the needle returns to rest as soon as you stop.

These values live in `LocationSpeedManager.swift` if you want to tune them.

## Prerequisites

- macOS with full Xcode installed.
- Xcode first-launch setup completed.
- Homebrew with XcodeGen installed.

Install XcodeGen:

	brew install xcodegen

## CLI Workflow (Recommended)

This repo includes a Makefile so you can build, test, and run from terminal.

Show all commands:

	make help

Typical daily flow:

	make doctor
	make build
	make test
	make sim-run

Useful targets:

- make generate: Generate Speedometer.xcodeproj from project.yml.
- make build: Build for default simulator device.
- make build-clean: Clean and build.
- make test: Run unit tests.
- make warnings: Print warning and deprecation lines from build output.
- make sim-run: Build, install, and launch in simulator.
- make sim-uninstall: Remove app from booted simulator.
- make clean: Remove derived data artifacts.
- make reset: Clean build artifacts and uninstall simulator app.

Override simulator target when needed:

	make build SIM_DEVICE="iPhone 17"

or

	make build DESTINATION="platform=iOS Simulator,name=iPhone 17"

## Xcode UI (Optional)

If you want to open in Xcode:

	make open-xcode

For first-time physical-device signing, Xcode UI is usually easiest.

## Notes About Testing

- Simulator is useful for UI and permission flow.
- Real speed readings require a physical iPhone.
- GPS speed is most reliable outdoors.

## Project Structure

- project.yml: XcodeGen source of truth for project configuration.
- Makefile: Standard command interface for build/test/run automation.
- Speedometer/: App source and assets.
- SpeedometerTests/: Unit tests.