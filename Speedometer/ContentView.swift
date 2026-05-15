import CoreLocation
import SwiftUI

// Main screen UI for the app.
// It binds directly to LocationSpeedManager so the view updates live.
struct ContentView: View {
    // `@StateObject` keeps one manager instance alive for this screen lifecycle.
    @StateObject private var speedManager = LocationSpeedManager()

    var body: some View {
        ZStack {
            // Full-screen gradient background.
            LinearGradient(
                colors: [Color(red: 0.07, green: 0.1, blue: 0.18), Color(red: 0.14, green: 0.18, blue: 0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                // Static heading so the user knows what this number represents.
                Text("Speed")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))

                VStack(spacing: 10) {
                    // Live speed value from the manager, formatted to one decimal place.
                    Text(String(format: "%.1f", speedManager.displaySpeed))
                        .font(.system(size: 110, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)

                    // Current speed unit (MPH/KPH).
                    Text(speedManager.selectedUnit.label)
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))
                }

                // Dynamic helper text (permission state, GPS quality, etc.).
                Text(speedManager.statusMessage)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)

                Spacer()

                // Unit toggle. This updates `selectedUnit` in real time.
                Picker("Units", selection: $speedManager.selectedUnit) {
                    ForEach(SpeedUnit.allCases) { unit in
                        Text(unit.label).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Primary action button alternates Start/Stop based on tracking state.
                Button(action: primaryAction) {
                    Text(speedManager.isTracking ? "Stop" : "Start")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .foregroundStyle(Color(red: 0.07, green: 0.1, blue: 0.18))
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .disabled(speedManager.needsSettings)
                .padding(.horizontal)

                // If permission was denied, expose a direct route to iOS Settings.
                if speedManager.needsSettings {
                    Button("Open Settings") {
                        speedManager.openSettings()
                    }
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                }
            }
            .padding(.vertical, 36)
        }
    }

    // Keeps button wiring simple and readable.
    private func primaryAction() {
        if speedManager.isTracking {
            speedManager.stopTracking()
        } else {
            speedManager.startTracking()
        }
    }
}

// Preview used only by Xcode canvas during development.
#Preview {
    ContentView()
}