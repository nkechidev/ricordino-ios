import Foundation
import UIKit

enum PhotoFileStoreError: Error {
    case encodingFailed
}

/// Photos are written to a temp file immediately on capture (for the Capture -> Review
/// nav handoff), and only copied into permanent storage when the user taps Save — so an
/// abandoned capture never leaves an orphaned file in the permanent Photos directory.
struct PhotoFileStore {
    private let photosDirectory: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let directory = documents.appendingPathComponent("Photos", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }()

    func writeTemporaryImage(_ image: UIImage) throws -> URL {
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw PhotoFileStoreError.encodingFailed
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("capture_\(UUID().uuidString).jpg")
        try data.write(to: url, options: .atomic)
        return url
    }

    func savePermanentPhoto(fromTemporaryURL tempURL: URL) throws -> String {
        let fileName = "\(UUID().uuidString).jpg"
        let destination = photosDirectory.appendingPathComponent(fileName)
        try FileManager.default.copyItem(at: tempURL, to: destination)
        try? FileManager.default.removeItem(at: tempURL)
        return fileName
    }

    func url(forPhotoFileName fileName: String) -> URL {
        photosDirectory.appendingPathComponent(fileName)
    }

    func deletePhoto(fileName: String) {
        try? FileManager.default.removeItem(at: url(forPhotoFileName: fileName))
    }
}
