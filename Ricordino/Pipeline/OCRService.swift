import Foundation
@preconcurrency import Vision

// Exists purely so NoteRepositoryTests can inject a fake — OCRService itself isn't
// designed to change, so production code only ever uses the concrete type directly.
protocol OCRRecognizing {
    func recognizeText(at imageURL: URL) async throws -> String
}

struct OCRService: OCRRecognizing {
    // VNRecognizeTextRequest reports results via a completion closure, and
    // VNImageRequestHandler.perform is itself a blocking call — bridge both to async/await
    // and keep the blocking call off the calling thread, the direct analogue of bridging
    // ML Kit's Task via a coroutine .await() extension.
    func recognizeText(at imageURL: URL) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let text = (request.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n") ?? ""
                continuation.resume(returning: text)
            }
            request.recognitionLevel = .accurate

            DispatchQueue.global(qos: .userInitiated).async {
                let handler = VNImageRequestHandler(url: imageURL, options: [:])
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
