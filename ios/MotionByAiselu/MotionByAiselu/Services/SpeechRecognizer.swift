import Foundation
import Speech
import AVFoundation
import Combine

@MainActor
class SpeechRecognizer: ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var isAvailable = false
    @Published var error: Error?
    @Published var autoStoppedRecording = false
    @Published var hasDetectedSpeech = false
    
    // Auto-stop configuration
    var silenceTimeout: TimeInterval = 5.0 // Configurable silence timeout in seconds
    
    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // Silence detection
    private var silenceTimer: Timer?
    private var lastTranscriptUpdate: Date?
    
    init() {
        Task {
            await setupSpeechRecognizer()
        }
    }
    
    // MARK: - Setup
    
    private func setupSpeechRecognizer() async {
        // Try multiple locales to find available speech recognizer
        let locales = [
            Locale(identifier: "en-US"),
            Locale(identifier: "en"),
            Locale.current,
            Locale(identifier: "en-GB")
        ]
        
        for locale in locales {
            speechRecognizer = SFSpeechRecognizer(locale: locale)
            if let recognizer = speechRecognizer {
                print("SpeechRecognizer: Trying locale: \(locale.identifier), available: \(recognizer.isAvailable)")
                if recognizer.isAvailable {
                    print("SpeechRecognizer: Using locale: \(locale.identifier)")
                    break
                }
            } else {
                print("SpeechRecognizer: Could not create recognizer for locale: \(locale.identifier)")
            }
        }
        
        guard let speechRecognizer = speechRecognizer else {
            print("SpeechRecognizer: No speech recognizer available for any locale")
            self.error = SpeechError.recognizerNotAvailable
            return
        }
        
        self.isAvailable = speechRecognizer.isAvailable
        print("SpeechRecognizer: Speech recognizer available: \(speechRecognizer.isAvailable)")
        
        // Request authorization
        await requestAuthorization()
        
        // Monitor availability changes
        speechRecognizer.delegate = SpeechRecognizerDelegate(parent: self)
    }
    
    private func requestAuthorization() async {
        let authStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        
        switch authStatus {
        case .authorized:
            // Request microphone permission
            await requestMicrophonePermission()
        case .denied:
            self.error = SpeechError.authorizationDenied
        case .restricted:
            self.error = SpeechError.authorizationRestricted
        case .notDetermined:
            self.error = SpeechError.authorizationNotDetermined
        @unknown default:
            self.error = SpeechError.unknownAuthorizationStatus
        }
    }
    
    private func requestMicrophonePermission() async {
        let permissionStatus = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        
        if !permissionStatus {
            self.error = SpeechError.microphonePermissionDenied
        }
    }
    
    // MARK: - Recording Control
    
    func startRecording() {
        guard !isRecording else { 
            print("SpeechRecognizer: Already recording")
            return 
        }
        
        print("SpeechRecognizer: Starting recording...")
        error = nil
        transcript = ""
        autoStoppedRecording = false
        
        // Reset silence detection state
        lastTranscriptUpdate = nil
        hasDetectedSpeech = false
        stopSilenceTimer()
        
        do {
            try startSpeechRecognition()
            isRecording = true
            print("SpeechRecognizer: Recording started successfully")
        } catch {
            print("SpeechRecognizer: Failed to start recording: \(error)")
            self.error = error
        }
    }
    
    func stopRecording(autoStopped: Bool = false) {
        guard isRecording else { 
            print("SpeechRecognizer: Not currently recording")
            return 
        }
        
        print("SpeechRecognizer: Stopping recording (auto-stopped: \(autoStopped))...")
        
        // Stop silence timer
        stopSilenceTimer()
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isRecording = false
        autoStoppedRecording = autoStopped
        print("SpeechRecognizer: Recording stopped")
    }
    
    private func startSpeechRecognition() throws {
        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechError.recognitionRequestFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure audio engine
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            throw SpeechError.audioEngineFailed
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                if let result = result {
                    let newTranscript = result.bestTranscription.formattedString
                    let transcriptChanged = newTranscript != self?.transcript
                    
                    self?.transcript = newTranscript
                    print("SpeechRecognizer: Transcript updated: \(newTranscript)")
                    
                    // Handle silence detection
                    if transcriptChanged && !newTranscript.isEmpty {
                        self?.handleTranscriptUpdate()
                    }
                    
                    // If result is final, stop recording
                    if result.isFinal {
                        print("SpeechRecognizer: Recognition completed")
                        self?.stopRecording()
                    }
                }
                
                if let error = error {
                    print("SpeechRecognizer: Recognition error: \(error)")
                    self?.error = error
                    self?.stopRecording()
                }
            }
        }
    }
    
    // MARK: - Silence Detection
    
    private func handleTranscriptUpdate() {
        print("SpeechRecognizer: Handling transcript update for silence detection")
        
        // Mark that we've detected speech
        hasDetectedSpeech = true
        lastTranscriptUpdate = Date()
        
        // Restart the silence timer
        restartSilenceTimer()
    }
    
    private func restartSilenceTimer() {
        stopSilenceTimer()
        
        // Only start silence timer if we've detected speech at least once
        guard hasDetectedSpeech && isRecording else { return }
        
        print("SpeechRecognizer: Starting silence timer for \(silenceTimeout) seconds")
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.handleSilenceTimeout()
            }
        }
    }
    
    private func stopSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = nil
    }
    
    private func handleSilenceTimeout() {
        guard isRecording && hasDetectedSpeech else { return }
        
        print("SpeechRecognizer: Silence timeout reached, auto-stopping recording")
        stopRecording(autoStopped: true)
    }
    
    // MARK: - Cleanup
    
    deinit {
        // Cleanup audio resources directly without @MainActor
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        silenceTimer?.invalidate()
    }
}

// MARK: - Speech Recognizer Delegate

private class SpeechRecognizerDelegate: NSObject, SFSpeechRecognizerDelegate {
    weak var parent: SpeechRecognizer?
    
    init(parent: SpeechRecognizer) {
        self.parent = parent
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            parent?.isAvailable = available
            if !available {
                parent?.stopRecording()
            }
        }
    }
}

// MARK: - Speech Errors

enum SpeechError: LocalizedError {
    case recognizerNotAvailable
    case authorizationDenied
    case authorizationRestricted
    case authorizationNotDetermined
    case unknownAuthorizationStatus
    case microphonePermissionDenied
    case recognitionRequestFailed
    case audioEngineFailed
    
    var errorDescription: String? {
        switch self {
        case .recognizerNotAvailable:
            return "Speech recognizer is not available for this device or locale"
        case .authorizationDenied:
            return "Speech recognition authorization was denied"
        case .authorizationRestricted:
            return "Speech recognition is restricted on this device"
        case .authorizationNotDetermined:
            return "Speech recognition authorization not determined"
        case .unknownAuthorizationStatus:
            return "Unknown speech recognition authorization status"
        case .microphonePermissionDenied:
            return "Microphone permission was denied"
        case .recognitionRequestFailed:
            return "Failed to create speech recognition request"
        case .audioEngineFailed:
            return "Failed to initialize audio engine"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .authorizationDenied, .microphonePermissionDenied:
            return "Please enable speech recognition and microphone access in Settings"
        case .recognizerNotAvailable:
            return "Try changing your device language or check internet connection"
        default:
            return "Please try again or restart the app"
        }
    }
}