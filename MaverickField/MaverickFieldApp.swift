import SwiftUI

@main
struct MaverickFieldApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var speech = SpeechManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(speech)
                .preferredColorScheme(.dark)
        }
    }
}
