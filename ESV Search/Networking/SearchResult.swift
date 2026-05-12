import Foundation

struct SearchResult : Identifiable {
    var id = UUID()
    var reference: String
    var content: String
}

extension SearchResult: Codable {
    enum CodingKeys: String, CodingKey {
        case reference
        case content
    }

    static let mockedData = [
        SearchResult(
            reference: "Genesis 1:1",
            content: "In the beginning, God created the heavens and the earth."),
        SearchResult(
            reference: "John 1:1",
            content: "In the beginning was the Word, and the Word was with God, and the Word was God."),
        SearchResult(
            reference: "1 John 1:1",
            content: "That which was from the beginning, which we have heard, which we have seen with our eyes, which we looked upon and have touched with our hands, concerning the word of life –")
    ]
}
