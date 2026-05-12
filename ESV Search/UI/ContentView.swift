import SwiftUI

struct ContentView: View {
    @State var queryText = ""
    @State var searchResults: [SearchResult] = []

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
            .padding()
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .onSubmit {
                Task {
                    let activeESVAPI = ESVAPI(apiKey: "868fa5f09cc5d415a2a89eeebe310942e26d31d9")
                    
                    /////////////////////////////////////////////////
                    let result = await activeESVAPI.search(queryText)
                    /////////////////////////////////////////////////

                    switch result {
                    case .success(let response):
                        searchResults = response.results
                    case .failure(let error):
                        searchResults = []
                        print(error)
                    }
                }
            }
            
            if !searchResults.isEmpty {
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
            } else {
                Text("No Search Results")
                    .font(Font.largeTitle.bold())
                Spacer()
            }
        }
    }
}

#Preview(traits: .modifier(PersistencePreviewModifier())) {
    ContentView(searchResults: SearchResult.mockedData)
        .environment(\.esvAPI, ESVAPI(apiKey: "868fa5f09cc5d415a2a89eeebe310942e26d31d9"))
}
