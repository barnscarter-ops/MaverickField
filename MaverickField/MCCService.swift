import Foundation

class MCCService {
    private let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
    }

    // MARK: - Streaming chat

    func streamChat(
        prompt: String,
        mode: WorkflowMode,
        history: [ChatMessage],
        attachments: [Attachment] = [],
        pendingEstimate: PendingEstimate? = nil
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let url = URL(string: "\(self.settings.serverURL)/api/chat") else {
                        throw URLError(.badURL)
                    }
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.timeoutInterval = 120

                    let apiHistory = history.dropLast().map {
                        APIChatMessage(role: $0.role.rawValue, content: $0.content)
                    }

                    let apiAttachments: [APIAttachment]? = attachments.isEmpty ? nil : attachments.map { att in
                        switch att.type {
                        case .text(let content):
                            return APIAttachment(name: att.name, type: nil, content: content, data: nil, mimeType: nil)
                        case .image(let data, let mime):
                            return APIAttachment(name: att.name, type: "image", content: nil,
                                                 data: data.base64EncodedString(), mimeType: mime)
                        }
                    }

                    let body = ChatRequest(
                        prompt: prompt,
                        mode: mode.rawValue,
                        history: apiHistory,
                        attachments: apiAttachments,
                        pendingItems: pendingEstimate?.lineItems,
                        pendingCustomer: pendingEstimate.map {
                            APICustomer(name: $0.customerName, email: $0.customerEmail, phone: $0.customerPhone)
                        }
                    )
                    request.httpBody = try JSONEncoder().encode(body)

                    let (bytes, _) = try await URLSession.shared.bytes(for: request)
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))
                        if payload == "[DONE]" { break }
                        if let data = payload.data(using: .utf8),
                           let chunk = try? JSONDecoder().decode(SSEChunk.self, from: data),
                           let text = chunk.choices.first?.delta.content {
                            continuation.yield(text)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Build estimate

    func buildEstimate(
        lineItems: [LineItem],
        newPricebookItems: [NewPricebookItem]?,
        customer: APICustomer?,
        techIds: [String]?,
        depositPercent: Int?
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let url = URL(string: "\(self.settings.serverURL)/api/chat") else {
                        throw URLError(.badURL)
                    }
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.timeoutInterval = 120

                    let body = EstimateReadyRequest(
                        lineItems: lineItems,
                        newPricebookItems: newPricebookItems,
                        pendingCustomer: customer,
                        techIds: techIds,
                        depositPercent: depositPercent
                    )
                    request.httpBody = try JSONEncoder().encode(body)

                    let (bytes, _) = try await URLSession.shared.bytes(for: request)
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))
                        if payload == "[DONE]" { break }
                        if let data = payload.data(using: .utf8),
                           let chunk = try? JSONDecoder().decode(SSEChunk.self, from: data),
                           let text = chunk.choices.first?.delta.content {
                            continuation.yield(text)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - File extraction

    func extractFile(name: String, base64: String) async throws -> String {
        guard let url = URL(string: "\(settings.serverURL)/api/extract-file") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["name": name, "data": base64]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: request)
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let text = json["text"] as? String {
            return text
        }
        return "[unreadable]"
    }

    // MARK: - Estimate parsing

    func extractEstimate(from text: String) -> (cleanText: String, estimate: PendingEstimate?) {
        guard let range = text.range(of: #"\[ESTIMATE_READY\]([\s\S]*?)\[\/ESTIMATE_READY\]"#,
                                      options: .regularExpression) else {
            return (text, nil)
        }
        let block = text[range]
        let jsonStart = block.index(block.startIndex, offsetBy: "[ESTIMATE_READY]".count)
        let jsonEnd = block.index(block.endIndex, offsetBy: -"[/ESTIMATE_READY]".count)
        let jsonStr = String(block[jsonStart..<jsonEnd])

        guard let jsonData = jsonStr.data(using: .utf8),
              let estimate = try? JSONDecoder().decode(PendingEstimate.self, from: jsonData) else {
            return (text, nil)
        }
        let clean = text.replacingCharacters(in: range, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        return (clean, estimate)
    }
}
