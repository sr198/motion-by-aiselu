import SwiftUI

struct SOAPReportView: View {
    let soapReport: SOAPReport
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with patient info
                PatientInfoHeader(soapReport: soapReport)
                    .padding(.bottom, 24)
                
                // SOAP Sections
                VStack(spacing: 20) {
                    SimplifiedSOAPSectionView(title: "Subjective (S)", content: soapReport.subjective, color: .blue, icon: "person.fill")
                    SimplifiedSOAPSectionView(title: "Objective (O)", content: soapReport.objective, color: .green, icon: "stethoscope")
                    SimplifiedSOAPSectionView(title: "Assessment (A)", content: soapReport.assessment, color: .orange, icon: "brain.head.profile")
                    SimplifiedSOAPSectionView(title: "Plan (P)", content: soapReport.plan, color: .purple, icon: "list.clipboard")
                    
                    // Exercises section if there are any
                    if !soapReport.exercises.isEmpty {
                        ExercisesSection(exercises: soapReport.exercises)
                    }
                }
                
                // Footer with timestamp
                HStack {
                    Spacer()
                    if let timestamp = soapReport.timestamp {
                        Text("Generated: \(formatTimestamp(timestamp))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 20)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func formatTimestamp(_ timestamp: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: timestamp) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return timestamp
    }
}

struct PatientInfoHeader: View {
    let soapReport: SOAPReport
    
    var body: some View {
        VStack(spacing: 16) {
            // Title
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("SOAP Report")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            // Patient details card
            VStack(alignment: .leading, spacing: 12) {
                if let name = soapReport.patientName {
                    InfoRow(label: "Patient", value: name, icon: "person.circle")
                }
                
                HStack {
                    if let age = soapReport.patientAge {
                        InfoRow(label: "Age", value: age, icon: "calendar")
                    }
                    
                    Spacer()
                    
                    if let sessionDate = soapReport.sessionDate {
                        InfoRow(label: "Session", value: sessionDate, icon: "clock")
                    }
                }
                
                if let condition = soapReport.condition {
                    InfoRow(label: "Condition", value: condition, icon: "medical.thermometer")
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .font(.caption)
                .frame(width: 16)
            
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct SimplifiedSOAPSectionView: View {
    let title: String
    let content: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(color.opacity(0.05))
            
            // Section Content
            VStack(alignment: .leading, spacing: 8) {
                Text(content)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
            }
            .padding(16)
            .background(Color(.systemBackground))
        }
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct ExercisesSection: View {
    let exercises: [SimpleExercise]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.teal.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "figure.walk")
                        .foregroundColor(.teal)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text("Exercises")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.teal)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.teal.opacity(0.05))
            
            // Exercises Content
            VStack(alignment: .leading, spacing: 12) {
                ForEach(exercises) { exercise in
                    ExerciseItemView(exercise: exercise)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
        }
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct ExerciseItemView: View {
    let exercise: SimpleExercise
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "figure.strengthtraining.functional")
                .foregroundColor(.teal)
                .font(.body)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(exercise.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                if let imageUrl = exercise.selectedImage {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(height: 100)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundColor(.secondary)
                            }
                    }
                    .frame(maxHeight: 100)
                    .cornerRadius(8)
                }
            }
            
            Spacer()
        }
    }
}

#Preview {
    SOAPReportView(
        soapReport: SOAPReport(
            patientName: "John Smith",
            patientAge: "45",
            condition: "Lower back pain",
            sessionDate: "2024-01-15",
            subjective: "Chief complaint: Lower back pain, 7/10 intensity. Duration: 3 days. Aggravating factors include sitting and bending forward. Relieving factors include walking and lying down.",
            objective: "Range of motion: Limited lumbar flexion (50% normal). Strength: 4/5 hip flexors bilaterally. Special tests: Positive straight leg raise test.",
            assessment: "Clinical impression: Acute lumbar strain. Contributing factors include poor posture and prolonged sitting.",
            plan: "Manual therapy: Soft tissue mobilization. Continue with prescribed home exercises. Follow-up in 1 week.",
            exercises: [
                SimpleExercise(name: "Cat-cow stretches", description: "10 reps, 3x daily", selectedImage: nil),
                SimpleExercise(name: "Bridge exercises", description: "10 reps, 2x daily", selectedImage: nil)
            ],
            timestamp: ISO8601DateFormatter().string(from: Date())
        )
    )
}