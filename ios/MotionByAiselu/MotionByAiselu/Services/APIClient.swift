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
                    exercises: nil,
                    requiresSelection: nil,
                    selectedImages: nil,
                    readyForPdf: nil,
                    soapReport: nil,
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
                
                // Try to extract and parse JSON from the message
                if let structuredMessage = extractAndParseJSON(from: messageText) {
                    self.lastMessage = structuredMessage
                    return
                }
                
                // If no structured JSON found, check if this looks like a conversational response
                // to a SOAP message (like "I've generated a SOAP report...")
                if messageText.lowercased().contains("soap") || 
                   messageText.lowercased().contains("report") ||
                   messageText.lowercased().contains("exercise") {
                    // This might be a conversational wrapper - try to extract JSON from anywhere in the text
                    if let structuredMessage = findJSONAnywhere(in: messageText) {
                        self.lastMessage = structuredMessage
                        return
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
                    exercises: nil,
                    requiresSelection: nil,
                    selectedImages: nil,
                    readyForPdf: nil,
                    soapReport: nil,
                    questions: nil,
                    originalContent: nil,
                    error: nil,
                    details: nil
                )
                return
            }
        }
    }
    
    private func extractAndParseJSON(from text: String) -> StructuredMessage? {
        // First try to extract from ```json code blocks
        if text.contains("```json") {
            print("APIClient: Found ```json marker, attempting extraction")
            let lines = text.components(separatedBy: .newlines)
            var jsonLines: [String] = []
            var inJsonBlock = false
            
            for (index, line) in lines.enumerated() {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                print("APIClient: Line \(index): '\(trimmedLine)', inJsonBlock: \(inJsonBlock)")
                
                if trimmedLine.contains("```json") {
                    inJsonBlock = true
                    print("APIClient: Started JSON block at line \(index)")
                    continue
                } else if trimmedLine == "```" && inJsonBlock {
                    print("APIClient: Ended JSON block at line \(index)")
                    break
                } else if inJsonBlock {
                    jsonLines.append(line)
                }
            }
            
            let jsonString = jsonLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            print("APIClient: Extracted JSON from code block (\(jsonLines.count) lines): \(jsonString)")
            
            if !jsonString.isEmpty {
                return parseJSONString(jsonString)
            }
        }
        
        return nil
    }
    
    private func findJSONAnywhere(in text: String) -> StructuredMessage? {
        print("APIClient: Attempting regex-based JSON extraction")
        
        // Look for JSON-like patterns anywhere in the text
        let patterns = [
            "\\{[^{}]*\"type\"[^{}]*\"soap_draft\"[\\s\\S]*?\\}(?=\\s*$|\\s*```|\\s*[^}])",  // More specific for soap_draft
            "\\{[\\s\\S]*?\"type\"[\\s\\S]*?\\}",  // General type-based JSON objects
        ]
        
        for (index, pattern) in patterns.enumerated() {
            print("APIClient: Trying pattern \(index): \(pattern)")
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
                let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
                
                print("APIClient: Found \(matches.count) matches for pattern \(index)")
                
                for (matchIndex, match) in matches.enumerated() {
                    if let range = Range(match.range, in: text) {
                        let jsonString = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                        print("APIClient: Match \(matchIndex): \(jsonString.prefix(100))...")
                        
                        if let message = parseJSONString(jsonString) {
                            print("APIClient: Successfully parsed JSON from regex match")
                            return message
                        }
                    }
                }
            } catch {
                print("APIClient: Regex error for pattern \(index): \(error)")
            }
        }
        
        return nil
    }
    
    private func parseJSONString(_ jsonString: String) -> StructuredMessage? {
        print("APIClient: Attempting to parse JSON string of length \(jsonString.count)")
        
        if let jsonData = jsonString.data(using: .utf8) {
            do {
                let message = try JSONDecoder().decode(StructuredMessage.self, from: jsonData)
                print("APIClient: Successfully decoded StructuredMessage of type: \(message.type)")
                return message
            } catch {
                print("APIClient: Failed to parse JSON: \(error)")
                print("APIClient: JSON string was: \(jsonString)")
                
                // Try to parse as raw JSON to see structure
                do {
                    if let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                        print("APIClient: Raw JSON structure: \(jsonObject.keys.sorted())")
                        if let type = jsonObject["type"] as? String {
                            print("APIClient: Found type field: \(type)")
                        }
                    }
                } catch {
                    print("APIClient: Even basic JSON parsing failed: \(error)")
                }
            }
        } else {
            print("APIClient: Failed to convert string to UTF8 data")
        }
        return nil
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
        case .httpError(let _):
            return "HTTP error occurred"
        case .decodingError(let _):
            return "Decoding error occurred"
        }
    }
}