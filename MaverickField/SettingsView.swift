import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var speech: SpeechManager
    @State private var urlDraft = ""
    @State private var showConnectionTest = false
    @State private var connectionResult: String? = nil
    @State private var isTesting = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0a0d14").ignoresSafeArea()
                List {
                    serverSection
                    voiceSection
                    aboutSection
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: "#0e1320"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear { urlDraft = settings.serverURL }
    }

    // MARK: - Server

    private var serverSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("MCC Server URL")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#8b93a7"))
                TextField("http://carterspc:3011", text: $urlDraft)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(Color(hex: "#e8ebf2"))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                    .onSubmit { settings.serverURL = urlDraft }
                Text("Requires Tailscale active on this device")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#5a6275"))
            }
            .listRowBackground(Color(hex: "#0e1320"))

            HStack {
                Button("Save URL") {
                    settings.serverURL = urlDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "#d9a441"))
                .disabled(urlDraft == settings.serverURL)

                Spacer()

                Button {
                    testConnection()
                } label: {
                    if isTesting {
                        ProgressView().tint(Color(hex: "#d9a441"))
                    } else {
                        Text("Test Connection")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#5b9dff"))
                    }
                }
                .disabled(isTesting)
            }
            .listRowBackground(Color(hex: "#0e1320"))

            if let result = connectionResult {
                Text(result)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(result.hasPrefix("✅") ? .green : .red)
                    .listRowBackground(Color(hex: "#0e1320"))
            }
        } header: {
            sectionHeader("SERVER")
        }
    }

    // MARK: - Voice

    private var voiceSection: some View {
        Section {
            Toggle(isOn: $settings.voiceEnabled) {
                Label("Enable Voice Input", systemImage: "mic.fill")
                    .foregroundColor(Color(hex: "#e8ebf2"))
            }
            .tint(Color(hex: "#d9a441"))
            .listRowBackground(Color(hex: "#0e1320"))

            if settings.voiceEnabled {
                Toggle(isOn: $settings.speakerEnabled) {
                    Label("Speak Responses (TTS)", systemImage: "speaker.wave.2.fill")
                        .foregroundColor(Color(hex: "#e8ebf2"))
                }
                .tint(Color(hex: "#d9a441"))
                .listRowBackground(Color(hex: "#0e1320"))

                if settings.speakerEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Speech Rate")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#e8ebf2"))
                            Spacer()
                            Text(String(format: "%.2f×", settings.voiceRate))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color(hex: "#8b93a7"))
                        }
                        Slider(value: $settings.voiceRate, in: 0.4...1.6, step: 0.05)
                            .tint(Color(hex: "#d9a441"))
                        HStack {
                            Text("Slow")
                            Spacer()
                            Text("Fast")
                        }
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#5a6275"))
                    }
                    .listRowBackground(Color(hex: "#0e1320"))

                    if speech.authStatus != .authorized {
                        Label("Microphone/Speech permission required", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .listRowBackground(Color(hex: "#0e1320"))
                    }
                }
            }
        } header: {
            sectionHeader("VOICE")
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                    .foregroundColor(Color(hex: "#e8ebf2"))
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundColor(Color(hex: "#8b93a7"))
                    .font(.system(size: 14, design: .monospaced))
            }
            .listRowBackground(Color(hex: "#0e1320"))

            HStack {
                Text("Mode")
                    .foregroundColor(Color(hex: "#e8ebf2"))
                Spacer()
                Text("◈ MAVERICK FIELD")
                    .foregroundColor(Color(hex: "#d9a441"))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
            }
            .listRowBackground(Color(hex: "#0e1320"))
        } header: {
            sectionHeader("ABOUT")
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundColor(Color(hex: "#5a6275"))
    }

    private func testConnection() {
        isTesting = true
        connectionResult = nil
        let url = URL(string: urlDraft.trimmingCharacters(in: .whitespacesAndNewlines) + "/health")
            ?? URL(string: "http://invalid")!

        Task {
            do {
                var req = URLRequest(url: url, timeoutInterval: 5)
                req.httpMethod = "GET"
                let (_, response) = try await URLSession.shared.data(for: req)
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                await MainActor.run {
                    connectionResult = code == 200 ? "✅ Connected (\(code))" : "⚠️ Server responded with \(code)"
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    connectionResult = "❌ \(error.localizedDescription)"
                    isTesting = false
                }
            }
        }
    }
}
