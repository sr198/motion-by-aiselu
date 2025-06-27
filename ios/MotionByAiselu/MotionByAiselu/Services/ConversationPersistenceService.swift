import Foundation
import CoreData

class ConversationPersistenceService: ObservableObject {
    static let shared = ConversationPersistenceService()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ConversationDataModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private init() {}
    
    // MARK: - Save Context
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
    
    // MARK: - Conversation Management
    
    func saveConversation(_ chatSession: ChatSession) -> ConversationEntity {
        let conversation = ConversationEntity(context: context)
        conversation.id = chatSession.id
        conversation.createdAt = chatSession.createdAt
        conversation.updatedAt = chatSession.updatedAt
        conversation.messageCount = Int32(chatSession.messages.count)
        conversation.title = generateConversationTitle(from: chatSession)
        conversation.hasSOAPReport = chatSession.messages.contains { $0.messageType == .soapDraft || $0.messageType == .finalReport }
        
        // Save messages
        for message in chatSession.messages {
            let messageEntity = MessageEntity(context: context)
            messageEntity.id = message.id
            messageEntity.content = message.content
            messageEntity.isFromUser = message.isFromUser
            messageEntity.timestamp = message.timestamp
            messageEntity.messageType = message.messageType?.rawValue
            messageEntity.conversation = conversation
            
            // Save structured data if available
            if let structuredMessage = message.structuredMessage {
                do {
                    let data = try JSONEncoder().encode(structuredMessage)
                    messageEntity.structuredData = data
                } catch {
                    print("Failed to encode structured message: \(error)")
                }
            }
            
            // Save SOAP reports separately for better querying
            if let structuredMessage = message.structuredMessage,
               let soapReport = structuredMessage.soapReport {
                saveSOAPReport(soapReport, for: conversation)
            }
        }
        
        save()
        return conversation
    }
    
    func updateConversation(_ chatSession: ChatSession) {
        let request: NSFetchRequest<ConversationEntity> = ConversationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", chatSession.id as CVarArg)
        
        do {
            let conversations = try context.fetch(request)
            if let conversation = conversations.first {
                conversation.updatedAt = chatSession.updatedAt
                conversation.messageCount = Int32(chatSession.messages.count)
                conversation.title = generateConversationTitle(from: chatSession)
                conversation.hasSOAPReport = chatSession.messages.contains { $0.messageType == .soapDraft || $0.messageType == .finalReport }
                
                // Remove existing messages and add new ones
                if let existingMessages = conversation.messages {
                    for message in existingMessages {
                        context.delete(message as! NSManagedObject)
                    }
                }
                
                // Add current messages
                for message in chatSession.messages {
                    let messageEntity = MessageEntity(context: context)
                    messageEntity.id = message.id
                    messageEntity.content = message.content
                    messageEntity.isFromUser = message.isFromUser
                    messageEntity.timestamp = message.timestamp
                    messageEntity.messageType = message.messageType?.rawValue
                    messageEntity.conversation = conversation
                    
                    if let structuredMessage = message.structuredMessage {
                        do {
                            let data = try JSONEncoder().encode(structuredMessage)
                            messageEntity.structuredData = data
                        } catch {
                            print("Failed to encode structured message: \(error)")
                        }
                    }
                }
                
                save()
            }
        } catch {
            print("Failed to update conversation: \(error)")
        }
    }
    
    func loadConversation(id: UUID) -> ChatSession? {
        let request: NSFetchRequest<ConversationEntity> = ConversationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let conversations = try context.fetch(request)
            if let conversation = conversations.first {
                return convertToConversation(conversation)
            }
        } catch {
            print("Failed to load conversation: \(error)")
        }
        
