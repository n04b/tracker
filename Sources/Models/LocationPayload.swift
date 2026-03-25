import Foundation

public struct LocationPayload: Codable, Equatable {
    public let identifierForVendor: String?
    public let lat: Double
    public let lon: Double
    public let accuracy: Double?
    public let altitude: Double?
    public let speed: Double?
    public let heading: Double?
    public let batteryLevel: Float?
    public let batteryState: String?
    public let timestamp: Int64
    
    public init(identifierForVendor: String?, lat: Double, lon: Double, accuracy: Double?, altitude: Double?, speed: Double?, heading: Double?, batteryLevel: Float?, batteryState: String?, timestamp: Int64) {
        self.identifierForVendor = identifierForVendor
        self.lat = lat
        self.lon = lon
        self.accuracy = accuracy
        self.altitude = altitude
        self.speed = speed
        self.heading = heading
        self.batteryLevel = batteryLevel
        self.batteryState = batteryState
        self.timestamp = timestamp
    }
}
