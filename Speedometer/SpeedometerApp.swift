import SwiftUI

// App entry point. iOS launches this type first.
// Think of this as the "main()" for SwiftUI apps.
@main
struct SpeedometerApp: App {
    var body: some Scene {
        // Single-window app scene that hosts our root view.
        WindowGroup {
            ContentView()
        }
    }
}