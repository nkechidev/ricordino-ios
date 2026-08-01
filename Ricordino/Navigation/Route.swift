import Foundation

enum Route: Hashable {
    case review(imagePath: String)
    case detail(noteID: UUID)
    case edit(noteID: UUID)
}
