import SwiftUI


struct ContentView: View {
    @State var queryText = ""
    @State var queryActivated = false
    @State var searchResults: [SearchResult] = []
    @Environment(\.managedObjectContext) private var context


    var body: some View {
        
        VStack {
            Text("Crossway")
                .font(Font.largeTitle.bold())
            
            Text("Interview Challenge")
                .font(.headline)
            
            TextField(
                "Search",
                text: $queryText
            )
            .onSubmit {
                queryActivated = true
            }
            .task(id: queryActivated) {
                queryActivated = false // reset search flag
                
                if queryText.count < 2 { // One character is not a suitable search value
                    searchResults = [] // Entering an empty search string should clear results
                    return
                }
                
                // Here, we should first determine if we have this query cached in local storage.
                // If not, then fetch results from server
                searchResults = await fetchMatchesFromServer(query: queryText)
            }
            
            Text("\(searchResults.count) matches found")
                .font(.headline)
            
            List(searchResults) {
                Text($0.reference)
                    .font(.title2.bold())
                    .listRowSeparator(.hidden)
                Text($0.content)
                    .font(.title2)
                    .listRowSeparator(.visible)
                    .listRowInsets(.init(top: 0,
                                         leading: 36,
                                         bottom: 12,
                                         trailing: 0))
            }
            .searchable(text: $queryText, prompt: "Search")
        }
    }
}

func fetchMatchesFromServer(query text: String) async -> [SearchResult] {
                    
    /////////////////////////////////////////////////
    let result = await activeESVAPI.search(text)
    /////////////////////////////////////////////////
    
    switch result {
    case .success(let response):
        if !response.results.isEmpty {
            // We need to cache these search results locally, but for now...
            return response.results
        }
    case .failure(let error):
        print(error)
    }
    return []
}

#Preview(traits: .modifier(PersistencePreviewModifier())) {
    ContentView(searchResults: SearchResult.mockedData)
        .environment(\.esvAPI, ESVAPI(apiKey: ESVKeys.apiKey))
}
