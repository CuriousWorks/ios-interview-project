import Foundation

struct ESVAPI {
    
    let apiKey: String

    /// Search the ESV API for a given term.
    ///
    /// Example usage:
    ///
    /// ```swift
    /// let result = await ESVAPI.search("God")
    /// switch result {
    ///     case .success(let results):
    ///         print(results)
    ///     case .failure(let error):
    ///         print(error)
    /// }
    /// ```

    /// - Parameter query: The String to search for.
    /// - Returns: a `Result` containing ``SearchResults`` if successful, or an ``APIError`` if unsuccessful.
    func search(_ query: String) async -> Result<SearchResults, APIError> {

        let url = URL(string: "\(ESVKeys.baseUrl)/search/")!
            .appending(queryItems: [
                .init(name: "q", value: query),
                .init(name: "page-size", value: "100")
            ])
        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "Authorization")

        do {
            /////////////////////////////////////////////////////////////////////
            let (data, response) = try await URLSession.shared.data(for: request)
            /////////////////////////////////////////////////////////////////////

            guard let httpResponse = response as? HTTPURLResponse else { return .failure(.unknownError(data)) }

            switch httpResponse.statusCode {
                case 200 ... 299:
                    do {
                        let response = try JSONDecoder().decode(SearchResults.self, from: data)
                        return .success(response)
                    }
                    catch {
                        print("Error loading data: \(error)")
                        return .failure(.invalid)
                    }

                case 400:
                    return .failure(.badRequest(data))
                case 401:
                    return .failure(.unauthorized(data))
                case 404:
                    return .failure(.notFound(data))
                default:
                    return .failure(.unknownError(data))
            }

        } catch {
            return .failure(.networkError)
        }
    }
    
}

enum APIError: Error, Sendable {
    case networkError
    case cancelled
    case invalid
    case badRequest(_ data: Data? = nil)
    case unauthorized(_ data: Data? = nil)
    case notFound(_ data: Data? = nil)
    case unknownError(_ data: Data? = nil)
}
