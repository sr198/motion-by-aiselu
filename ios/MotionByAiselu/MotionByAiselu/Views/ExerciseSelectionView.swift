import SwiftUI

struct ExerciseSelectionView: View {
    let exerciseName: String
    let exerciseDescription: String
    let images: [ExerciseImage]
    @Binding var selectedImages: Set<String>
    let onContinue: () -> Void
    
    @State private var imageLoadErrors: Set<String> = []
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Exercise Illustrations")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exerciseName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(exerciseDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Instructions
            Text("Choose one or more illustrations to include in your SOAP report:")
                .font(.body)
                .foregroundColor(.secondary)
            
            // Image Grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(images) { image in
                        ExerciseImageCard(
                            image: image,
                            isSelected: selectedImages.contains(image.id),
                            hasError: imageLoadErrors.contains(image.id),
                            onToggle: { toggleImageSelection(image.id) },
                            onImageError: { imageLoadErrors.insert(image.id) }
                        )
                    }
                }
                .padding(.vertical)
            }
            
            Spacer()
            
            // Continue Button
            VStack(spacing: 12) {
                HStack {
                    Text("\\(selectedImages.count) image(s) selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                
                Button(action: onContinue) {
                    HStack {
                        Text("Continue with Selected Images")
                        Image(systemName: "arrow.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedImages.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                    .foregroundColor(selectedImages.isEmpty ? .gray : .white)
                    .cornerRadius(8)
                }
                .disabled(selectedImages.isEmpty)
            }
        }
        .padding()
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
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 120)
                
                if hasError {
                    // Error state
                    VStack {
                        Image(systemName: "photo")
                            .font(.title)
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
                                .frame(width: 40, height: 40)
                        case .success(let loadedImage):
                            loadedImage
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 120)
                                .cornerRadius(8)
                        case .failure(_):
                            VStack {
                                Image(systemName: "photo")
                                    .font(.title)
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
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue, lineWidth: 3)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.1))
                        )
                    
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                                .background(Color.white)
                                .clipShape(Circle())
                                .padding(4)
                        }
                        Spacer()
                    }
                }
            }
            
            // Image name
            Text(image.name)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundColor(.primary)
        }
        .onTapGesture {
            onToggle()
        }
    }
}

#Preview {
    ExerciseSelectionView(
        exerciseName: "Cat-Cow Exercises",
        exerciseDescription: "10 repetitions, 3 times daily",
        images: [
            ExerciseImage(
                id: "img_1",
                url: "https://example.com/cat-cow-1.jpg",
                name: "Cat pose demonstration"
            ),
            ExerciseImage(
                id: "img_2", 
                url: "https://example.com/cat-cow-2.jpg",
                name: "Cow pose demonstration"
            ),
            ExerciseImage(
                id: "img_3",
                url: "https://example.com/cat-cow-3.jpg", 
                name: "Full cat-cow sequence"
            ),
            ExerciseImage(
                id: "img_4",
                url: "https://example.com/cat-cow-4.jpg",
                name: "Alternative cat-cow position"
            )
        ],
        selectedImages: .constant(["img_1"]),
        onContinue: {}
    )
}