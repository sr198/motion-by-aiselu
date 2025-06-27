import SwiftUI

struct ChatView: View {
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var apiClient = APIClient()
    @StateObject private var persistenceService = ConversationPersistenceService.shared
    
    @State private var chatSession = ChatSession()
    @State private var currentInput = ""
    @State private var specialState: SpecialMessageState = .none
    @State private var selectedImages: Set<String> = []
    @State private var isProcessing = false
    @State private var isNewConversation = true
    
    // Voice settings
    @State private var autoStopTimeout: TimeInterval = 5.0
    
    // Conversation persistence
    private let conversationId: UUID?
    
    init(conversationId: UUID? = nil) {
        self.conversationId = conversationId
    }
    
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
        .onReceive(speechRecognizer.$autoStoppedRecording) { autoStopped in
            if autoStopped {
                print("ChatView: Auto-stop detected, sending message")
                sendMessage()
            }
        }
        .onAppear {
            // Sync timeout setting
            speechRecognizer.silenceTimeout = autoStopTimeout
            
            // Load existing conversation if ID provided
            if let conversationId = conversationId {
                loadExistingConversation(id: conversationId)
            } else {
                isNewConversation = true
            }
        }
        .onChange(of: autoStopTimeout) { _, newTimeout in
            speechRecognizer.silenceTimeout = newTimeout
        }
    }
    
    private var headerView: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Motion")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("AI Physiotherapy Assistant")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Voice settings button
                Menu {
                    Picker("Auto-stop timeout", selection: $autoStopTimeout) {
                        Text("3 seconds").tag(3.0)
                        Text("5 seconds").tag(5.0)
                        Text("7 seconds").tag(7.0)
                        Text("10 seconds").tag(10.0)
                    }
                } label: {
                    Image(systemName: "gear")
                        .font(.title2)
                }
                
                Button(action: saveAndStartNewSession) {
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
            // Full screen exercise selection
            ExerciseSelectionView(
                exercises: data.exercises,
                selectedImages: $selectedImages,
                onContinue: handleImageSelection
            )
            .background(Color(.systemBackground))
            .ignoresSafeArea(.container, edges: [.bottom])
        case .finalReportReady:
            // Final reports are now handled as regular chat messages
            EmptyView()
        }
    }
    
    private var inputAreaView: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // Text Input
                HStack(alignment: .bottom) {
                    TextField("Tap mic to speak (auto-stops after silence) or type...", text: $currentInput, axis: .vertical)
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
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: "waveform")
                            .foregroundColor(.red)
                        Text("Recording... Auto-stops after \(Int(autoStopTimeout))s of silence")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    if speechRecognizer.hasDetectedSpeech {
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(.orange)
                                .font(.caption2)
                            Text("Silence timer active - speak or tap to stop")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(.bottom, 8)
            } else if speechRecognizer.autoStoppedRecording {
                HStack {
                    Image(systemName: "timer.circle")
                        .foregroundColor(.green)
                    Text("Auto-stopped after silence - sending message...")
                        .font(.caption)
                        .foregroundColor(.green)
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
    
    private func clearInput() {
        currentInput = ""
        speechRecognizer.stopRecording(autoStopped: false)
    }
    
    private func handleInputAction() {
        if speechRecognizer.isRecording {
            // Manual stop - we'll send the message manually
            speechRecognizer.stopRecording(autoStopped: false)
            sendMessage()
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
        
        // Auto-save conversation after user message
        saveConversationIfNeeded()
        
        // Send to API
        isProcessing = true
        Task {
            await apiClient.processTranscript(messageContent)
            await MainActor.run {
                isProcessing = false
                // Auto-save after API response
                saveConversationIfNeeded()
            }
        }
    }
    
    private func handleNewMessage(_ message: StructuredMessage) {
        switch message.type {
        case .chatMessage:
            chatSession.addAssistantMessage(message.content ?? "", messageType: .chatMessage)
            specialState = .none
            
        case .soapDraft:
            chatSession.addAssistantMessage("I've generated a SOAP report based on your patient session:")
            chatSession.addStructuredMessage(message)
            specialState = .none
            
        case .exerciseSelection:
            let data = ExerciseSelectionData(
                exercises: message.exercises ?? []
            )
            chatSession.addAssistantMessage("Please select exercise illustrations for your SOAP report:", messageType: .exerciseSelection)
            specialState = .waitingForImageSelection(data)
            selectedImages.removeAll()
            
        case .finalReport:
            // Add final report as a structured message - no special state needed
            chatSession.addStructuredMessage(message)
            specialState = .none
            
        case .clarificationNeeded:
            // Handle clarification as a normal chat message
            let questions = message.questions ?? []
            let clarificationText = questions.isEmpty ? 
                (message.content ?? "I need some additional information to proceed.") :
                "I need some clarification:\n\n" + questions.map { "• \($0)" }.joined(separator: "\n")
            
            chatSession.addAssistantMessage(clarificationText, messageType: .chatMessage)
            specialState = .none
            
        case .error:
            chatSession.addAssistantMessage("I encountered an error: \(message.error ?? "Unknown error")", messageType: .error)
            specialState = .none
        }
        
        // Auto-save after each message update
        saveConversationIfNeeded()
    }
    
    private func handleImageSelection() {
        specialState = .none
        Task {
            await apiClient.submitImageSelection(Array(selectedImages))
        }
    }
    
    
    private func exportToPDF() {
        // TODO: Implement PDF export functionality
        print("Export to PDF requested")
    }
    
    private func createFallbackSOAPReport(from content: String) -> SOAPReport {
        // Create a basic SOAP report structure from plain text content
        return SOAPReport(
            patientName: nil,
            patientAge: nil,
            condition: "Unknown",
            sessionDate: nil,
            subjective: "Report content not available in structured format",
            objective: content.isEmpty ? "No data available" : content,
            assessment: "Assessment not available",
            plan: "Plan not available",
            exercises: [],
            timestamp: ISO8601DateFormatter().string(from: Date())
        )
    }
    
    // MARK: - Conversation Persistence
    
    private func loadExistingConversation(id: UUID) {
        if let existingSession = persistenceService.loadConversation(id: id) {
            chatSession = existingSession
            isNewConversation = false
        }
    }
    
    private func saveConversationIfNeeded() {
        // Only save if we have messages
        guard !chatSession.messages.isEmpty else { return }
        
        if isNewConversation {
            // Save new conversation
            _ = persistenceService.saveConversation(chatSession)
            isNewConversation = false
        } else {
            // Update existing conversation
            persistenceService.updateConversation(chatSession)
        }
    }
    
    private func saveAndStartNewSession() {
        // Save current conversation if it has content
        if !chatSession.messages.isEmpty {
            saveConversationIfNeeded()
        }
        
        // Start fresh
        startNewSession()
    }
    
    private func startNewSession() {
        chatSession = ChatSession()
        specialState = .none
        selectedImages.removeAll()
        currentInput = ""
        speechRecognizer.stopRecording(autoStopped: false)
        isNewConversation = true
    }
}

#Preview {
    ChatView()
}
