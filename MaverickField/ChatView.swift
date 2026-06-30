import SwiftUI
import PhotosUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isBusy = false
    @Published var mode: WorkflowMode = .ask
    @Published var attachments: [Attachment] = []
    @Published var pendingEstimate: PendingEstimate? = nil
    @Published var showVoicePanel = false
    @Published var showJobHistory = false
    @Published var showSaveDialog = false
    @Published var saveLabel = ""
    @Published var errorMessage: String? = nil

    private var streamTask: Task<Void, Never>?
    private(set) var service: MCCService
    var speech: SpeechManager?

    init(settings: AppSettings) {
        self.service = MCCService(settings: settings)
        loadLastSession()
    }

    // MARK: - Send

    func send(text: String? = nil) {
        let prompt = (text ?? inputText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, !isBusy else { return }
        inputText = ""
        let userMsg = ChatMessage(role: .user, content: prompt)
        let assistantMsg = ChatMessage(role: .assistant, content: "")
        messages.append(userMsg)
        messages.append(assistantMsg)
        let msgSnapshot = messages
        let attSnapshot = attachments
        let estimateSnapshot = pendingEstimate
        attachments = []
        isBusy = true
        errorMessage = nil

        streamTask = Task {
            var accumulated = ""
            do {
                let stream = service.streamChat(
                    prompt: prompt,
                    mode: mode,
                    history: msgSnapshot,
                    attachments: attSnapshot,
                    pendingEstimate: estimateSnapshot
                )
                for try await token in stream {
                    accumulated += token
                    if let idx = messages.indices.last {
                        messages[idx].content = accumulated
                    }
                    saveSession()
                }
                // Detect estimate block
                let (clean, estimate) = service.extractEstimate(from: accumulated)
                if let estimate {
                    if let idx = messages.indices.last {
                        messages[idx].content = clean
                    }
                    pendingEstimate = estimate
                }
                saveSession()
            } catch {
                if let idx = messages.indices.last {
                    messages[idx].content = "[Error: \(error.localizedDescription)]"
                }
            }
            isBusy = false

            // TTS if voice panel open
            if showVoicePanel, let last = messages.last(where: { $0.role == .assistant }),
               let speech {
                speech.speak(last.content)
            }
        }
    }

    func stop() {
        streamTask?.cancel()
        streamTask = nil
        isBusy = false
        speech?.stopSpeaking()
    }

    // MARK: - Estimate

    func buildEstimate() {
        guard let est = pendingEstimate, !isBusy else { return }
        pendingEstimate = nil
        let buildMsg = ChatMessage(role: .user, content: "⚡ Build estimate")
        let assistantMsg = ChatMessage(role: .assistant, content: "")
        messages.append(buildMsg)
        messages.append(assistantMsg)
        isBusy = true

        streamTask = Task {
            var accumulated = ""
            do {
                let customer = APICustomer(name: est.customerName, email: est.customerEmail, phone: est.customerPhone)
                let stream = service.buildEstimate(
                    lineItems: est.lineItems,
                    newPricebookItems: est.newPricebookItems,
                    customer: customer,
                    techIds: est.techIds,
                    depositPercent: est.depositPercent
                )
                for try await token in stream {
                    accumulated += token
                    if let idx = messages.indices.last {
                        messages[idx].content = accumulated
                    }
                }
                saveSession()
            } catch {
                if let idx = messages.indices.last {
                    messages[idx].content = "[Error: \(error.localizedDescription)]"
                }
            }
            isBusy = false
        }
    }

    // MARK: - Jobs

    func saveCurrentJob() {
        guard !messages.isEmpty else { return }
        let job = SavedJob(label: saveLabel.isEmpty ? "Untitled Job" : saveLabel,
                           messages: messages, mode: mode)
        PersistenceManager.shared.saveJob(job)
        saveLabel = ""
    }

    func loadJob(_ job: SavedJob) {
        stop()
        messages = job.messages
        mode = job.mode
        pendingEstimate = nil
        attachments = []
        saveSession()
    }

    func clearChat() {
        stop()
        messages = []
        pendingEstimate = nil
        attachments = []
        saveSession()
    }

    // MARK: - Session persistence (last open chat)

    private let sessionKey = "mav_last_session"

    private func saveSession() {
        if let data = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(data, forKey: sessionKey)
        }
    }

    private func loadLastSession() {
        guard let data = UserDefaults.standard.data(forKey: sessionKey),
              let msgs = try? JSONDecoder().decode([ChatMessage].self, from: data) else { return }
        messages = msgs
    }
}