        return nil
    }
    
    func loadAllConversations() -> [ConversationSummary] {
        let request: NSFetchRequest<ConversationEntity> = ConversationEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ConversationEntity.updatedAt, ascending: false)]
        
        do {
            let conversations = try context.fetch(request)
            return conversations.map { conversation in
                ConversationSummary(
                    id: conversation.id!,
                    title: conversation.title ?? "Untitled Conversation",
                    createdAt: conversation.createdAt!,
                    updatedAt: conversation.updatedAt!,
                    messageCount: Int(conversation.messageCount),
                    hasSOAPReport: conversation.hasSOAPReport
                )
            }
        } catch {
            print("Failed to load conversations: \(error)")
            return []
        }
    }
    
    func deleteConversation(id: UUID) {
        let request: NSFetchRequest<ConversationEntity> = ConversationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let conversations = try context.fetch(request)
            for conversation in conversations {
                context.delete(conversation)
            }
            save()
        } catch {
            print("Failed to delete conversation: \(error)")
        }
    }
    
    func searchConversations(query: String) -> [ConversationSummary] {
        let request: NSFetchRequest<ConversationEntity> = ConversationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "title CONTAINS[cd] %@ OR ANY messages.content CONTAINS[cd] %@", query, query)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ConversationEntity.updatedAt, ascending: false)]
        
        do {
            let conversations = try context.fetch(request)
            return conversations.map { conversation in
                ConversationSummary(
                    id: conversation.id!,
                    title: conversation.title ?? "Untitled Conversation",
                    createdAt: conversation.createdAt!,
                    updatedAt: conversation.updatedAt!,
                    messageCount: Int(conversation.messageCount),
                    hasSOAPReport: conversation.hasSOAPReport
                )
            }
        } catch {
            print("Failed to search conversations: \(error)")
            return []
        }
    }
    
    // MARK: - SOAP Report Management
    
    private func saveSOAPReport(_ soapReport: SOAPReport, for conversation: ConversationEntity) {
        let soapEntity = SOAPReportEntity(context: context)
        soapEntity.id = soapReport.id
        soapEntity.patientName = soapReport.patientName
        soapEntity.patientAge = soapReport.patientAge
        soapEntity.condition = soapReport.condition
        soapEntity.sessionDate = soapReport.sessionDate
        soapEntity.subjective = soapReport.subjective
        soapEntity.objective = soapReport.objective
        soapEntity.assessment = soapReport.assessment
        soapEntity.plan = soapReport.plan
        soapEntity.timestamp = soapReport.timestamp ?? ISO8601DateFormatter().string(from: Date())
        soapEntity.createdAt = Date()
        soapEntity.conversation = conversation
        
        // Save exercises
        for exercise in soapReport.exercises {
            let exerciseEntity = ExerciseEntity(context: context)
            exerciseEntity.id = exercise.id
            exerciseEntity.name = exercise.name
            exerciseEntity.exerciseDescription = exercise.description
            exerciseEntity.selectedImageURL = exercise.selectedImage
            exerciseEntity.soapReport = soapEntity
        }
    }
    
    func loadSOAPReports() -> [SOAPReportSummary] {
        let request: NSFetchRequest<SOAPReportEntity> = SOAPReportEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SOAPReportEntity.createdAt, ascending: false)]
        
        do {
            let reports = try context.fetch(request)
            return reports.map { report in
                SOAPReportSummary(
                    id: report.id!,
                    patientName: report.patientName,
                    condition: report.condition,
                    sessionDate: report.sessionDate,
                    createdAt: report.createdAt!,
                    conversationId: report.conversation!.id!
                )
            }
        } catch {
            print("Failed to load SOAP reports: \(error)")
            return []
        }
    }
    
    // MARK: - Helper Methods
    
    private func convertToConversation(_ entity: ConversationEntity) -> ChatSession {
        var chatSession = ChatSession()
        chatSession = ChatSession() // Reset with correct IDs
        
        // Convert messages
        if let messages = entity.messages?.allObjects as? [MessageEntity] {
            let sortedMessages = messages.sorted { $0.timestamp! < $1.timestamp! }
            
            for messageEntity in sortedMessages {
                var structuredMessage: StructuredMessage? = nil
                
                if let structuredData = messageEntity.structuredData {
                    do {
                        structuredMessage = try JSONDecoder().decode(StructuredMessage.self, from: structuredData)
                    } catch {
                        print("Failed to decode structured message: \(error)")
                    }
                }
                
                let message = ChatMessage(
                    content: messageEntity.content!,
                    isFromUser: messageEntity.isFromUser,
                    messageType: MessageType(rawValue: messageEntity.messageType ?? ""),
                    structuredMessage: structuredMessage
                )
                
                chatSession.messages.append(message)
            }
        }
        
        return chatSession
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
}

// MARK: - Supporting Models

struct ConversationSummary: Identifiable {
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

// MARK: - ChatMessage Extension for Persistence
extension ChatMessage {
    init(content: String, isFromUser: Bool, messageType: MessageType? = nil, structuredMessage: StructuredMessage? = nil) {
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = Date()
        self.messageType = messageType
        self.structuredMessage = structuredMessage
    }
}