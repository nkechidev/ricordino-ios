import SwiftUI
import UIKit

struct CaptureView: View {
    var onCaptured: (String) -> Void

    @Environment(NoteRepository.self) private var repository
    @State private var errorMessage: String?

    var body: some View {
        ImagePicker { image in
            do {
                let url = try repository.writeTemporaryPhoto(image)
                onCaptured(url.path)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        .ignoresSafeArea()
        .alert(
            "Couldn't save photo",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { isPresented in if !isPresented { errorMessage = nil } },
            ),
        ) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
}

/// The Simulator has no camera hardware, so this falls back to the photo library —
/// lets the capture -> review -> save flow still be exercised there.
private struct ImagePicker: UIViewControllerRepresentable {
    var onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImagePicked: (UIImage) -> Void

        init(onImagePicked: @escaping (UIImage) -> Void) {
            self.onImagePicked = onImagePicked
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any],
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
        }
    }
}
