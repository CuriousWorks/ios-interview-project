import SwiftUI
import CoreData

enum ESVKeys {
    // Constants
    static let apiKey: String = "868fa5f09cc5d415a2a89eeebe310942e26d31d9"
    static let baseUrl: String = "https://api.esv.org/v3/passage"
}

enum DataSource {
    case device
    case server
}

let activeESVAPI = ESVAPI(apiKey: ESVKeys.apiKey)

@main
struct ESVSearchApp: App {

    let persistenceController = PersistenceController.shared
    let api = ESVAPI(apiKey: ESVKeys.apiKey)

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
