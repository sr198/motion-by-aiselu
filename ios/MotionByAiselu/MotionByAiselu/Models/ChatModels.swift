import Foundation

// MARK: - Chat Message
struct ChatMessage: Identifiable, Codable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    let messageType: MessageType?
    
    init(content: String, isFromUser: Bool, messageType: MessageType? = nil) {
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = Date()
        self.messageType = messageType
    }
    
    init(from structuredMessage: StructuredMessage) {
        self.content = structuredMessage.content ?? ""
        self.isFromUser = false
        self.timestamp = ISO8601DateFormatter().date(from: structuredMessage.timestamp) ?? Date()
        self.messageType = structuredMessage.type
    }
}

// MARK: - Chat Session
struct ChatSession: Identifiable, Codable {
    let id = UUID()
    var messages: [ChatMessage]
    let createdAt: Date
    var updatedAt: Date
    
    init() {
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
}

// MARK: - Special Message States
enum SpecialMessageState {
    case none
    case waitingForImageSelection(ExerciseSelectionData)
    case waitingForClarification(ClarificationData)
    case finalReportReady(FinalReportData)
}

struct ExerciseSelectionData {
    let exerciseName: String
    let exerciseDescription: String
    let images: [ExerciseImage]
}

struct ClarificationData {
    let questions: [String]
    let originalContent: String
}

struct FinalReportData {
    let content: String
    let selectedImages: [String]
}