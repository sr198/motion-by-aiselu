import SwiftUI

struct ClarificationView: View {
    let questions: [String]
    let onRespond: ([String]) -> Void
    
    @State private var responses: [String] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Clarification Needed")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("Please provide additional information to complete your SOAP report:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 16) {
                ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\\(index + 1). \\(question)")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        TextField("Your response", text: binding(for: index), axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(1...3)
                    }
                }
            }
            
            HStack {
                Spacer()
                
                Button("Submit Responses") {
                    onRespond(responses)
                }
                .buttonStyle(.borderedProminent)
                .disabled(responses.contains { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .onAppear {
            responses = Array(repeating: "", count: questions.count)
        }
    }
    
    private func binding(for index: Int) -> Binding<String> {
        Binding(
            get: { responses.indices.contains(index) ? responses[index] : "" },
            set: { 
                if responses.indices.contains(index) {
                    responses[index] = $0
                }
            }
        )
    }
}

#Preview {
    ClarificationView(
        questions: [
            "What was the patient's pain intensity on a scale of 0-10?",
            "How long has the patient been experiencing these symptoms?",
            "What activities aggravate the pain?",
            "What exercises or treatments did you provide during this session?"
        ],
        onRespond: { responses in
            print("Responses: \\(responses)")
        }
    )
    .padding()
}