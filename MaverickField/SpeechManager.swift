import Foundation
import Speech
import AVFoundation
import Combine

class SpeechManager: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    @Published var isListening = false
    @Published var transcript = ""
    @Published var isSpeaking = false
    @Published var authStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let synthesizer = AVSpeechSynthesizer()
    private var silenceTimer: Timer?
    var onFinalTranscript: ((String) -> Void)?

    override init() {
        super.init()
        recognizer?.delegate = self
        synthesizer.delegate = self
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async { self?.authStatus = status }
        }
    }

    // MARK: - STT

    func startListening() {
        guard authStatus == .authorized, !isListening else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let request = recognitionRequest else { return }
            request.shouldReportPartialResults = true

            let inputNode = audioEngine.inputNode
            recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
                guard let self else { return }
                if let result {
                    let text = result.bestTranscription.formattedString
                    DispatchQueue.main.async { self.transcript = text }
                    self.silenceTimer?.invalidate()
                    self.silenceTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                        self.commitTranscript()
                    }
                }
                if error != nil || (result?.isFinal ?? false) {
                    self.stopListening()
                }
            }

            let format = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buf, _ in
                self?.recognitionRequest?.append(buf)
            }
            audioEngine.prepare()
            try audioEngine.start()
            DispatchQueue.main.async { self.isListening = true }
        } catch {
            print("STT start error: \(error)")
        }
    }

    func stopListening() {
        silenceTimer?.invalidate()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        DispatchQueue.main.async {
            self.isListening = false
        }
    }

    private func commitTranscript() {
        let text = transcript
        transcript = ""
        stopListening()
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            DispatchQueue.main.async { self.onFinalTranscript?(text) }
        }
    }

    // MARK: - TTS

    func speak(_ text: String, rate: Float = 1.05) {
        let clean = text
            .replacingOccurrences(of: #"\[ESTIMATE_READY\][\s\S]*?\[\/ESTIMATE_READY\]"#,
                                   with: "", options: .regularExpression)
            .replacingOccurrences(of: #"```[\s\S]*?```"#, with: "code block.", options: .regularExpression)
            .replacingOccurrences(of: #"\*\*(.*?)\*\*"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"\*(.*?)\*"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"#{1,6} "#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        synthesizer.stopSpeaking(at: .immediate)
        let utt = AVSpeechUtterance(string: clean)
        utt.voice = AVSpeechSynthesisVoice(language: "en-US")
        utt.rate = rate
        synthesizer.speak(utt)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

extension SpeechManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = true }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false }
    }
}
