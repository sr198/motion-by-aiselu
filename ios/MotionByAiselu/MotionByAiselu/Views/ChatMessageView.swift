import SwiftUI

struct ChatMessageView: View {
    let message: ChatMessage
    
    var body: some View {
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
            MarkdownText(markdown: message.content)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(18)
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
}

// MARK: - Supporting Views

struct FinalReportView: View {
    let content: String
    let selectedImages: [String]
    let onExportPDF: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Final SOAP Report")
                .font(.headline)
                .fontWeight(.bold)
            
            MarkdownText(markdown: content)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            
            if !selectedImages.isEmpty {
                Text("Selected Images: \\(selectedImages.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Spacer()
                
                Button(action: onExportPDF) {
                    HStack {
                        Image(systemName: "doc.fill")
                        Text("Export as PDF")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
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
            message: ChatMessage(content: "# SOAP Report\\n\\n## Subjective\\n- Patient reports lower back pain\\n- 7/10 intensity", isFromUser: false, messageType: .soapDraft)
        )
    }
    .padding()
}