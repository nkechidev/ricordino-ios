import Foundation
import SwiftData

@Model
final class Note {
    @Attribute(.unique) var id: UUID
    var extractedText: String
    var categoryRawValue: String
    var createdAt: Date
    var photoFileName: String
    var detectedEntities: [DetectedEntity]

    init(
        id: UUID = UUID(),
        extractedText: String,
        category: NoteCategory,
        createdAt: Date = .now,
        photoFileName: String,
        detectedEntities: [DetectedEntity] = []
    ) {
        self.id = id
        self.extractedText = extractedText
        self.categoryRawValue = category.rawValue
        self.createdAt = createdAt
        self.photoFileName = photoFileName
        self.detectedEntities = detectedEntities
    }

    var category: NoteCategory {
        get { NoteCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }
}
