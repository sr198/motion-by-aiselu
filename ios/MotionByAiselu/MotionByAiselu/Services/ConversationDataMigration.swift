import Foundation
import CoreData

class ConversationDataMigration {
    static let shared = ConversationDataMigration()
    
    private init() {}
    
    func performMigrationIfNeeded() {
        let userDefaults = UserDefaults.standard
        let migrationKey = "ConversationDataMigration_v1_completed"
        
        if !userDefaults.bool(forKey: migrationKey) {
            print("Performing initial conversation data migration...")
            
            // Create sample conversations for testing if this is the first launch
            createSampleConversationsIfNeeded()
            
            userDefaults.set(true, forKey: migrationKey)
            print("Migration completed")
        }
    }
    
    private func createSampleConversationsIfNeeded() {
        let persistenceService = ConversationPersistenceService.shared
        let existingConversations = persistenceService.loadAllConversations()
        
        // Only create samples if no conversations exist
        guard existingConversations.isEmpty else { return }
        
        print("Creating sample conversations for first launch...")
        
        // Sample conversation 1: General chat
        var chatSession1 = ChatSession()
        chatSession1.addUserMessage("Hello! What are the best exercises for lower back pain?")
        chatSession1.addAssistantMessage("Hello! For lower back pain, I recommend starting with gentle exercises that strengthen your core and improve flexibility. Here are some effective options:\n\n1. Cat-Cow stretches\n2. Knee-to-chest stretches\n3. Pelvic tilts\n4. Modified planks\n5. Bird dog exercises\n\nWould you like me to explain how to perform any of these exercises?")
        chatSession1.addUserMessage("Yes, please explain the cat-cow stretch.")
        chatSession1.addAssistantMessage("The Cat-Cow stretch is excellent for improving spinal mobility:\n\n1. Start on hands and knees in a tabletop position\n2. For 'Cow': Drop your belly, lift your chest and tailbone toward the ceiling\n3. For 'Cat': Round your spine toward the ceiling, tuck your chin to chest\n4. Move slowly between positions, holding each for 2-3 seconds\n5. Repeat 10-15 times\n\nThis exercise helps relieve tension and improves flexibility in your spine.")
        
        _ = persistenceService.saveConversation(chatSession1)
        
        // Sample conversation 2: SOAP report session
        var chatSession2 = ChatSession()
        chatSession2.addUserMessage("I just finished treating a patient with shoulder impingement. Sarah, 42 years old, complained of pain when reaching overhead, especially with lifting. Range of motion was limited in flexion and abduction. Positive impingement tests. I performed manual therapy and gave her pendulum exercises and wall slides.")
        
        // Create a structured SOAP message
        let soapReport = SOAPReport(
            patientName: "Sarah",
            patientAge: "42",
            condition: "Shoulder impingement",
            sessionDate: nil,
            subjective: "Patient reports pain when reaching overhead, especially with lifting. Pain is localized to anterior shoulder.",
            objective: "Limited range of motion in shoulder flexion (120°) and abduction (110°). Positive Neer and Hawkins impingement tests. Tenderness over subacromial space.",
            assessment: "Subacromial impingement syndrome with secondary adhesive capsulitis. Functional limitations in overhead activities.",
            plan: "Continue manual therapy, progressive exercise program focusing on scapular stabilization and rotator cuff strengthening. Patient education on posture and activity modification.",
            exercises: [
                SimpleExercise(name: "Pendulum exercises", description: "10 swings each direction, 3 times daily", selectedImage: nil),
                SimpleExercise(name: "Wall slides", description: "10 repetitions, 2 times daily", selectedImage: nil)
            ],
            timestamp: ISO8601DateFormatter().string(from: Date())
        )
        
        let structuredMessage = StructuredMessage(
            type: .soapDraft,
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
            soapReport: soapReport,
            questions: nil,
            originalContent: nil,
            error: nil,
            details: nil
        )
        
        chatSession2.addStructuredMessage(structuredMessage)
        
        _ = persistenceService.saveConversation(chatSession2)
        
        print("Sample conversations created successfully")
    }
}

// MARK: - StructuredMessage Initializer Extension
extension StructuredMessage {
    init(type: MessageType, timestamp: String, content: String?, format: String?, exerciseName: String?, exerciseDescription: String?, images: [ExerciseImage]?, exercises: [Exercise]?, requiresSelection: Bool?, selectedImages: [String]?, readyForPdf: Bool?, soapReport: SOAPReport?, questions: [String]?, originalContent: String?, error: String?, details: String?) {
        self.type = type
        self.timestamp = timestamp
        self.content = content
        self.format = format
        self.exerciseName = exerciseName
        self.exerciseDescription = exerciseDescription
        self.images = images
        self.exercises = exercises
        self.requiresSelection = requiresSelection
        self.selectedImages = selectedImages
        self.readyForPdf = readyForPdf
        self.soapReport = soapReport
        self.questions = questions
        self.originalContent = originalContent
        self.error = error
        self.details = details
    }
}