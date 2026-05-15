import CoreLocation
import Foundation

// Supported display units for speed.
enum SpeedUnit: String, CaseIterable, Identifiable {
    case mph
    case kph

    // Required by Identifiable so SwiftUI can diff Picker rows.
    var id: Self { self }

    // User-facing label shown in the UI.
    var label: String {
        rawValue.uppercased()
    }

    // Converts Core Location speed (m/s) into the selected display unit.
    func converted(fromMetersPerSecond speed: CLLocationSpeed) -> Double {
        switch self {
        case .mph:
            return speed * 2.236_936_292_1
        case .kph:
            return speed * 3.6
        }
    }

    // Picks an initial default from the user's locale measurement system.
    // Users can still switch units manually in the app.
    static func defaultForCurrentLocale(_ locale: Locale = .current) -> SpeedUnit {
        switch locale.measurementSystem {
        case .metric:
            return .kph
        default:
            return .mph
        }
    }
}