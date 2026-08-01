import Foundation
import SwiftData

@MainActor
final class AppDependencies {
    let repository: NoteRepository

    init(modelContext: ModelContext) {
        self.repository = NoteRepository(
            modelContext: modelContext,
            ocrService: OCRService(),
            classifier: KeywordCategoryClassifier(),
            entityService: EntityDetectionService(),
            photoStore: PhotoFileStore()
        )
    }
}
