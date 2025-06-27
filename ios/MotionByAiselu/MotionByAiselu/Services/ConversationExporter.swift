import Foundation
import UIKit

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
    
    func exportConversationAsJSON(_ conversation: ConversationSummary, chatSession: ChatSession) -> URL? {
        let fileName = "\(conversation.title.replacingOccurrences(of: " ", with: "_"))_\(formatDate(conversation.createdAt)).json"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        let exportData = ConversationExportData(
            conversation: conversation,
            messages: chatSession.messages.map { ExportMessage(from: $0) }
        )
        
        do {
            let jsonData = try JSONEncoder().encode(exportData)
            try jsonData.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to export conversation as JSON: \(error)")
            return nil
        }
    }
    
    func shareConversation(_ conversation: ConversationSummary, chatSession: ChatSession, from viewController: UIViewController) {
        guard let fileURL = exportConversation(conversation, chatSession: chatSession) else {
            print("Failed to create export file")
            return
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )
        
        // For iPad
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        viewController.present(activityViewController, animated: true)
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
            
            """
            
            // Add structured data if available
            if let structuredMessage = message.structuredMessage {
                content += "Structured Data:\n"
                if let soapReport = structuredMessage.soapReport {
                    content += formatSOAPReport(soapReport)
                }
                if let exercises = structuredMessage.exercises {
                    content += formatExercises(exercises)
                }
                content += "\n"
            }
            
            content += "---\n\n"
        }
        
        return content
    }
    
    private func formatSOAPReport(_ soapReport: SOAPReport) -> String {
        return """
        SOAP Report:
        Patient: \(soapReport.patientName ?? "N/A")
        Age: \(soapReport.patientAge ?? "N/A")
        Condition: \(soapReport.condition ?? "N/A")
        Session Date: \(soapReport.sessionDate ?? "N/A")
        
        Subjective: \(soapReport.subjective)
        Objective: \(soapReport.objective)
        Assessment: \(soapReport.assessment)
        Plan: \(soapReport.plan)
        
        Exercises:
        \(soapReport.exercises.map { "- \($0.name): \($0.description)" }.joined(separator: "\n"))
        
        """
    }
    
    private func formatExercises(_ exercises: [Exercise]) -> String {
        return """
        Exercises:
        \(exercises.map { exercise in
            let imageCount = exercise.images.count
            return "- \(exercise.name): \(exercise.description) (\(imageCount) images available)"
        }.joined(separator: "\n"))
        
        """
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

// MARK: - ConversationSummary Codable Extension

extension ConversationSummary: Codable {
    enum CodingKeys: String, CodingKey {
        case id, title, createdAt, updatedAt, messageCount, hasSOAPReport
    }
}