import SwiftUI
import UIKit

struct ReviewView: View {
    @Bindable var editor: NoteEditorState
    var onFinished: () -> Void

    @Environment(NoteRepository.self) private var repository
    @State private var displayedImage: UIImage?

    var body: some View {
        Group {
            if editor.isProcessing {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                form
            }
        }
        .navigationTitle(editor.isEditingExisting ? "Edit Note" : "Review")
        .task {
            loadImage()
            if !editor.isEditingExisting {
                await processIfNeeded()
            }
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { editor.errorMessage != nil },
                set: { isPresented in if !isPresented { editor.errorMessage = nil } },
            ),
        ) {
            Button("OK") { editor.errorMessage = nil }
        } message: {
            Text(editor.errorMessage ?? "")
        }
    }

    private var form: some View {
        Form {
            if let displayedImage {
                Section {
                    Image(uiImage: displayedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 240)
                        .listRowInsets(EdgeInsets())
                }
            }

            Section("Extracted text") {
                TextEditor(text: $editor.extractedText)
                    .frame(minHeight: 120)
            }

            Section("Category") {
                Picker("Category", selection: $editor.category) {
                    ForEach(NoteCategory.allCases, id: \.self) { category in
                        Text(category.rawValue.capitalized).tag(category)
                    }
                }
                .pickerStyle(.menu)
            }

            if !editor.detectedEntities.isEmpty {
                Section("Detected") {
                    ForEach(editor.detectedEntities, id: \.self) { entity in
                        Text("\(entity.kind.rawValue): \(entity.text)")
                    }
                }
            }

            Section {
                Button(editor.isSaving ? "Saving…" : "Save note") {
                    Task { await save() }
                }
                .disabled(editor.isSaving)
            }
        }
    }

    private func loadImage() {
        if let note = editor.existingNote {
            displayedImage = UIImage(contentsOfFile: repository.photoURL(for: note).path)
        } else if let path = editor.temporaryImagePath {
            displayedImage = UIImage(contentsOfFile: path)
        }
    }

    private func processIfNeeded() async {
        guard let path = editor.temporaryImagePath else { return }
        do {
            let result = try await repository.processCapture(imageURL: URL(fileURLWithPath: path))
            editor.extractedText = result.extractedText
            editor.category = result.category
            editor.detectedEntities = result.detectedEntities
        } catch {
            editor.errorMessage = error.localizedDescription
        }
        editor.isProcessing = false
    }

    private func save() async {
        editor.isSaving = true
        do {
            if let note = editor.existingNote {
                try repository.updateNote(note, extractedText: editor.extractedText, category: editor.category)
            } else if let path = editor.temporaryImagePath {
                try repository.saveNote(
                    temporaryImageURL: URL(fileURLWithPath: path),
                    extractedText: editor.extractedText,
                    category: editor.category,
                    detectedEntities: editor.detectedEntities,
                )
            }
            onFinished()
        } catch {
            editor.errorMessage = error.localizedDescription
        }
        editor.isSaving = false
    }
}
