import Foundation

// Preset gauge range modes for the analog speedometer.
// Each mode defines a maximum speed value the gauge will display.
// "auto" dynamically scales based on the current/recent speed.
enum SpeedRange: String, CaseIterable, Identifiable {
    case auto
    case walk
    case bike
    case city
    case highway

    var id: Self { self }

    // Short user-facing label for the picker.
    var label: String {
        switch self {
        case .auto: return "Auto"
        case .walk: return "Walk"
        case .bike: return "Bike"
        case .city: return "City"
        case .highway: return "Hwy"
        }
    }

    // Returns the gauge max for the given unit.
    // For .auto, callers should compute the max separately based on current speed.
    func maxValue(for unit: SpeedUnit) -> Double {
        switch (self, unit) {
        case (.walk, .mph): return 10
        case (.walk, .kph): return 15
        case (.bike, .mph): return 30
        case (.bike, .kph): return 50
        case (.city, .mph): return 60
        case (.city, .kph): return 100
        case (.highway, .mph): return 120
        case (.highway, .kph): return 200
        case (.auto, _): return 60  // sensible fallback if used directly
        }
    }

    // Auto-mode: pick the smallest preset whose max is comfortably above currentSpeed.
    // Adds 30% headroom so the needle isn't pinned at the top.
    static func autoMax(forCurrentSpeed speed: Double, unit: SpeedUnit) -> Double {
        let candidates: [SpeedRange] = [.walk, .bike, .city, .highway]
        let needed = speed * 1.3
        for range in candidates {
            if range.maxValue(for: unit) >= needed {
                return range.maxValue(for: unit)
            }
        }
        return SpeedRange.highway.maxValue(for: unit)
    }
}
