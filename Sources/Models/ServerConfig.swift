import Foundation

public struct ServerConfig: Identifiable, Codable, Equatable {
    public var id: UUID = UUID()
    public var name: String
    public var urlString: String
    public var isActive: Bool
    
    public var url: URL? {
        URL(string: urlString)
    }
    
    public init(id: UUID = UUID(), name: String, urlString: String, isActive: Bool = true) {
        self.id = id
        self.name = name
        self.urlString = urlString
        self.isActive = isActive
    }
}
