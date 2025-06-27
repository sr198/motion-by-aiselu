import Foundation

// MARK: - Conversation Persistence Models

struct ConversationSummary: Identifiable, Codable {
    let id: UUID
    let title: String
    let createdAt: Date
    let updatedAt: Date
    let messageCount: Int
    let hasSOAPReport: Bool
}

struct SOAPReportSummary: Identifiable {
    let id: UUID
    let patientName: String?
    let condition: String?
    let sessionDate: String?
    let createdAt: Date
    let conversationId: UUID
}

// MARK: - Export Data Models

struct ConversationExportData: Codable {
    let conversation: ConversationSummary
    let messages: [ExportMessage]
    let exportedAt: Date
    
    init(conversation: ConversationSummary, messages: [ExportMessage]) {
        self.conversation = conversation
        self.messages = messages
        self.exportedAt = Date()
    }
}

struct ExportMessage: Codable {
    let id: UUID
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    let messageType: String?
    let structuredData: Data?
    
    init(from chatMessage: ChatMessage) {
        self.id = chatMessage.id
        self.content = chatMessage.content
        self.isFromUser = chatMessage.isFromUser
        self.timestamp = chatMessage.timestamp
        self.messageType = chatMessage.messageType?.rawValue
        
        if let structuredMessage = chatMessage.structuredMessage {
            self.structuredData = try? JSONEncoder().encode(structuredMessage)
        } else {
            self.structuredData = nil
        }
    }
}

// MARK: - Chat Message
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    let messageType: MessageType?
    let structuredMessage: StructuredMessage?
    
    init(content: String, isFromUser: Bool, messageType: MessageType? = nil) {
        self.id = UUID()
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = Date()
        self.messageType = messageType
        self.structuredMessage = nil
    }
    
    init(from structuredMessage: StructuredMessage) {
        self.id = UUID()
        self.content = structuredMessage.content ?? ""
        self.isFromUser = false
        self.timestamp = ISO8601DateFormatter().date(from: structuredMessage.timestamp) ?? Date()
        self.messageType = structuredMessage.type
        self.structuredMessage = structuredMessage
    }
}

// MARK: - Chat Session
struct ChatSession: Identifiable, Codable {
    let id: UUID
    var messages: [ChatMessage]
    let createdAt: Date
    var updatedAt: Date
    
    init() {
        self.id = UUID()
        self.messages = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    mutating func addMessage(_ message: ChatMessage) {
        messages.append(message)
        updatedAt = Date()
    }
    
    mutating func addUserMessage(_ content: String) {
        let message = ChatMessage(content: content, isFromUser: true)
        addMessage(message)
    }
    
    mutating func addAssistantMessage(_ content: String, messageType: MessageType = .chatMessage) {
        let message = ChatMessage(content: content, isFromUser: false, messageType: messageType)
        addMessage(message)
    }
    
    mutating func addStructuredMessage(_ structuredMessage: StructuredMessage) {
        let message = ChatMessage(from: structuredMessage)
        addMessage(message)
    }
}

// MARK: - Special Message States
enum SpecialMessageState {
    case none
    case waitingForImageSelection(ExerciseSelectionData)
    case finalReportReady(FinalReportData)
}

struct ExerciseSelectionData {
    let exercises: [Exercise]
}


struct FinalReportData {
    let soapReport: SOAPReport
    let selectedImages: [String]
}