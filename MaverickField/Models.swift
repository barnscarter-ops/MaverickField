import Foundation

// MARK: - Workflow modes

enum WorkflowMode: String, CaseIterable, Identifiable, Codable {
    case ask   = "ask"
    case agent = "agent"
    case ops   = "ops"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .ask:   return "ASK MAVERICK"
        case .agent: return "MAVERICK"
        case .ops:   return "OPERATIONS"
        }
    }

    var tooltip: String {
        switch self {
        case .ask:   return "Ask anything, scope jobs, and build estimates"
        case .agent: return "Field assistant — schedule, job details, code questions"
        case .ops:   return "Personal assistant — emails, docs, spreadsheets"
        }
    }

    var accentColor: String {
        switch self {
        case .ask:   return "cyan"
        case .agent: return "purple"
        case .ops:   return "green"
        }
    }
}

// MARK: - Chat

struct ChatMessage: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var role: MessageRole
    var content: String
    var timestamp: Date = Date()

    enum MessageRole: String, Codable {
        case user, assistant
    }
}

// MARK: - Attachments

struct Attachment: Identifiable {
    let id = UUID()
    var name: String
    var type: AttachmentType

    enum AttachmentType {
        case text(String)
        case image(Data, String) // data, mimeType
    }
}

// MARK: - Estimates

struct PendingEstimate: Codable {
    var lineItems: [LineItem]
    var newPricebookItems: [NewPricebookItem]?
    var customerName: String?
    var customerPhone: String?
    var customerEmail: String?
    var techIds: [String]?
    var depositPercent: Int?

    var totalItems: Int { lineItems.count + (newPricebookItems?.count ?? 0) }
}

struct LineItem: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var quantity: Double
    var unitPrice: Double
    var type: String   // "matched" | "adjusted" | "new"
    var serviceItemId: String?

    var total: Double { quantity * unitPrice }

    private enum CodingKeys: String, CodingKey {
        case name, quantity, unitPrice, type, serviceItemId
    }
}

struct NewPricebookItem: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var description: String?
    var category: String?
    var unitPrice: Double
    var quantity: Double
    var saveToBook: Bool?

    var total: Double { quantity * unitPrice }

    private enum CodingKeys: String, CodingKey {
        case name, description, category, unitPrice, quantity, saveToBook
    }
}

// MARK: - Job history

struct SavedJob: Identifiable, Codable {
    var id: String
    var label: String
    var preview: String
    var savedAt: Date
    var messages: [ChatMessage]
    var mode: WorkflowMode

    enum CodingKeys: String, CodingKey {
        case id, label, preview, savedAt, messages, mode
    }

    init(id: String = UUID().uuidString, label: String, messages: [ChatMessage], mode: WorkflowMode) {
        self.id = id
        self.label = label
        self.preview = messages.first(where: { $0.role == .user })?.content.prefix(80).description ?? ""
        self.savedAt = Date()
        self.messages = Array(messages.suffix(40))
        self.mode = mode
    }
}

// MARK: - Field tools

struct CounterItem: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var count: Int = 0
}

// MARK: - API wire types

struct ChatRequest: Encodable {
    var prompt: String
    var mode: String
    var history: [APIChatMessage]
    var attachments: [APIAttachment]?
    var pendingItems: [LineItem]?
    var pendingCustomer: APICustomer?
}

struct EstimateReadyRequest: Encodable {
    var prompt: String = "Build estimate"
    var mode: String = "estimate-ready"
    var lineItems: [LineItem]
    var newPricebookItems: [NewPricebookItem]?
    var pendingCustomer: APICustomer?
    var techIds: [String]?
    var depositPercent: Int?
}

struct APIChatMessage: Encodable {
    var role: String
    var content: String
}

struct APIAttachment: Encodable {
    var name: String
    var type: String?
    var content: String?
    var data: String?
    var mimeType: String?
}

struct APICustomer: Encodable {
    var name: String?
    var email: String?
    var phone: String?
}

struct SSEChunk: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable {
            var content: String?
        }
        var delta: Delta
    }
    var choices: [Choice]
}
