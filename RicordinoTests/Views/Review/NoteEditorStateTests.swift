import Testing
@testable import Ricordino

struct NoteEditorStateTests {
    @Test func newCaptureStateStartsProcessingWithEmptyFields() {
        let state = NoteEditorState(temporaryImagePath: "/tmp/fake.jpg")

        #expect(state.isProcessing == true)
        #expect(state.isEditingExisting == false)
        #expect(state.extractedText == "")
        #expect(state.category == .other)
    }

    @Test func editingExistingNoteStartsWithItsFieldsAndNotProcessing() {
        let note = Note(extractedText: "existing text", category: .recipe, photoFileName: "photo.jpg")
        let state = NoteEditorState(existingNote: note)

        #expect(state.isProcessing == false)
        #expect(state.isEditingExisting == true)
        #expect(state.extractedText == "existing text")
        #expect(state.category == .recipe)
    }

    @Test func fieldsCanBeUpdated() {
        let state = NoteEditorState(temporaryImagePath: "/tmp/fake.jpg")

        state.extractedText = "edited"
        state.category = .contact
        state.isSaving = true

        #expect(state.extractedText == "edited")
        #expect(state.category == .contact)
        #expect(state.isSaving == true)
    }
}
