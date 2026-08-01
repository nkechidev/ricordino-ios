import SwiftUI
import UIKit

struct NotesListView: View {
    @Environment(NoteRepository.self) private var repository

    @State private var path: [Route] = []
    @State private var searchText = ""
    @State private var notes: [Note] = []
    @State private var isCapturing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if notes.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No notes yet" : "No matches",
                        systemImage: "note.text",
                        description: Text(
                            searchText.isEmpty
                                ? "Tap + to capture one."
                                : "No notes match \"\(searchText)\".",
                        ),
                    )
                } else {
                    List(notes, id: \.id) { note in
                        Button {
                            path.append(.detail(noteID: note.id))
                        } label: {
                            NoteRow(note: note)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Ricordino")
            .searchable(text: $searchText, prompt: "Search notes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isCapturing = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(for: Route.self) { route in
                destination(for: route)
            }
        }
        .fullScreenCover(isPresented: $isCapturing) {
            CaptureView { imagePath in
                isCapturing = false
                path.append(.review(imagePath: imagePath))
            }
        }
        .task { reload() }
        .onChange(of: searchText) { reload() }
        .alert(
            "Something went wrong",
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

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .review(let imagePath):
            ReviewView(editor: NoteEditorState(temporaryImagePath: imagePath)) {
                path.removeAll()
                reload()
            }

        case .detail(let noteID):
            if let note = notes.first(where: { $0.id == noteID }) {
                NoteDetailView(
                    note: note,
                    onEdit: { path.append(.edit(noteID: noteID)) },
                    onDeleted: {
                        path.removeLast()
                        reload()
                    },
                )
            }

        case .edit(let noteID):
            if let note = notes.first(where: { $0.id == noteID }) {
                ReviewView(editor: NoteEditorState(existingNote: note)) {
                    path.removeLast(2) // pop Edit and Detail, back to the list
                    reload()
                }
            }
        }
    }

    private func reload() {
        do {
            notes = try repository.searchNotes(query: searchText)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct NoteRow: View {
    let note: Note

    @Environment(NoteRepository.self) private var repository
    @State private var thumbnail: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(firstLine)
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                Text(note.category.rawValue.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .task { await loadThumbnail() }
    }

    private var firstLine: String {
        note.extractedText
            .split(separator: "\n", omittingEmptySubsequences: true)
            .first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
            .map(String.init) ?? "(no text)"
    }

    // Downsampled off the main actor — full-resolution capture photos would jank a
    // scrolling list otherwise (same lesson learned on the Android thumbnail list).
    private func loadThumbnail() async {
        let url = repository.photoURL(for: note)
        thumbnail = await Task.detached {
            guard let image = UIImage(contentsOfFile: url.path) else { return nil }
            return image.preparingThumbnail(of: CGSize(width: 112, height: 112)) ?? image
        }.value
    }
}
