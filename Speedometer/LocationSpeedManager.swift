import CoreLocation
import Foundation
import UIKit

// `@MainActor` forces all reads/writes on this type onto the main thread.
// That matters because SwiftUI observes these properties for UI updates.
@MainActor
final class LocationSpeedManager: NSObject, ObservableObject {
    // Current iOS location-permission state (not determined, denied, authorized, etc.).
    @Published private(set) var authorizationStatus: CLAuthorizationStatus

    // Whether we are actively asking Core Location for updates right now.
    @Published private(set) var isTracking = false

    // Raw speed from Core Location in meters/second.
    // This is the base value we convert to MPH/KPH for display.
    @Published private(set) var speedInMetersPerSecond: CLLocationSpeed = 0

    // Exponential moving average of the speed to smooth out GPS jitter.
    // Updated each time we get a new location sample.
    private var smoothedSpeedInMetersPerSecond: CLLocationSpeed = 0

    // Smoothing factor for EMA (0.2 = 20% new value, 80% old value).
    // Lower = smoother/slower response, higher = more responsive/noisier.
    // 0.2 is a good balance for GPS data.
    private let smoothingAlpha: CLLocationSpeed = 0.2

    // User-facing helper text shown under the speed readout.
    // We update this as permission/tracking/GPS quality changes.
    @Published private(set) var statusMessage = "Tap Start to begin measuring your speed."

    // User-selected display unit. Default comes from the phone's locale.
    @Published var selectedUnit: SpeedUnit

    // Apple's location engine object that delivers permission and GPS callbacks.
    private let locationManager: CLLocationManager

    // Dependency-injected init makes this easier to test later.
    // In real app usage, defaults are CLLocationManager() and Locale.current.
    init(locationManager: CLLocationManager = CLLocationManager(), locale: Locale = .current) {
        self.locationManager = locationManager
        self.authorizationStatus = locationManager.authorizationStatus
        self.selectedUnit = SpeedUnit.defaultForCurrentLocale(locale)
        super.init()

        // Receive CLLocationManagerDelegate callbacks in this class.
        self.locationManager.delegate = self

        // Hint about expected movement type.
        // For a speedometer app, automotive-style updates are a good default.
        self.locationManager.activityType = .automotiveNavigation

        // Request high quality location since speed calculations depend on it.
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation

        // No minimum movement threshold; we want continuous updates.
        self.locationManager.distanceFilter = kCLDistanceFilterNone

        // Seed the first status message from the current permission state.
        refreshStatusMessage()
    }

    // Converts smoothed m/s to the selected unit and rounds to one decimal place for precision.
    var displaySpeed: Double {
        let converted = selectedUnit.converted(fromMetersPerSecond: smoothedSpeedInMetersPerSecond)
        return (converted * 10).rounded() / 10
    }

    // If permission is denied/restricted, the UI should offer a Settings shortcut
    // instead of pretending Start can work.
    var needsSettings: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    // Called by the Start button.
    // Behavior depends entirely on current iOS permission status.
    func startTracking() {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            // Permission already granted: start location stream immediately.
            isTracking = true
            statusMessage = "Waiting for a GPS reading..."
            locationManager.startUpdatingLocation()
        case .notDetermined:
            // First run: ask for permission. iOS will show a system dialog.
            statusMessage = "Allow location access so the app can measure your speed."
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // Cannot proceed until the user changes permissions in Settings.
            refreshStatusMessage()
        @unknown default:
            // Safety branch for future enum cases Apple may add.
            statusMessage = "Location access is unavailable right now."
        }
    }

    // Called by the Stop button and when permission is revoked mid-session.
    func stopTracking() {
        isTracking = false

        // Reset speed so the UI does not show stale motion after stopping.
        speedInMetersPerSecond = 0
        smoothedSpeedInMetersPerSecond = 0

        // Stop battery/GPS work.
        locationManager.stopUpdatingLocation()
        refreshStatusMessage()
    }

    // Opens iOS Settings directly on this app's page.
    // Used when user denied permission and wants to re-enable it.
    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        UIApplication.shared.open(url)
    }

    // Centralized status-message mapping so messaging stays consistent.
    private func refreshStatusMessage() {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            statusMessage = isTracking ? "Waiting for a GPS reading..." : "Tap Start to begin measuring your speed."
        case .notDetermined:
            statusMessage = "Tap Start and allow location access to measure your speed."
        case .denied, .restricted:
            statusMessage = "Location access is off. Enable it in Settings to measure speed."
        @unknown default:
            statusMessage = "Location access is unavailable right now."
        }
    }
}

// `@preconcurrency` avoids strict Swift 6 actor-isolation warnings for delegate APIs
// that were designed before modern concurrency annotations.
extension LocationSpeedManager: @preconcurrency CLLocationManagerDelegate {
    // Fired whenever permission changes (first prompt, settings changes, etc.).
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        // If permission is removed while tracking, shut down immediately.
        if isTracking,
           authorizationStatus != .authorizedAlways,
           authorizationStatus != .authorizedWhenInUse {
            stopTracking()
            return
        }

        refreshStatusMessage()
    }

    // Fired whenever Core Location has new location samples.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Ignore updates if we are not currently in tracking mode.
        // `locations.last` is the newest reading in this batch.
        guard isTracking, let location = locations.last else {
            return
        }

        // Reject clearly weak readings to reduce noisy speed spikes.
        // lower is better; >65m is too noisy for this simple app.
        guard location.horizontalAccuracy >= 0, location.horizontalAccuracy <= 65 else {
            statusMessage = "GPS signal is weak. Move to an open area for a better reading."
            return
        }

        // CLLocation speed is m/s and can be negative when unavailable.
        // Clamp to zero so the user never sees nonsense negatives.
        speedInMetersPerSecond = max(location.speed, 0)

        // Apply exponential moving average to smooth out GPS jitter.
        // Formula: smoothed = (alpha * raw) + (1 - alpha) * previous
        // This makes the display less jumpy while staying responsive.
        smoothedSpeedInMetersPerSecond = (smoothingAlpha * speedInMetersPerSecond) + ((1 - smoothingAlpha) * smoothedSpeedInMetersPerSecond)

        // Keep message simple: either actively tracking movement or waiting for movement.
        statusMessage = smoothedSpeedInMetersPerSecond > 0 ? "Tracking live speed." : "Move to begin measuring speed."
    }

    // Fired when Core Location fails (temporary system/location issue).
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        statusMessage = "Unable to update your location right now."
    }
}