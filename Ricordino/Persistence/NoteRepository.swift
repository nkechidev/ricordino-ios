import Foundation
import SwiftData
import UIKit

struct CaptureResult {
    var extractedText: String
    var category: NoteCategory
    var detectedEntities: [DetectedEntity]
}

@Observable
@MainActor
final class NoteRepository {
    private let modelContext: ModelContext
    private let ocrService: any OCRRecognizing
    private let classifier: CategoryClassifying
    private let entityService: any EntityDetecting
    private let photoStore: PhotoFileStore

    init(
        modelContext: ModelContext,
        ocrService: any OCRRecognizing,
        classifier: CategoryClassifying,
        entityService: any EntityDetecting,
        photoStore: PhotoFileStore
    ) {
        self.modelContext = modelContext
        self.ocrService = ocrService
        self.classifier = classifier
        self.entityService = entityService
        self.photoStore = photoStore
    }

    func writeTemporaryPhoto(_ image: UIImage) throws -> URL {
        try photoStore.writeTemporaryImage(image)
    }

    func processCapture(imageURL: URL) async throws -> CaptureResult {
        let text = try await ocrService.recognizeText(at: imageURL)
        let category = try await classifier.classify(text: text)
        let entities = await entityService.detect(in: text)
        return CaptureResult(extractedText: text, category: category, detectedEntities: entities)
    }

    func saveNote(
        temporaryImageURL: URL,
        extractedText: String,
        category: NoteCategory,
        detectedEntities: [DetectedEntity]
    ) throws {
        let fileName = try photoStore.savePermanentPhoto(fromTemporaryURL: temporaryImageURL)
        let note = Note(
            extractedText: extractedText,
            category: category,
            photoFileName: fileName,
            detectedEntities: detectedEntities
        )
        modelContext.insert(note)
        try modelContext.save()
    }

    func updateNote(_ note: Note, extractedText: String, category: NoteCategory) throws {
        note.extractedText = extractedText
        note.category = category
        try modelContext.save()
    }

    func deleteNote(_ note: Note) throws {
        photoStore.deletePhoto(fileName: note.photoFileName)
        modelContext.delete(note)
        try modelContext.save()
    }

    func getAllNotes() throws -> [Note] {
        try searchNotes(query: "")
    }

    func searchNotes(query: String) throws -> [Note] {
        let descriptor: FetchDescriptor<Note>
        if query.isEmpty {
            descriptor = FetchDescriptor<Note>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        } else {
            descriptor = FetchDescriptor<Note>(
                predicate: #Predicate<Note> { note in
                    note.extractedText.localizedStandardContains(query)
                },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
        }
        return try modelContext.fetch(descriptor)
    }

    func photoURL(for note: Note) -> URL {
        photoStore.url(forPhotoFileName: note.photoFileName)
    }
}
