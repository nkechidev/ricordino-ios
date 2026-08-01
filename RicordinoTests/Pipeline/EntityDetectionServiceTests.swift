import Testing
@testable import Ricordino

struct EntityDetectionServiceTests {
    let service = EntityDetectionService()

    // The exact bug hit on Android: ingredient percentages on a product label
    // misread as date fragments.
    @Test func rejectsPercentagesMisreadAsDates() async {
        let entities = await service.detect(in: "POLYETHYLENE GLYCOL 400 0.4%\nPROPYLENE GLYCOL 0.3%")
        #expect(entities.isEmpty)
    }

    @Test func detectsARealDate() async {
        let entities = await service.detect(in: "Meet me on March 15, 2025 at noon")
        #expect(entities.contains { $0.kind == .date })
    }

    @Test func detectsAPhoneNumber() async {
        let entities = await service.detect(in: "Call me at 415-555-0192")
        #expect(entities.contains { $0.kind == .phoneNumber })
    }

    @Test func rejectsShortNumericFragments() async {
        let entities = await service.detect(in: "Total: 12.5")
        #expect(entities.isEmpty)
    }
}
