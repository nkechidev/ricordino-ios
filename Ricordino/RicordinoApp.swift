//
//  RicordinoApp.swift
//  Ricordino
//
//  Created by Nkechi Nnaji on 7/31/26.
//

import SwiftUI
import SwiftData

@main
struct RicordinoApp: App {
    let modelContainer: ModelContainer
    let dependencies: AppDependencies

    init() {
        let schema = Schema([Note.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        self.modelContainer = container
        self.dependencies = AppDependencies(modelContext: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            NotesListView()
                .environment(dependencies.repository)
        }
        .modelContainer(modelContainer)
    }
}
