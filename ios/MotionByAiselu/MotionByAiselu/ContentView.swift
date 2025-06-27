import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ChatView()
                .tabItem {
                    Image(systemName: "message")
                    Text("Chat")
                }
                .tag(0)
            
            ConversationListView(onNewChatTapped: {
                selectedTab = 0
            })
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("History")
                }
                .tag(1)
        }
    }
}

#Preview {
    ContentView()
}
