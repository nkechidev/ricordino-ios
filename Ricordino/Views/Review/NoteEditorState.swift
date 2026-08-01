import Foundation

@Observable
final class NoteEditorState {
    private(set) var existingNote: Note?
    private(set) var temporaryImagePath: String?

    var extractedText: String
    var category: NoteCategory
    var detectedEntities: [DetectedEntity]
    var isProcessing: Bool
    var isSaving = false
    var errorMessage: String?

    var isEditingExisting: Bool { existingNote != nil }

    /// New capture — fields populate asynchronously via NoteRepository.processCapture.
    init(temporaryImagePath: String) {
        self.temporaryImagePath = temporaryImagePath
        self.existingNote = nil
        self.extractedText = ""
        self.category = .other
        self.detectedEntities = []
        self.isProcessing = true
    }

    /// Editing an existing note — fields are already known, no processing needed.
    init(existingNote: Note) {
        self.existingNote = existingNote
        self.temporaryImagePath = nil
        self.extractedText = existingNote.extractedText
        self.category = existingNote.category
        self.detectedEntities = existingNote.detectedEntities
        self.isProcessing = false
    }
}
