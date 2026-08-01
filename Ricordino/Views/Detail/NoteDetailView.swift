import SwiftUI
import UIKit

struct NoteDetailView: View {
    let note: Note
    var onEdit: () -> Void
    var onDeleted: () -> Void

    @Environment(NoteRepository.self) private var repository
    @State private var displayedImage: UIImage?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let displayedImage {
                    Image(uiImage: displayedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 280)
                }

                Text(note.category.rawValue.capitalized)
                    .font(.headline)
                Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(note.extractedText)

                if !note.detectedEntities.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Detected").font(.headline)
                        ForEach(note.detectedEntities, id: \.self) { entity in
                            Text("\(entity.kind.rawValue): \(entity.text)")
                        }
                    }
                }

                HStack {
                    Button("Edit", action: onEdit)
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                    Button("Delete", role: .destructive, action: delete)
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
        .task {
            displayedImage = UIImage(contentsOfFile: repository.photoURL(for: note).path)
        }
        .alert(
            "Couldn't delete note",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { isPresented in if !isPresented { errorMessage = nil } },
            ),
        ) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .navigationTitle("Note")
    }

    private func delete() {
        do {
            try repository.deleteNote(note)
            onDeleted()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
