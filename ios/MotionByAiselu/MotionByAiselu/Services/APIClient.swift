import Foundation
import Combine

@MainActor
class APIClient: ObservableObject {
    @Published var lastMessage: StructuredMessage?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let baseURL: String
    private let session = URLSession.shared
    private var currentSessionId: String?
    
    // Configuration
    private let appName = "soap_agents"
    private let userId = "user" // In production, this would be user-specific
    
    init(baseURL: String = "http://localhost:8000") {
        self.baseURL = baseURL
    }
    
    // MARK: - Public Methods
    
    func processTranscript(_ transcript: String) async {
        isLoading = true
        error = nil
        
        print("APIClient: Processing transcript: \(transcript)")
        print("APIClient: Base URL: \(baseURL)")
        
        do {
            // Create or get session
            let sessionId = try await getOrCreateSession()
            print("APIClient: Using session ID: \(sessionId)")
            
            // Send transcript to agent
            let request = AgentRunRequest(
                appName: appName,
                userId: userId,
                sessionId: sessionId,
                newMessage: MessageContent(text: transcript),
                streaming: false
            )
            
            print("APIClient: Sending request to: \(baseURL)/run")
            let response = try await sendAgentRequest(request)
            await parseAgentResponse(response)
            
        } catch {
            self.error = error
            print("Error processing transcript: \(error)")
            print("Error details: \(error.localizedDescription)")
            if let apiError = error as? APIError {
                print("API Error type: \(apiError)")
            }
        }
        
        isLoading = false
    }
    
    func submitImageSelection(_ selectedImageIds: [String]) async {
        guard let sessionId = currentSessionId else {
            error = APIError.noActiveSession
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let selectionData = ImageSelectionRequest(selectedImageIds: selectedImageIds)
            let jsonData = try JSONEncoder().encode(selectionData)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            
            let request = AgentRunRequest(
                appName: appName,
                userId: userId,
                sessionId: sessionId,
                newMessage: MessageContent(text: jsonString),
                streaming: false
            )
            
            let response = try await sendAgentRequest(request)
            await parseAgentResponse(response)
            
        } catch {
            self.error = error
            print("Error submitting image selection: \(error)")
        }
        
        isLoading = false
    }
    
    func submitClarificationResponses(_ responses: [String]) async {
        guard let sessionId = currentSessionId else {
            error = APIError.noActiveSession
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let clarificationData = ClarificationResponseRequest(responses: responses)
            let jsonData = try JSONEncoder().encode(clarificationData)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            
            let request = AgentRunRequest(
                appName: appName,
                userId: userId,
                sessionId: sessionId,
                newMessage: MessageContent(text: jsonString),
                streaming: false
            )
            
            let response = try await sendAgentRequest(request)
            await parseAgentResponse(response)
            
        } catch {
            self.error = error
            print("Error submitting clarification responses: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func getOrCreateSession() async throws -> String {
        if let existingSessionId = currentSessionId {
            return existingSessionId
        }
        
        let sessionId = UUID().uuidString
        let url = URL(string: "\(baseURL)/apps/\(appName)/users/\(userId)/sessions/\(sessionId)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw APIError.sessionCreationFailed
        }
        
        currentSessionId = sessionId
        return sessionId
    }
    
    private func sendAgentRequest(_ request: AgentRunRequest) async throws -> APIResponse {
        let url = URL(string: "\(baseURL)/run")!
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestData = try JSONEncoder().encode(request)
        urlRequest.httpBody = requestData
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("APIClient: HTTP Status: \(httpResponse.statusCode)")
        print("APIClient: Response headers: \(httpResponse.allHeaderFields)")
        
        if httpResponse.statusCode != 200 {
            let responseString = String(data: data, encoding: .utf8) ?? "No response body"
            print("APIClient: Error response body: \(responseString)")
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let responseString = String(data: data, encoding: .utf8) ?? "No response body"
        print("APIClient: Response body: \(responseString)")
        
        // ADK returns array of events directly, not wrapped in APIResponse
        let events = try JSONDecoder().decode([AgentEvent].self, from: data)
        return APIResponse(events: events, error: nil)
    }
    
    private func parseAgentResponse(_ response: APIResponse) async {
        guard let events = response.events else {
            if let error = response.error {
                self.lastMessage = StructuredMessage(
                    type: .error,
                    timestamp: ISO8601DateFormatter().string(from: Date()),
                    content: nil,
                    format: nil,
                    exerciseName: nil,
                    exerciseDescription: nil,
                    images: nil,
                    requiresSelection: nil,
                    selectedImages: nil,
                    readyForPdf: nil,
                    questions: nil,
                    originalContent: nil,
                    error: error,
                    details: nil
                )
            }
            return
        }
        
        // Process events to find structured messages
        for event in events {
            if let content = event.content,
               let parts = content.parts,
               let firstPart = parts.first {
                
                let messageText = firstPart.text
                print("APIClient: Processing event content: \(messageText)")
                
                // Check if content contains JSON structure (starts with ```json)
                if messageText.contains("```json") {
                    // Extract JSON from markdown code block
                    let lines = messageText.components(separatedBy: .newlines)
                    var jsonLines: [String] = []
                    var inJsonBlock = false
                    
                    for line in lines {
                        if line.contains("```json") {
                            inJsonBlock = true
                            continue
                        } else if line.contains("```") && inJsonBlock {
                            break
                        } else if inJsonBlock {
                            jsonLines.append(line)
                        }
                    }
                    
                    let jsonString = jsonLines.joined(separator: "\n")
                    print("APIClient: Extracted JSON: \(jsonString)")
                    
                    if let jsonData = jsonString.data(using: .utf8) {
                        do {
                            let message = try JSONDecoder().decode(StructuredMessage.self, from: jsonData)
                            self.lastMessage = message
                            return
                        } catch {
                            print("APIClient: Failed to parse structured message: \(error)")
                        }
                    }
                }
                
                // Fallback: treat as plain chat message
                self.lastMessage = StructuredMessage(
                    type: .chatMessage,
                    timestamp: ISO8601DateFormatter().string(from: Date()),
                    content: messageText,
                    format: nil,
                    exerciseName: nil,
                    exerciseDescription: nil,
                    images: nil,
                    requiresSelection: nil,
                    selectedImages: nil,
                    readyForPdf: nil,
                    questions: nil,
                    originalContent: nil,
                    error: nil,
                    details: nil
                )
                return
            }
        }
    }
}

// MARK: - API Errors
enum APIError: LocalizedError {
    case invalidResponse
    case sessionCreationFailed
    case noActiveSession
    case httpError(Int)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .sessionCreationFailed:
            return "Failed to create session"
        case .noActiveSession:
            return "No active session"
        case .httpError(let code):
            return "HTTP error: \\(code)"
        case .decodingError(let error):
            return "Decoding error: \\(error.localizedDescription)"
        }
    }
}