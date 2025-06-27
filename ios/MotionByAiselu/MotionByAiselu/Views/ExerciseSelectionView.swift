import SwiftUI

struct ExerciseSelectionView: View {
    let exercises: [Exercise]
    @Binding var selectedImages: Set<String>
    let onContinue: () -> Void
    
    // Legacy support for single exercise
    init(exerciseName: String, exerciseDescription: String, images: [ExerciseImage], selectedImages: Binding<Set<String>>, onContinue: @escaping () -> Void) {
        let legacyExercise = Exercise(id: "legacy", name: exerciseName, description: exerciseDescription, images: images)
        self.exercises = [legacyExercise]
        self._selectedImages = selectedImages
        self.onContinue = onContinue
    }
    
    // New multi-exercise initializer
    init(exercises: [Exercise], selectedImages: Binding<Set<String>>, onContinue: @escaping () -> Void) {
        self.exercises = exercises
        self._selectedImages = selectedImages
        self.onContinue = onContinue
    }
    
    @State private var imageLoadErrors: Set<String> = []
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Select Exercise Illustrations")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Choose illustrations to include in your SOAP report")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\\(selectedImages.count) selected")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(.systemGray5)),
                alignment: .bottom
            )
            
            // Exercise Groups - Full height scrollable area
            ScrollView {
                LazyVStack(spacing: 32) {
                    ForEach(exercises) { exercise in
                        ExerciseGroupView(
                            exercise: exercise,
                            selectedImages: $selectedImages,
                            imageLoadErrors: $imageLoadErrors
                        )
                    }
                }
                .padding()
            }
            
            // Continue Button - Fixed at bottom
            VStack(spacing: 0) {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(.systemGray5))
                
                Button(action: onContinue) {
                    HStack {
                        Text("Continue with Selected Images")
                        Image(systemName: "arrow.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedImages.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                    .foregroundColor(selectedImages.isEmpty ? .gray : .white)
                    .cornerRadius(12)
                }
                .disabled(selectedImages.isEmpty)
                .padding()
                .background(Color(.systemBackground))
            }
        }
    }
    
    private func toggleImageSelection(_ imageId: String) {
        if selectedImages.contains(imageId) {
            selectedImages.remove(imageId)
        } else {
            selectedImages.insert(imageId)
        }
    }
}

struct ExerciseGroupView: View {
    let exercise: Exercise
    @Binding var selectedImages: Set<String>
    @Binding var imageLoadErrors: Set<String>
    
    let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise header with name and description (keeping the format you like)
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(exercise.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
            // Images grid for this exercise
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(exercise.images) { image in
                    ExerciseImageCard(
                        image: image,
                        isSelected: selectedImages.contains(image.id),
                        hasError: imageLoadErrors.contains(image.id),
                        onToggle: { toggleImageSelection(image.id) },
                        onImageError: { imageLoadErrors.insert(image.id) }
                    )
                }
            }
        }
    }
    
    private func toggleImageSelection(_ imageId: String) {
        if selectedImages.contains(imageId) {
            selectedImages.remove(imageId)
        } else {
            selectedImages.insert(imageId)
        }
    }
}

struct ExerciseImageCard: View {
    let image: ExerciseImage
    let isSelected: Bool
    let hasError: Bool
    let onToggle: () -> Void
    let onImageError: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
                    .frame(height: 200)
                
                if hasError {
                    // Error state
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("Failed to load")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                } else {
                    // Async image loading
                    AsyncImage(url: URL(string: image.url)) { imagePhase in
                        switch imagePhase {
                        case .empty:
                            ProgressView()
                                .frame(width: 50, height: 50)
                                .scaleEffect(1.2)
                        case .success(let loadedImage):
                            loadedImage
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 190)
                                .cornerRadius(12)
                                .clipped()
                        case .failure(_):
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("Failed to load")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .onAppear {
                                onImageError()
                            }
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                
                // Selection overlay
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 4)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.15))
                        )
                    
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .background(Color.white)
                                .clipShape(Circle())
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            
            // Image name
            Text(image.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .onTapGesture {
            onToggle()
        }
    }
}

#Preview {
    ExerciseSelectionView(
        exercises: [
            Exercise(
                id: "exercise_1",
                name: "Cat-Cow Exercises",
                description: "10 repetitions, 3 times daily",
                images: [
                    ExerciseImage(id: "img_1", url: "https://example.com/cat-cow-1.jpg", name: "Cat pose demonstration"),
                    ExerciseImage(id: "img_2", url: "https://example.com/cat-cow-2.jpg", name: "Cow pose demonstration"),
                    ExerciseImage(id: "img_3", url: "https://example.com/cat-cow-3.jpg", name: "Full cat-cow sequence")
                ]
            ),
            Exercise(
                id: "exercise_2", 
                name: "Bridge Exercises",
                description: "10 repetitions, 2 times daily",
                images: [
                    ExerciseImage(id: "img_4", url: "https://example.com/bridge-1.jpg", name: "Basic bridge position"),
                    ExerciseImage(id: "img_5", url: "https://example.com/bridge-2.jpg", name: "Single leg bridge"),
                    ExerciseImage(id: "img_6", url: "https://example.com/bridge-3.jpg", name: "Bridge with leg extension")
                ]
            )
        ],
        selectedImages: .constant(["img_1", "img_4"]),
        onContinue: {}
    )
}