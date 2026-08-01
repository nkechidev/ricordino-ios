import Foundation

/// The one seam designed for v2 churn: KeywordCategoryClassifier implements this now,
/// an LLM-backed classifier implements it later — no caller changes when that swap happens.
protocol CategoryClassifying {
    func classify(text: String) async throws -> NoteCategory
}
