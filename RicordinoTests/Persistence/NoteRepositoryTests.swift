import Foundation
import SwiftData
import Testing
@testable import Ricordino

@MainActor
struct NoteRepositoryTests {
    @Test func processCaptureRunsOcrClassificationAndEntityDetectionInOrder() async throws {
        let ocr = FakeOCRRecognizing(result: "Total: $12.00")
        let classifier = FakeCategoryClassifier(result: .receipt)
        let entities = FakeEntityDetecting(result: [DetectedEntity(kind: .date, text: "March 1")])
        let repository = try makeRepository(ocr: ocr, classifier: classifier, entities: entities)

        let result = try await repository.processCapture(imageURL: URL(fileURLWithPath: "/tmp/fake.jpg"))

        #expect(result.extractedText == "Total: $12.00")
        #expect(result.category == .receipt)
        #expect(result.detectedEntities == [DetectedEntity(kind: .date, text: "March 1")])
        #expect(ocr.receivedImageURL?.path == "/tmp/fake.jpg")
        #expect(classifier.receivedText == "Total: $12.00")
        #expect(entities.receivedText == "Total: $12.00")
    }

    @Test func saveNoteConsumesTheTempPhotoAndInsertsANote() throws {
        let repository = try makeRepository()
        let tempURL = try writeFakeJPEG()

        try repository.saveNote(
            temporaryImageURL: tempURL,
            extractedText: "hello",
            category: .note,
            detectedEntities: [],
        )

        let notes = try repository.getAllNotes()
        #expect(notes.count == 1)
        #expect(notes.first?.extractedText == "hello")
        #expect(notes.first?.category == .note)
        #expect(!FileManager.default.fileExists(atPath: tempURL.path))
    }

    @Test func searchNotesFiltersBySubstring() throws {
        let repository = try makeRepository()
        try insertNote(repository, text: "Grocery receipt total $42.10")
        try insertNote(repository, text: "Call mom about dinner")

        let results = try repository.searchNotes(query: "receipt")

        #expect(results.count == 1)
        #expect(results.first?.extractedText.contains("receipt") == true)
    }

    @Test func deleteNoteRemovesIt() throws {
        let repository = try makeRepository()
        try insertNote(repository, text: "temp")
        let note = try repository.getAllNotes().first!

        try repository.deleteNote(note)

        #expect(try repository.getAllNotes().isEmpty)
    }

    @Test func updateNoteChangesTextAndCategory() throws {
        let repository = try makeRepository()
        try insertNote(repository, text: "original")
        let note = try repository.getAllNotes().first!

        try repository.updateNote(note, extractedText: "edited", category: .contact)

        let updated = try repository.getAllNotes().first!
        #expect(updated.extractedText == "edited")
        #expect(updated.category == .contact)
    }

    // MARK: - Helpers

    private func makeRepository(
        ocr: any OCRRecognizing = FakeOCRRecognizing(result: ""),
        classifier: any CategoryClassifying = FakeCategoryClassifier(result: .note),
        entities: any EntityDetecting = FakeEntityDetecting(result: []),
    ) throws -> NoteRepository {
        let schema = Schema([Note.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        // container.mainContext carries stricter main-thread-affinity assumptions than
        // Swift Testing's @MainActor test execution reliably provides — a plain
        // ModelContext(container) avoids that mismatch in tests.
        return NoteRepository(
            modelContext: ModelContext(container),
            ocrService: ocr,
            classifier: classifier,
            entityService: entities,
            photoStore: PhotoFileStore(),
        )
    }

    private func writeFakeJPEG() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("test-\(UUID().uuidString).jpg")
        try Data([0xFF, 0xD8, 0xFF]).write(to: url)
        return url
    }

    private func insertNote(_ repository: NoteRepository, text: String) throws {
        let tempURL = try writeFakeJPEG()
        try repository.saveNote(temporaryImageURL: tempURL, extractedText: text, category: .note, detectedEntities: [])
    }
}

private final class FakeOCRRecognizing: OCRRecognizing {
    let result: String
    var receivedImageURL: URL?

    init(result: String) {
        self.result = result
    }

    func recognizeText(at imageURL: URL) async throws -> String {
        receivedImageURL = imageURL
        return result
    }
}

private final class FakeCategoryClassifier: CategoryClassifying {
    let result: NoteCategory
    var receivedText: String?

    init(result: NoteCategory) {
        self.result = result
    }

    func classify(text: String) async throws -> NoteCategory {
        receivedText = text
        return result
    }
}

private final class FakeEntityDetecting: EntityDetecting {
    let result: [DetectedEntity]
    var receivedText: String?

    init(result: [DetectedEntity]) {
        self.result = result
    }

    func detect(in text: String) async -> [DetectedEntity] {
        receivedText = text
        return result
    }
}
