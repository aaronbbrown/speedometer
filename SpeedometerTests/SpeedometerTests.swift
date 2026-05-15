import XCTest
@testable import Speedometer

// Basic unit tests for conversion behavior and locale defaults.
final class SpeedometerTests: XCTestCase {
    // 10 m/s should equal ~22.369 mph.
    func testMilesPerHourConversion() {
        XCTAssertEqual(SpeedUnit.mph.converted(fromMetersPerSecond: 10), 22.369_362_921, accuracy: 0.000_001)
    }

    // 10 m/s should equal exactly 36 kph.
    func testKilometersPerHourConversion() {
        XCTAssertEqual(SpeedUnit.kph.converted(fromMetersPerSecond: 10), 36, accuracy: 0.000_001)
    }

    // Locale defaults: US => mph, most metric locales => kph.
    func testDefaultUnitFollowsLocale() {
        XCTAssertEqual(SpeedUnit.defaultForCurrentLocale(Locale(identifier: "en_US")), .mph)
        XCTAssertEqual(SpeedUnit.defaultForCurrentLocale(Locale(identifier: "fr_FR")), .kph)
    }
}