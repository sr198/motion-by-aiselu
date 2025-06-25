import SwiftUI
import UIKit

struct SOAPReportView: View {
    let content: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("SOAP Report")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)
                
                MarkdownText(markdown: content)
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
            }
            .padding()
        }
    }
}

struct MarkdownText: UIViewRepresentable {
    let markdown: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.font = UIFont.systemFont(ofSize: 16)
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // Convert markdown to attributed string
        let attributedString = parseMarkdown(markdown)
        uiView.attributedText = attributedString
    }
    
    private func parseMarkdown(_ markdown: String) -> NSAttributedString {
        let mutableString = NSMutableAttributedString()
        let lines = markdown.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.isEmpty {
                // Empty line
                mutableString.append(NSAttributedString(string: "\\n"))
            } else if trimmedLine.hasPrefix("# ") {
                // H1 Header
                let text = String(trimmedLine.dropFirst(2))
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 24),
                    .foregroundColor: UIColor.label
                ]
                mutableString.append(NSAttributedString(string: text + "\\n\\n", attributes: attrs))
            } else if trimmedLine.hasPrefix("## ") {
                // H2 Header
                let text = String(trimmedLine.dropFirst(3))
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 20),
                    .foregroundColor: UIColor.label
                ]
                mutableString.append(NSAttributedString(string: text + "\\n", attributes: attrs))
            } else if trimmedLine.hasPrefix("### ") {
                // H3 Header
                let text = String(trimmedLine.dropFirst(4))
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 18),
                    .foregroundColor: UIColor.label
                ]
                mutableString.append(NSAttributedString(string: text + "\\n", attributes: attrs))
            } else if trimmedLine.hasPrefix("**") && trimmedLine.hasSuffix("**") && trimmedLine.count > 4 {
                // Bold text
                let text = String(trimmedLine.dropFirst(2).dropLast(2))
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 16),
                    .foregroundColor: UIColor.label
                ]
                mutableString.append(NSAttributedString(string: text + "\\n", attributes: attrs))
            } else if trimmedLine.hasPrefix("- ") {
                // Bullet point
                let text = "• " + String(trimmedLine.dropFirst(2))
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 16),
                    .foregroundColor: UIColor.label
                ]
                mutableString.append(NSAttributedString(string: text + "\\n", attributes: attrs))
            } else if trimmedLine.hasPrefix("  - ") {
                // Sub bullet point
                let text = "  ◦ " + String(trimmedLine.dropFirst(4))
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 16),
                    .foregroundColor: UIColor.secondaryLabel
                ]
                mutableString.append(NSAttributedString(string: text + "\\n", attributes: attrs))
            } else if trimmedLine.hasPrefix("*") && trimmedLine.hasSuffix("*") && !trimmedLine.hasPrefix("**") {
                // Italic text
                let text = String(trimmedLine.dropFirst(1).dropLast(1))
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.italicSystemFont(ofSize: 16),
                    .foregroundColor: UIColor.secondaryLabel
                ]
                mutableString.append(NSAttributedString(string: text + "\\n", attributes: attrs))
            } else {
                // Regular text
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 16),
                    .foregroundColor: UIColor.label
                ]
                mutableString.append(NSAttributedString(string: trimmedLine + "\\n", attributes: attrs))
            }
        }
        
        return mutableString
    }
}

#Preview {
    SOAPReportView(content: """
    # SOAP Report
    
    ## Subjective (S)
    - Chief complaint: Lower back pain, 7/10 intensity
    - Duration: 3 days
    - **Aggravating factors**: Sitting, bending forward
    - **Relieving factors**: Walking, lying down
    
    ## Objective (O)
    - Range of motion: Limited lumbar flexion (50% normal)
    - Strength: 4/5 hip flexors bilaterally
    - *Special tests*: Positive straight leg raise test
    
    ## Assessment (A)
    - Clinical impression: Acute lumbar strain
    - Contributing factors: Poor posture, prolonged sitting
    
    ## Plan (P)
    - Manual therapy: Soft tissue mobilization
    - Home exercises:
      - Cat-cow stretches: 10 reps, 3x daily
      - Bridges: 10 reps, 2x daily
    - Follow-up: 1 week
    """)
}