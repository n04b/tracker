import Foundation

public struct NetworkError: Error {
    public let message: String
}

public class NetworkService {
    public static let shared = NetworkService()
    
    private let urlSession: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        self.urlSession = URLSession(configuration: config)
    }
    
    public func send(payload: LocationPayload, to url: URL) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(payload)
        request.httpBody = data
        
        let (_, response) = try await urlSession.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            throw NetworkError(message: "HTTP Status Code: \(httpResponse.statusCode)")
        }
    }
}
