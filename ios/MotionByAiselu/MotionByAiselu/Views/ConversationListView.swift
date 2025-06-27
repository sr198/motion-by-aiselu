import SwiftUI

struct ConversationListView: View {
    @StateObject private var persistenceService = ConversationPersistenceService.shared
    @State private var conversations: [ConversationSummary] = []
    @State private var searchText = ""
    @State private var showingDeleteAlert = false
    @State private var conversationToDelete: ConversationSummary?
    @State private var isLoading = true
    
    let onNewChatTapped: (() -> Void)?
    
    init(onNewChatTapped: (() -> Void)? = nil) {
        self.onNewChatTapped = onNewChatTapped
    }
    
    var filteredConversations: [ConversationSummary] {
        if searchText.isEmpty {
            return conversations
        } else {
            return persistenceService.searchConversations(query: searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading conversations...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if conversations.isEmpty {
                    EmptyConversationsView(onNewChatTapped: onNewChatTapped)
                } else {
                    List {
                        ForEach(filteredConversations) { conversation in
                            NavigationLink(destination: ChatView(conversationId: conversation.id)) {
                                ConversationRowView(conversation: conversation)
                            }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("Delete", role: .destructive) {
                                        conversationToDelete = conversation
                                        showingDeleteAlert = true
                                    }
                                    
                                    Button("Export") {
                                        exportConversation(conversation)
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await refreshConversations()
                    }
                }
            }
            .navigationTitle("Conversations")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search conversations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Chat") {
                        onNewChatTapped?()
                    }
                }
            }
            .onAppear {
                loadConversations()
            }
            .alert("Delete Conversation", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let conversation = conversationToDelete {
                        deleteConversation(conversation)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this conversation? This action cannot be undone.")
            }
        }
    }
    
    private func loadConversations() {
        isLoading = true
        DispatchQueue.main.async {
            self.conversations = persistenceService.loadAllConversations()
            self.isLoading = false
        }
    }
    
    private func refreshConversations() async {
        await MainActor.run {
            self.conversations = persistenceService.loadAllConversations()
        }
    }
    
    private func deleteConversation(_ conversation: ConversationSummary) {
        persistenceService.deleteConversation(id: conversation.id)
        conversations.removeAll { $0.id == conversation.id }
        conversationToDelete = nil
    }
    
    private func exportConversation(_ conversation: ConversationSummary) {
        guard let chatSession = persistenceService.loadConversation(id: conversation.id) else {
            print("Failed to load conversation for export")
            return
        }
        
        if let fileURL = ConversationExporter.shared.exportConversation(conversation, chatSession: chatSession) {
            // Show share sheet
            let activityViewController = UIActivityViewController(
                activityItems: [fileURL],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                
                // For iPad
                if let popover = activityViewController.popoverPresentationController {
                    popover.sourceView = rootViewController.view
                    popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                
                rootViewController.present(activityViewController, animated: true)
            }
        }
    }
    
}

struct ConversationRowView: View {
    let conversation: ConversationSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(conversation.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(relativeDate(conversation.updatedAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if conversation.hasSOAPReport {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.blue)
                            Text("SOAP")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text("\(conversation.messageCount) messages")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if conversation.hasSOAPReport {
                HStack {
                    Image(systemName: "stethoscope")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("Contains SOAP Report")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct EmptyConversationsView: View {
    let onNewChatTapped: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Conversations")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start a new conversation to see it here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Start New Chat") {
                onNewChatTapped?()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


#Preview {
    ConversationListView()
}