// MARK: - ChatView

struct ChatView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var speech: SpeechManager
    @StateObject private var vm: ChatViewModel
    @State private var photoItem: PhotosPickerItem? = nil
    @FocusState private var inputFocused: Bool
    @State private var scrollProxy: ScrollViewProxy? = nil

    init() {
        // Using a workaround since @EnvironmentObject isn't available in init
        // ChatViewModel is created in onAppear
        _vm = StateObject(wrappedValue: ChatViewModel(settings: AppSettings()))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(hex: "#0a0d14").ignoresSafeArea()

                VStack(spacing: 0) {
                    modeStrip
                    messagesArea
                    if let est = vm.pendingEstimate {
                        EstimateBarView(estimate: est,
                                        isBusy: vm.isBusy,
                                        onBuild: { vm.buildEstimate() },
                                        onDismiss: { vm.pendingEstimate = nil })
                    }
                    inputBar
                }

                if vm.showVoicePanel {
                    VoicePanelView(
                        vm: vm,
                        onClose: { vm.showVoicePanel = false }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(isPresented: $vm.showJobHistory) {
                JobHistoryView(onLoad: { job in
                    vm.loadJob(job)
                    vm.showJobHistory = false
                })
            }
            .alert("Save Job", isPresented: $vm.showSaveDialog) {
                TextField("Job label", text: $vm.saveLabel)
                Button("Save") { vm.saveCurrentJob(); vm.clearChat() }
                Button("Cancel", role: .cancel) { vm.clearChat() }
            } message: {
                Text("Give this job a name before clearing (optional)")
            }
        }
        .onAppear {
            vm.speech = speech
            vm.service = MCCService(settings: settings)
        }
    }

    // MARK: - Mode strip

    private var modeStrip: some View {
        HStack(spacing: 6) {
            ForEach(WorkflowMode.allCases) { m in
                Button(m.label) {
                    guard !vm.isBusy else { return }
                    vm.mode = m
                }
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(vm.mode == m ? .black : Color(hex: "#8b93a7"))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(vm.mode == m ? modeColor(m) : Color(hex: "#161c2b"))
                .cornerRadius(8)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(hex: "#0e1320"))
    }

    // MARK: - Messages

    private var messagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if vm.messages.isEmpty {
                        emptyState
                    } else {
                        ForEach(vm.messages) { msg in
                            MessageBubble(message: msg, isBusy: vm.isBusy && msg == vm.messages.last)
                                .id(msg.id)
                        }
                    }
                }
                .padding(12)
            }
            .onChange(of: vm.messages.count) { _, _ in
                if let last = vm.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .onChange(of: vm.messages.last?.content) { _, _ in
                if let last = vm.messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("◈")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "#d9a441"))
            Text("MAVERICK READY")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "#e8ebf2"))
            Text("Select a mode and send your first message")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#8b93a7"))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    // MARK: - Input bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            // Attachment chips
            if !vm.attachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(vm.attachments) { att in
                            AttachmentChip(attachment: att) {
                                vm.attachments.removeAll { $0.id == att.id }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .background(Color(hex: "#0e1320"))
            }

            HStack(alignment: .bottom, spacing: 8) {
                // Photo attach
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Image(systemName: "camera.fill")
                        .foregroundColor(Color(hex: "#8b93a7"))
                        .frame(width: 36, height: 36)
                        .background(Color(hex: "#161c2b"))
                        .cornerRadius(8)
                }
                .onChange(of: photoItem) { _, item in
                    Task { await loadPhoto(item) }
                }

                // Text input
                TextField("", text: $vm.inputText, axis: .vertical)
                    .placeholder(when: vm.inputText.isEmpty) {
                        Text(vm.isBusy ? "Maverick is responding…" : "Message Maverick…")
                            .foregroundColor(Color(hex: "#5a6275"))
                    }
                    .foregroundColor(Color(hex: "#e8ebf2"))
                    .font(.system(size: 15))
                    .lineLimit(1...5)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#161c2b"))
                    .cornerRadius(10)
                    .focused($inputFocused)
                    .disabled(vm.isBusy)
                    .onSubmit { vm.send() }

                // Voice / Send / Stop
                if vm.isBusy {
                    Button { vm.stop() } label: {
                        Image(systemName: "stop.fill")
                            .foregroundColor(.red)
                            .frame(width: 36, height: 36)
                            .background(Color(hex: "#1c2436"))
                            .cornerRadius(8)
                    }
                } else {
                    Button {
                        if vm.inputText.trimmingCharacters(in: .whitespaces).isEmpty {
                            vm.showVoicePanel.toggle()
                        } else {
                            vm.send()
                        }
                    } label: {
                        Image(systemName: vm.inputText.isEmpty ? "mic.fill" : "arrow.up.circle.fill")
                            .foregroundColor(vm.inputText.isEmpty ? Color(hex: "#8b93a7") : Color(hex: "#d9a441"))
                            .font(.system(size: 22))
                            .frame(width: 36, height: 36)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(hex: "#0e1320"))
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            HStack(spacing: 6) {
                Circle()
                    .fill(modeColor(vm.mode))
                    .frame(width: 8, height: 8)
                Text(vm.mode.label)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "#e8ebf2"))
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 12) {
                if !vm.messages.isEmpty {
                    Button {
                        if vm.messages.isEmpty {
                            vm.clearChat()
                        } else {
                            vm.showSaveDialog = true
                        }
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(Color(hex: "#8b93a7"))
                    }
                }
                Button { vm.showJobHistory = true } label: {
                    Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                        .foregroundColor(Color(hex: "#8b93a7"))
                }
            }
        }
    }

    // MARK: - Helpers

    private func modeColor(_ m: WorkflowMode) -> Color {
        switch m {
        case .ask:   return .cyan
        case .agent: return .purple
        case .ops:   return .green
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            let att = Attachment(name: "photo.jpg", type: .image(data, "image/jpeg"))
            vm.attachments.append(att)
        }
        photoItem = nil
    }
}

