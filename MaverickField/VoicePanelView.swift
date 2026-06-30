import SwiftUI

struct VoicePanelView: View {
    @ObservedObject var vm: ChatViewModel
    @EnvironmentObject private var speech: SpeechManager
    @EnvironmentObject private var settings: AppSettings
    let onClose: () -> Void

    var statusLabel: String {
        if vm.isBusy { return "⟳  Maverick thinking…" }
        if speech.isSpeaking { return "◈  Maverick speaking…" }
        if speech.isListening { return "🎙  Hearing you…" }
        return "●  Listening…"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color(hex: "#252d40"))
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            // Header
            HStack {
                Text(statusLabel)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(hex: "#8b93a7"))
                Spacer()
                HStack(spacing: 16) {
                    Button {
                        if speech.isSpeaking { speech.stopSpeaking() }
                    } label: {
                        Image(systemName: speech.isSpeaking ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .foregroundColor(speech.isSpeaking ? Color(hex: "#d9a441") : Color(hex: "#5a6275"))
                    }
                    Button {
                        if speech.isListening { speech.stopListening() } else { speech.startListening() }
                    } label: {
                        Image(systemName: speech.isListening ? "mic.slash.fill" : "mic.fill")
                            .foregroundColor(speech.isListening ? .cyan : Color(hex: "#5a6275"))
                    }
                    Button {
                        speech.stopListening()
                        speech.stopSpeaking()
                        onClose()
                    } label: {
                        Text("END")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().background(Color(hex: "#252d40"))

            // Transcript area
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(vm.messages.suffix(6)) { msg in
                        HStack(alignment: .top, spacing: 8) {
                            Text(msg.role == .user ? "YOU" : "MAV")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(msg.role == .user ? .cyan : Color(hex: "#d9a441"))
                                .frame(width: 28, alignment: .leading)
                            Text(msg.content.isEmpty ? "…" : msg.content)
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#e8ebf2"))
                        }
                    }
                    if !speech.transcript.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Text("YOU")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan.opacity(0.6))
                                .frame(width: 28, alignment: .leading)
                            Text(speech.transcript + "…")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#8b93a7"))
                                .italic()
                        }
                    }
                }
                .padding(16)
            }
            .frame(maxHeight: 200)

            // Estimate bar in voice mode
            if let est = vm.pendingEstimate {
                HStack {
                    Text("📋 \(est.totalItems) item\(est.totalItems == 1 ? "" : "s") ready")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#e8ebf2"))
                    Spacer()
                    Button("⚡ BUILD IT") {
                        vm.buildEstimate()
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#d9a441"))
                    .cornerRadius(8)
                    .disabled(vm.isBusy)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(hex: "#1c2436"))
            }
        }
        .background(Color(hex: "#0e1320"))
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.5), radius: 20, y: -4)
        .onAppear {
            speech.onFinalTranscript = { text in
                vm.send(text: text)
            }
            speech.startListening()
        }
        .onDisappear {
            speech.stopListening()
            speech.onFinalTranscript = nil
        }
    }
}

// MARK: - Corner radius helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
