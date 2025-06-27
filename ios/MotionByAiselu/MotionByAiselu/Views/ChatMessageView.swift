import SwiftUI

struct ChatMessageView: View {
    let message: ChatMessage
    
    var body: some View {
        // Special handling for SOAP reports - they should take full width
        if message.messageType == .soapDraft || message.messageType == .finalReport {
            soapReportFullWidthView
        } else {
            HStack {
                if message.isFromUser {
                    Spacer(minLength: 50)
                    userMessageView
                } else {
                    assistantMessageView
                    Spacer(minLength: 50)
                }
            }
        }
    }
    
    private var userMessageView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(message.content)
                .font(.body)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.blue)
                .cornerRadius(18)
            
            Text(formatTime(message.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var assistantMessageView: some View {
        HStack(alignment: .top, spacing: 8) {
            // Assistant Avatar
            Image(systemName: "stethoscope")
                .font(.caption)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.green)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                // Message content with conditional rendering
                messageContentView
                
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var messageContentView: some View {
        switch message.messageType {
        case .soapDraft:
            // Always use structured SOAP report - no markdown fallback
            if let structuredMessage = message.structuredMessage,
               let soapReport = structuredMessage.soapReport {
                SOAPReportView(soapReport: soapReport)
            } else {
                // Error state - backend should always send structured data
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("SOAP Report Error")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                    Text("Expected structured SOAP data but received: \(message.content)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(18)
            }
        case .chatMessage, .none:
            Text(message.content)
                .font(.body)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(18)
        default:
            Text(message.content)
                .font(.body)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(18)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Full-width SOAP report view
    private var soapReportFullWidthView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with timestamp and assistant indicator
            HStack {
                Image(systemName: "stethoscope")
                    .font(.caption)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Color.green)
                    .clipShape(Circle())
                
                Text("SOAP Report Generated")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Full-width SOAP report
            if let structuredMessage = message.structuredMessage,
               let soapReport = structuredMessage.soapReport {
                SOAPReportView(soapReport: soapReport)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 8)
            } else {
                // Error state
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("SOAP Report Error")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                    Text("Expected structured SOAP data but received: \(message.content)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, 8)
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Supporting Views

struct FinalReportView: View {
    let soapReport: SOAPReport
    let selectedImages: [String]
    let onExportPDF: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Final SOAP Report")
                .font(.headline)
                .fontWeight(.bold)
            
            SOAPReportView(soapReport: soapReport)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ChatMessageView(
            message: ChatMessage(content: "Hello, I need help with a patient who has lower back pain.", isFromUser: true)
        )
        
        ChatMessageView(
            message: ChatMessage(content: "I'd be happy to help you with that patient. Could you tell me more about their symptoms, examination findings, and what treatment you provided?", isFromUser: false, messageType: .chatMessage)
        )
        
        ChatMessageView(
            message: ChatMessage(from: StructuredMessage(
                type: .soapDraft,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                content: "SOAP Report Content",
                format: nil,
                exerciseName: nil,
                exerciseDescription: nil,
                images: nil,
                exercises: nil,
                requiresSelection: nil,
                selectedImages: nil,
                readyForPdf: nil,
                soapReport: SOAPReport(
                    patientName: "John Smith",
                    patientAge: "45",
                    condition: "Lower back pain",
                    sessionDate: "2024-01-15",
                    subjective: "Chief complaint: Lower back pain, 7/10 intensity. Duration: 3 days.",
                    objective: "Range of motion: Limited lumbar flexion (50% normal). Positive straight leg raise test.",
                    assessment: "Clinical impression: Acute lumbar strain. Contributing factors include poor posture.",
                    plan: "Manual therapy: Soft tissue mobilization. Continue home exercises as prescribed.",
                    exercises: [
                        SimpleExercise(name: "Cat-cow stretches", description: "10 reps, 3x daily", selectedImage: nil)
                    ],
                    timestamp: ISO8601DateFormatter().string(from: Date())
                ),
                questions: nil,
                originalContent: nil,
                error: nil,
                details: nil
            ))
        )
    }
    .padding()
}
