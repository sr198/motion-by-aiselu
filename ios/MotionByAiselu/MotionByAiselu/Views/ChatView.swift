import SwiftUI

struct ChatView: View {
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var apiClient = APIClient()
    
    @State private var chatSession = ChatSession()
    @State private var currentInput = ""
    @State private var specialState: SpecialMessageState = .none
    @State private var selectedImages: Set<String> = []
    @State private var isProcessing = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Chat Messages
            chatMessagesView
            
            // Special UI based on state
            specialStateView
            
            // Input Area
            inputAreaView
        }
        .onReceive(apiClient.$lastMessage) { message in
            if let message = message {
                handleNewMessage(message)
            }
        }
        .onReceive(speechRecognizer.$transcript) { transcript in
            currentInput = transcript
        }
    }
    
    private var headerView: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Motion by Aiselu")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("AI Physiotherapy Assistant")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: startNewSession) {
                    Image(systemName: "plus.bubble")
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            Divider()
        }
        .background(Color(.systemBackground))
    }
    
    private var chatMessagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if chatSession.messages.isEmpty {
                        welcomeMessageView
                    } else {
                        ForEach(chatSession.messages) { message in
                            ChatMessageView(message: message)
                                .id(message.id)
                        }
                    }
                }
                .padding()
            }
            .onChange(of: chatSession.messages.count) {
                if let lastMessage = chatSession.messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var welcomeMessageView: some View {
        VStack(spacing: 16) {
            Image(systemName: "stethoscope")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Welcome to Motion by Aiselu")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("I'm your AI physiotherapy assistant. You can ask me questions about treatments, exercises, conditions, or dictate patient sessions for SOAP report generation.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 50)
    }
    
    @ViewBuilder
    private var specialStateView: some View {
        switch specialState {
        case .none:
            EmptyView()
        case .waitingForImageSelection(let data):
            ExerciseSelectionView(
                exerciseName: data.exerciseName,
                exerciseDescription: data.exerciseDescription,
                images: data.images,
                selectedImages: $selectedImages,
                onContinue: handleImageSelection
            )
            .padding()
            .background(Color(.systemGray6))
        case .waitingForClarification(let data):
            ClarificationView(
                questions: data.questions,
                onRespond: handleClarificationResponse
            )
            .padding()
            .background(Color(.systemGray6))
        case .finalReportReady(let data):
            FinalReportView(
                content: data.content,
                selectedImages: data.selectedImages,
                onExportPDF: exportToPDF
            )
            .padding()
            .background(Color(.systemGray6))
        }
    }
    
    private var inputAreaView: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // Text Input
                HStack(alignment: .bottom) {
                    TextField("Type your message or tap mic to speak...", text: $currentInput, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(2...6)
                        .frame(minHeight: 40)
                        .multilineTextAlignment(.leading)
                        .submitLabel(.send)
                        .onSubmit {
                            if !currentInput.isEmpty {
                                sendMessage()
                            }
                        }
                    
                    if !currentInput.isEmpty {
                        Button(action: clearInput) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                
                // Voice/Send Button
                Button(action: handleInputAction) {
                    if speechRecognizer.isRecording {
                        Image(systemName: "stop.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    } else if !currentInput.isEmpty {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    } else {
                        Image(systemName: "mic.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .disabled(isProcessing)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Recording indicator or error
            if speechRecognizer.isRecording {
                HStack {
                    Image(systemName: "waveform")
                        .foregroundColor(.red)
                    Text("Recording... Tap to stop")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(.bottom, 8)
            } else if let error = speechRecognizer.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    Text("Speech error: \(error.localizedDescription)")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(.bottom, 8)
            }
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Actions
    
    private func startNewSession() {
        chatSession = ChatSession()
        specialState = .none
        selectedImages.removeAll()
        currentInput = ""
        speechRecognizer.stopRecording()
    }
    
    private func clearInput() {
        currentInput = ""
        speechRecognizer.stopRecording()
    }
    
    private func handleInputAction() {
        if speechRecognizer.isRecording {
            speechRecognizer.stopRecording()
        } else if !currentInput.isEmpty {
            sendMessage()
        } else {
            speechRecognizer.startRecording()
        }
    }
    
    private func sendMessage() {
        guard !currentInput.isEmpty && !isProcessing else { return }
        
        let messageContent = currentInput
        currentInput = ""
        speechRecognizer.stopRecording()
        
        // Add user message to chat
        chatSession.addUserMessage(messageContent)
        
        // Send to API
        isProcessing = true
        Task {
            await apiClient.processTranscript(messageContent)
            await MainActor.run {
                isProcessing = false
            }
        }
    }
    
    private func handleNewMessage(_ message: StructuredMessage) {
        switch message.type {
        case .chatMessage:
            chatSession.addAssistantMessage(message.content ?? "", messageType: .chatMessage)
            specialState = .none
            
        case .soapDraft:
            chatSession.addAssistantMessage("I've generated a SOAP report based on your patient session:", messageType: .soapDraft)
            chatSession.addAssistantMessage(message.content ?? "", messageType: .soapDraft)
            specialState = .none
            
        case .exerciseSelection:
            let data = ExerciseSelectionData(
                exerciseName: message.exerciseName ?? "",
                exerciseDescription: message.exerciseDescription ?? "",
                images: message.images ?? []
            )
            chatSession.addAssistantMessage("Please select exercise illustrations for \(data.exerciseName):", messageType: .exerciseSelection)
            specialState = .waitingForImageSelection(data)
            selectedImages.removeAll()
            
        case .finalReport:
            let data = FinalReportData(
                content: message.content ?? "",
                selectedImages: message.selectedImages ?? []
            )
            chatSession.addAssistantMessage("Here's your final SOAP report with selected images:", messageType: .finalReport)
            specialState = .finalReportReady(data)
            
        case .clarificationNeeded:
            let data = ClarificationData(
                questions: message.questions ?? [],
                originalContent: message.originalContent ?? ""
            )
            chatSession.addAssistantMessage("I need some clarification to complete the SOAP report:", messageType: .clarificationNeeded)
            specialState = .waitingForClarification(data)
            
        case .error:
            chatSession.addAssistantMessage("I encountered an error: \(message.error ?? "Unknown error")", messageType: .error)
            specialState = .none
        }
    }
    
    private func handleImageSelection() {
        specialState = .none
        Task {
            await apiClient.submitImageSelection(Array(selectedImages))
        }
    }
    
    private func handleClarificationResponse(_ responses: [String]) {
        specialState = .none
        
        // Add user responses to chat
        let responseText = responses.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
        chatSession.addUserMessage(responseText)
        
        Task {
            await apiClient.submitClarificationResponses(responses)
        }
    }
    
    private func exportToPDF() {
        // TODO: Implement PDF export functionality
        print("Export to PDF requested")
    }
}

#Preview {
    ChatView()
}