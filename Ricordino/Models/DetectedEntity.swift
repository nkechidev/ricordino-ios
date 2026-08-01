import Foundation

struct DetectedEntity: Codable, Hashable {
    enum Kind: String, Codable {
        case date
        case phoneNumber
        case address
    }

    var kind: Kind
    var text: String
}
