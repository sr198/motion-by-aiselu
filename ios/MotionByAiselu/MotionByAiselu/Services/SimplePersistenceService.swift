import Foundation
import CoreData

// Simple in-memory conversation persistence until Core Data files are added to Xcode project
class ConversationPersistenceService: ObservableObject {
    static let shared = ConversationPersistenceService()
    
    private var conversations: [UUID: ChatSession] = [:]
    private var conversationSummaries: [ConversationSummary] = []
    
    private init() {
        // Only load sample data on first launch
        let userDefaults = UserDefaults.standard
        if !userDefaults.bool(forKey: "HasLoadedSampleData") {
            loadSampleData()
            userDefaults.set(true, forKey: "HasLoadedSampleData")
        }
    }
    
    // Mock Core Data context for compatibility
    var context: NSManagedObjectContext? {
        return nil
    }
    
    func saveConversation(_ chatSession: ChatSession) -> UUID {
        let id = chatSession.id
        conversations[id] = chatSession
        
        let summary = ConversationSummary(
            id: id,
            title: generateConversationTitle(from: chatSession),
            createdAt: chatSession.createdAt,
            updatedAt: chatSession.updatedAt,
            messageCount: chatSession.messages.count,
            hasSOAPReport: chatSession.messages.contains { $0.messageType == .soapDraft || $0.messageType == .finalReport }
        )
        
        // Update or add summary
        if let index = conversationSummaries.firstIndex(where: { $0.id == id }) {
            conversationSummaries[index] = summary
        } else {
            conversationSummaries.append(summary)
        }
        
        // Sort by update date
        conversationSummaries.sort { $0.updatedAt > $1.updatedAt }
        
        return id
    }
    
    func updateConversation(_ chatSession: ChatSession) {
        _ = saveConversation(chatSession)
    }
    
    func loadConversation(id: UUID) -> ChatSession? {
        return conversations[id]
    }
    
    func loadAllConversations() -> [ConversationSummary] {
        return conversationSummaries
    }
    
    func deleteConversation(id: UUID) {
        conversations.removeValue(forKey: id)
        conversationSummaries.removeAll { $0.id == id }
    }
    
    func searchConversations(query: String) -> [ConversationSummary] {
        return conversationSummaries.filter { summary in
            summary.title.localizedCaseInsensitiveContains(query) ||
            (conversations[summary.id]?.messages.contains { $0.content.localizedCaseInsensitiveContains(query) } ?? false)
        }
    }
    
    private func generateConversationTitle(from chatSession: ChatSession) -> String {
        // Try to find a meaningful title from the first user message
        let firstUserMessage = chatSession.messages.first { $0.isFromUser }?.content ?? ""
        
        if !firstUserMessage.isEmpty {
            // Take first 30 characters and clean up
            let title = String(firstUserMessage.prefix(30))
            return title.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Check if there's a SOAP report for a patient name
        let soapMessage = chatSession.messages.first { $0.messageType == .soapDraft || $0.messageType == .finalReport }
        if let patientName = soapMessage?.structuredMessage?.soapReport?.patientName,
           !patientName.isEmpty {
            return "Session with \(patientName)"
        }
        
        // Fallback to date-based title
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Chat \(formatter.string(from: chatSession.createdAt))"
    }
    
    private func loadSampleData() {
        // Sample conversation 1: General chat
        var chatSession1 = ChatSession()
        chatSession1.addUserMessage("Hello! What are the best exercises for lower back pain?")
        chatSession1.addAssistantMessage("Hello! For lower back pain, I recommend starting with gentle exercises that strengthen your core and improve flexibility. Here are some effective options:\n\n1. Cat-Cow stretches\n2. Knee-to-chest stretches\n3. Pelvic tilts\n4. Modified planks\n5. Bird dog exercises\n\nWould you like me to explain how to perform any of these exercises?")
        chatSession1.addUserMessage("Yes, please explain the cat-cow stretch.")
        chatSession1.addAssistantMessage("The Cat-Cow stretch is excellent for improving spinal mobility:\n\n1. Start on hands and knees in a tabletop position\n2. For 'Cow': Drop your belly, lift your chest and tailbone toward the ceiling\n3. For 'Cat': Round your spine toward the ceiling, tuck your chin to chest\n4. Move slowly between positions, holding each for 2-3 seconds\n5. Repeat 10-15 times\n\nThis exercise helps relieve tension and improves flexibility in your spine.")
        
        _ = saveConversation(chatSession1)
        
        // Sample conversation 2: SOAP report session
        var chatSession2 = ChatSession()
        chatSession2.addUserMessage("I just finished treating a patient with shoulder impingement. Sarah, 42 years old, complained of pain when reaching overhead, especially with lifting. Range of motion was limited in flexion and abduction. Positive impingement tests. I performed manual therapy and gave her pendulum exercises and wall slides.")
        chatSession2.addAssistantMessage("I've generated a SOAP report based on your patient session:")
        
        _ = saveConversation(chatSession2)
    }
}

// Simple export functionality
class ConversationExporter {
    static let shared = ConversationExporter()
    
    private init() {}
    
    func exportConversation(_ conversation: ConversationSummary, chatSession: ChatSession) -> URL? {
        let fileName = "\(conversation.title.replacingOccurrences(of: " ", with: "_"))_\(formatDate(conversation.createdAt)).txt"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        let exportContent = generateExportContent(conversation: conversation, chatSession: chatSession)
        
        do {
            try exportContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to export conversation: \(error)")
            return nil
        }
    }
    
    private func generateExportContent(conversation: ConversationSummary, chatSession: ChatSession) -> String {
        var content = """
        Conversation Export
        ==================
        
        Title: \(conversation.title)
        Created: \(formatDateTime(conversation.createdAt))
        Last Updated: \(formatDateTime(conversation.updatedAt))
        Message Count: \(conversation.messageCount)
        Has SOAP Report: \(conversation.hasSOAPReport ? "Yes" : "No")
        
        Messages
        --------
        
        """
        
        for message in chatSession.messages {
            let sender = message.isFromUser ? "User" : "Assistant"
            let timestamp = formatDateTime(message.timestamp)
            let messageType = message.messageType?.rawValue ?? "text"
            
            content += """
            [\(timestamp)] \(sender) (\(messageType))
            \(message.content)
            
            ---
            
            """
        }
        
        return content
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}