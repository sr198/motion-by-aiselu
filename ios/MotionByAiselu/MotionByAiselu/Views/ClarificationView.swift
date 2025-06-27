import SwiftUI

// DEPRECATED: This view is no longer used.
// Clarifications are now handled as normal chat messages.
// This file exists only to prevent Xcode build errors.
// TODO: Remove this file from the Xcode project and delete it.

struct ClarificationView: View {
    let questions: [String]
    let onRespond: ([String]) -> Void
    
    var body: some View {
        Text("This view is deprecated")
            .foregroundColor(.secondary)
    }
}