import Testing
@testable import Ricordino

struct KeywordCategoryClassifierTests {
    let classifier = KeywordCategoryClassifier()

    @Test func classifiesReceiptTextWithCurrencyAndTotalKeyword() async throws {
        let result = try await classifier.classify(text: "Grocery Store\nSubtotal: $38.50\nTax: $3.10\nTotal: $41.60")
        #expect(result == .receipt)
    }

    @Test func classifiesTextWithEmailAddressAsContact() async throws {
        let result = try await classifier.classify(text: "Jane Doe\njane.doe@example.com")
        #expect(result == .contact)
    }

    @Test func classifiesTextWithPhoneNumberAsContact() async throws {
        let result = try await classifier.classify(text: "Call me at 415-555-0192")
        #expect(result == .contact)
    }

    @Test func classifiesRecipeTextWithIngredientKeywords() async throws {
        let result = try await classifier.classify(text: "Ingredients:\n2 cups flour\n1 tsp salt\nPreheat oven to 350F")
        #expect(result == .recipe)
    }

    @Test func fallsBackToNoteForPlainText() async throws {
        let result = try await classifier.classify(text: "Remember to water the plants this weekend")
        #expect(result == .note)
    }
}
