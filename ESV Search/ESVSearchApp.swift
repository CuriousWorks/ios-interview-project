import SwiftUI

@main
struct ESVSearchApp: App {

    let persistenceController = PersistenceController.shared
    let api = ESVAPI(apiKey: "868fa5f09cc5d415a2a89eeebe310942e26d31d9")

    var body: some Scene {
        WindowGroup {
            ContentView(queryText: "", searchResults: [])
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environment(\.esvAPI, api)
        }
    }
}

extension EnvironmentValues {
    @Entry var esvAPI: ESVAPI?
}
