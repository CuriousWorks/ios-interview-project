import SwiftUI
import CoreData

struct ContentView: View {
    @State var queryText = ""
    @State var isQueryActivated = false
    @State var searchResults: [SearchResult] = []
    @State var dataSource = DataSource.server
    @State var statusMessage = "Pending"
    @Environment(\.managedObjectContext) private var context
 
    // Retrieve matches from the local device
    private func fetchSearchesInLocalContext(_ context: NSManagedObjectContext, forQuery searchString: String) async -> [SearchResult] {
        let fetchRequest: NSFetchRequest<SearchResultEntity> = SearchResultEntity.fetchRequest()
        var fetchResults = [SearchResult]()
        var searchResult: SearchResult

        do {
            fetchRequest.predicate = NSPredicate(format: "query == %@", searchString)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
            let matches = try context.fetch(fetchRequest)
            for match in matches {
                searchResult = SearchResult(reference: match.reference ?? "missing reference", content: match.content ?? "missing content")
                fetchResults.append(searchResult)
                match.lastSearch = Date()
            }
            try context.save() // Update the lastSearch date on device
            dataSource = DataSource.device
        } catch {
            print("Failed to match items: \(error)")
        }
        
        return fetchResults
    }

    // Retrieve matches from the server, and cache results locally on the device
    private func fetchMatchesFromServerIntoContext(_ context: NSManagedObjectContext, forQuery searchString: String) async -> [SearchResult] {
                        
        /////////////////////////////////////////////////
        let result = await activeESVAPI.search(searchString)
        /////////////////////////////////////////////////
        
        switch result {
        case .success(let response):
            if !response.results.isEmpty {
                // Cache search results locally
                // Add index to preserve sequence (otherwise not sortable)
                for (index, match) in response.results.enumerated() {
                    let searchData = SearchResultEntity(context: context)
                    searchData.index = Int16(index)
                    searchData.query = searchString
                    searchData.reference = match.reference
                    searchData.content = match.content
                    searchData.lastSearch = Date() // This can be used for a stale date to remove search results older than an arbitrary time, eg. older than 30 days.
                }
                
                do {
                    try context.save()
                    dataSource = DataSource.server
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

    var body: some View {
        VStack {
            // Banner
            Group {
                Text("Crossway")
                    .font(Font.largeTitle.bold())
                
                Text("Interview Challenge")
                    .font(.headline)
            }
            
            // Search Field
            TextField(
                "Search",
                text: $queryText
            )
            .padding(EdgeInsets(top: 0, leading: 50, bottom: 0, trailing: 50))
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .onSubmit {
                // Toggle the task to run with the current search term.
                isQueryActivated = true
            }
            .task(id: isQueryActivated) {
                // Resetting isQueryActivated within the task refires the task. If the query is not activated, do not run the task.
                if isQueryActivated == false { return }

                // One character is not a suitable search value, so we won't start search with less than 2 characters.
                // There are valid 2 letter searches, eg Og
                if queryText.count < 2 {
                    searchResults = [] // Entering an empty search string should clear results
                    return
                }
                
                // Here, first determine if this query cached in local storage (presently using Core Data)
                searchResults = await fetchSearchesInLocalContext(context, forQuery: queryText)
                
                // If the query has not already been cached, the search results will be empty,
                // and the server will be called upon for the search data.
                if searchResults.isEmpty {
                    searchResults = await fetchMatchesFromServerIntoContext(context, forQuery: queryText)
                }
                
                isQueryActivated = false // Reset search flag so that the search field is ready for another search to be run.
           }
            
            // Set the status message based on the current state
            Text(isQueryActivated
                 ? "Searching..."
                 : searchResults.isEmpty
                     ? "No matches found"
                    // Determine if the search results are from the local device or the remote server
                     : dataSource == .server
                         ? "\(searchResults.count) Matches Found on Server"
                         : "\(searchResults.count) Matches Found on Device")
                .font(.headline)
            
            // When the searchResults are updated, refresh the list.
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

#Preview(traits: .modifier(PersistencePreviewModifier())) {
    ContentView(searchResults: SearchResult.mockedData)
        .environment(\.esvAPI, ESVAPI(apiKey: ESVKeys.apiKey))
}
