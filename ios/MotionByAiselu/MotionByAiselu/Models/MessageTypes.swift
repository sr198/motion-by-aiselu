import Foundation

// MARK: - Message Types
enum MessageType: String, Codable {
    case chatMessage = "chat_message"
    case soapDraft = "soap_draft"
    case exerciseSelection = "exercise_selection"
    case finalReport = "final_report"
    case clarificationNeeded = "clarification_needed"
    case error = "error"
}

// MARK: - Main Message Structure
struct StructuredMessage: Codable, Identifiable {
    let id = UUID()
    let type: MessageType
    let timestamp: String
    
    // Common properties (optional based on message type)
    let content: String?
    let format: String?
    
    // Exercise selection specific
    let exerciseName: String?
    let exerciseDescription: String?
    let images: [ExerciseImage]?
    let exercises: [Exercise]? // New: multiple exercises support
    let requiresSelection: Bool?
    
    // Final report specific
    let selectedImages: [String]?
    let readyForPdf: Bool?
    
    // Structured SOAP report
    let soapReport: SOAPReport?
    
    // Clarification specific
    let questions: [String]?
    let originalContent: String?
    
    // Error specific
    let error: String?
    let details: String?
    
    private enum CodingKeys: String, CodingKey {
        case type, timestamp, content, format
        case exerciseName = "exercise_name"
        case exerciseDescription = "exercise_description"
        case images
        case exercises
        case requiresSelection = "requires_selection"
        case selectedImages = "selected_images"
        case readyForPdf = "ready_for_pdf"
        case soapReport = "soap_report"
        case questions
        case originalContent = "original_content"
        case error, details
    }
}

// MARK: - Exercise
struct Exercise: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let images: [ExerciseImage]
    
    init(id: String, name: String, description: String, images: [ExerciseImage]) {
        self.id = id
        self.name = name
        self.description = description
        self.images = images
    }
}

// MARK: - Exercise Image
struct ExerciseImage: Codable, Identifiable {
    let id: String
    let url: String
    let name: String
    var selected: Bool
    
    init(id: String, url: String, name: String, selected: Bool = false) {
        self.id = id
        self.url = url
        self.name = name
        self.selected = selected
    }
}

// MARK: - API Request Types
struct AgentRunRequest: Codable {
    let appName: String
    let userId: String
    let sessionId: String
    let newMessage: MessageContent
    let streaming: Bool
    
    private enum CodingKeys: String, CodingKey {
        case appName = "app_name"
        case userId = "user_id"
        case sessionId = "session_id"
        case newMessage = "new_message"
        case streaming
    }
}

struct MessageContent: Codable {
    let role: String
    let parts: [MessagePart]
    
    init(text: String) {
        self.role = "user"
        self.parts = [MessagePart(text: text)]
    }
}

struct MessagePart: Codable {
    let text: String
}

// MARK: - API Response Types
struct APIResponse: Codable {
    let events: [AgentEvent]?
    let error: String?
}

struct AgentEvent: Codable {
    let id: String?
    let author: String?
    let content: EventContent?
    let timestamp: Double?
    let invocationId: String?
    
    private enum CodingKeys: String, CodingKey {
        case id, author, content, timestamp
        case invocationId = "invocationId"
    }
}

struct EventContent: Codable {
    let parts: [MessagePart]?
    let role: String?
}

// MARK: - Helper for dynamic JSON
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let value = try? container.decode(String.self) {
            self.value = value
        } else if let value = try? container.decode(Int.self) {
            self.value = value
        } else if let value = try? container.decode(Double.self) {
            self.value = value
        } else if let value = try? container.decode(Bool.self) {
            self.value = value
        } else if let value = try? container.decode([String: AnyCodable].self) {
            self.value = value
        } else if let value = try? container.decode([AnyCodable].self) {
            self.value = value
        } else {
            throw DecodingError.typeMismatch(AnyCodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let dict as [String: AnyCodable]:
            try container.encode(dict)
        case let array as [AnyCodable]:
            try container.encode(array)
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}

// MARK: - Image Selection Request
struct ImageSelectionRequest: Codable {
    let selectedImageIds: [String]
    let messageType: String
    
    private enum CodingKeys: String, CodingKey {
        case selectedImageIds = "selected_image_ids"
        case messageType = "message_type"
    }
    
    init(selectedImageIds: [String]) {
        self.selectedImageIds = selectedImageIds
        self.messageType = "image_selection"
    }
}


// MARK: - Simplified SOAP Report
struct SOAPReport: Codable, Identifiable {
    let id = UUID()
    let patientName: String?
    let patientAge: String?
    let condition: String?
    let sessionDate: String?
    let subjective: String
    let objective: String
    let assessment: String
    let plan: String
    let exercises: [SimpleExercise]
    let timestamp: String?
    
    private enum CodingKeys: String, CodingKey {
        case patientName = "patient_name"
        case patientAge = "patient_age"
        case condition
        case sessionDate = "session_date"
        case subjective, objective, assessment, plan, exercises, timestamp
    }
}

struct SimpleExercise: Codable, Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let selectedImage: String?
    
    private enum CodingKeys: String, CodingKey {
        case name, description
        case selectedImage = "selected_image"
    }
}