// MARK: - MessageBubble

struct MessageBubble: View {
    let message: ChatMessage
    let isBusy: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(message.role == .user ? "CMD" : "MAV")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(message.role == .user ? Color(hex: "#5b9dff") : Color(hex: "#d9a441"))
                .padding(.top, 2)
                .frame(width: 32, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                if message.content.isEmpty && isBusy {
                    Text("▋")
                        .foregroundColor(Color(hex: "#d9a441"))
                        .font(.system(size: 15))
                } else {
                    Text(message.content)
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "#e8ebf2"))
                        .textSelection(.enabled)
                }
            }
            Spacer(minLength: 20)

            if message.role == .assistant && !message.content.isEmpty {
                Button {
                    UIPasteboard.general.string = message.content
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#5a6275"))
                }
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - AttachmentChip

struct AttachmentChip: View {
    let attachment: Attachment
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            if case .image(let data, _) = attachment.type,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: "paperclip")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#8b93a7"))
            }
            Text(attachment.name)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#e8ebf2"))
                .lineLimit(1)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "#5a6275"))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color(hex: "#1c2436"))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#252d40"), lineWidth: 1))
    }
}

// MARK: - Placeholder modifier

extension View {
    func placeholder<Content: View>(when shouldShow: Bool, @ViewBuilder content: () -> Content) -> some View {
        ZStack(alignment: .leading) {
            if shouldShow { content() }
            self
        }
    }
}
