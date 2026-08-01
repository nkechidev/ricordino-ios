import Foundation

struct KeywordCategoryClassifier: CategoryClassifying {
    func classify(text: String) async throws -> NoteCategory {
        let lower = text.lowercased()
        let fullRange = NSRange(text.startIndex..., in: text)

        let hasReceiptKeyword = Self.receiptKeywords.contains { lower.contains($0) }
        let hasCurrency = Self.currencyRegex.firstMatch(in: text, range: fullRange) != nil
        if hasReceiptKeyword && hasCurrency {
            return .receipt
        }

        let hasPhone = Self.phoneRegex.firstMatch(in: text, range: fullRange) != nil
        if text.contains("@") || hasPhone {
            return .contact
        }

        if Self.recipeKeywords.contains(where: { lower.contains($0) }) {
            return .recipe
        }

        return .note
    }

    private static let receiptKeywords = ["total", "subtotal", "receipt", "tax", "change due"]
    private static let recipeKeywords = ["ingredients", "recipe", "cup ", "tbsp", "tsp", "preheat", "bake"]
    private static let currencyRegex = try! NSRegularExpression(pattern: #"[$€£]\s?\d"#)
    private static let phoneRegex = try! NSRegularExpression(pattern: #"(\+?\d[\d\-.\s]{7,}\d)"#)
}
