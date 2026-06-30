import Foundation
import Combine

class AppSettings: ObservableObject {
    @Published var serverURL: String {
        didSet { UserDefaults.standard.set(serverURL, forKey: "mcc_server_url") }
    }
    @Published var voiceEnabled: Bool {
        didSet { UserDefaults.standard.set(voiceEnabled, forKey: "voice_enabled") }
    }
    @Published var speakerEnabled: Bool {
        didSet { UserDefaults.standard.set(speakerEnabled, forKey: "speaker_enabled") }
    }
    @Published var voiceRate: Float {
        didSet { UserDefaults.standard.set(voiceRate, forKey: "voice_rate") }
    }

    init() {
        self.serverURL = UserDefaults.standard.string(forKey: "mcc_server_url") ?? "http://carterspc:3011"
        self.voiceEnabled = UserDefaults.standard.bool(forKey: "voice_enabled")
        self.speakerEnabled = UserDefaults.standard.object(forKey: "speaker_enabled") as? Bool ?? true
        self.voiceRate = UserDefaults.standard.object(forKey: "voice_rate") as? Float ?? 1.05
    }
}
