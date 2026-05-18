import SwiftUI
import CoreData

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
            .padding(EdgeInsets(top: 0, leading: 50, bottom: 0, trailing: 50))
            .onSubmit {
                queryActivated = true
            }
            .task(id: queryActivated) {
                queryActivated = false // reset search flag
                
                // One character is not a suitable search value, so we won't start search with less than 2 characters. There are valid 2 letter searches, Eg Og
                if queryText.count < 2 {
                    searchResults = [] // Entering an empty search string should clear results
                    return
                }
                
                // Here, we should first determine if we have this query cached in local storage (presently Core Data)
                searchResults = await fetchSearchesInLocalContext(context, forQuery: queryText)
                
                if searchResults.isEmpty {
                    // If no locally stored matches, then fetch results from server
                    searchResults = await fetchMatchesFromServerIntoContext(context, forQuery: queryText)
                }
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


private func fetchSearchesInLocalContext(_ context: NSManagedObjectContext, forQuery text: String) async -> [SearchResult] {
    let fetchRequest: NSFetchRequest<SearchResultEntity> = SearchResultEntity.fetchRequest()
    var searchResult = [SearchResult]()
    var aResult: SearchResult

    do {
        let matches = try context.fetch(fetchRequest)
        for match in matches {
            aResult = SearchResult(reference: match.reference ?? "missing reference", content: match.content ?? "missing content")
            searchResult.append(aResult)
        }
    } catch {
        print("Failed to match items: \(error)")
    }
    
    return searchResult
}


private func fetchMatchesFromServerIntoContext(_ context: NSManagedObjectContext, forQuery text: String) async -> [SearchResult] {
                    
    /////////////////////////////////////////////////
    let result = await activeESVAPI.search(text)
    /////////////////////////////////////////////////
    
    switch result {
    case .success(let response):
        if !response.results.isEmpty {
            // We need to cache these search results locally, so do it here...
            for match in response.results {
                let searchData = SearchResultEntity(context: context)
                searchData.query = text
                searchData.reference = match.reference
                searchData.content = match.content
                //searchData.createdAt = Date()
            }
            
            do {
                try context.save()
            } catch {
                // We could politely handle the error appropriately, but the failure makes the ultimate solution needing to fetch again from the server.
            }
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
