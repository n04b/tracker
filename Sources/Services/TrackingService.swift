import Foundation
import CoreLocation
import UIKit
import Combine

@MainActor
public class TrackingService: ObservableObject {
    public static let shared = TrackingService()
    
    @Published public var servers: [ServerConfig] = [] {
        didSet {
            checkTrackingState()
        }
    }
    @Published public var lastSendDate: Date?
    @Published public var isTracking: Bool = false
    
    private var timer: Timer?
    public let locationService = LocationService()
    
    private var lastSentLocationTimestamp: Date?
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        loadServers()
        locationService.$lastLocation
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        checkTrackingState()
    }
    
    private func checkTrackingState() {
        let hasActiveServers = servers.contains { $0.isActive }
        if hasActiveServers {
            if !isTracking {
                isTracking = true
                startTracking()
            }
        } else {
            if isTracking {
                isTracking = false
                stopTracking()
            }
        }
    }
    
    public func startTracking() {
        locationService.requestPermissions()
        locationService.startUpdatingLocation()
        
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    await self?.tick()
                }
            }
        }
    }
    
    public func stopTracking() {
        locationService.stopUpdatingLocation()
        timer?.invalidate()
        timer = nil
    }
    
    private func tick() async {
        guard let location = locationService.lastLocation else { return }
        
        // Prevent sending the exact same location ping if it hasn't updated
        if let lastTimestamp = lastSentLocationTimestamp, lastTimestamp == location.timestamp {
            return
        }
        
        let payload = createPayload(from: location)
        var anySuccess = false
        
        let activeServers = servers.filter { $0.isActive }
        guard !activeServers.isEmpty else { return }
        
        for server in activeServers {
            guard let url = server.url else { continue }
            do {
                try await NetworkService.shared.send(payload: payload, to: url)
                anySuccess = true
                print("Successfully sent to \(server.name)")
            } catch {
                print("Failed to send to \(server.name): \(error)")
            }
        }
        
        if anySuccess {
            self.lastSendDate = Date()
            self.lastSentLocationTimestamp = location.timestamp
        }
    }
    
    private func createPayload(from location: CLLocation) -> LocationPayload {
        let identifierForVendor = UIDevice.current.identifierForVendor?.uuidString
        let ms = Int64(location.timestamp.timeIntervalSince1970 * 1000)
        
        let level = UIDevice.current.batteryLevel
        let batteryLevel: Float? = level >= 0 ? level : nil
        var batteryStateStr: String?
        switch UIDevice.current.batteryState {
        case .unplugged: batteryStateStr = "unplugged"
        case .charging: batteryStateStr = "charging"
        case .full: batteryStateStr = "full"
        default: batteryStateStr = nil
        }
        
        return LocationPayload(
            identifierForVendor: identifierForVendor,
            lat: location.coordinate.latitude,
            lon: location.coordinate.longitude,
            accuracy: location.horizontalAccuracy,
            altitude: location.altitude,
            speed: location.speed >= 0 ? location.speed : nil,
            heading: location.course >= 0 ? location.course : nil,
            batteryLevel: batteryLevel,
            batteryState: batteryStateStr,
            timestamp: ms
        )
    }
    
    // MARK: - Persistence
    
    private let serversKey = "saved_servers"
    
    public func saveServers() {
        if let data = try? JSONEncoder().encode(servers) {
            UserDefaults.standard.set(data, forKey: serversKey)
        }
    }
    
    public func addServer(name: String, urlString: String) {
        let server = ServerConfig(name: name, urlString: urlString)
        servers.append(server)
        saveServers()
    }
    
    public func updateServer(_ server: ServerConfig) {
        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            servers[index] = server
            saveServers()
        }
    }
    
    public func toggleServerActive(_ id: UUID) {
        if let index = servers.firstIndex(where: { $0.id == id }) {
            servers[index].isActive.toggle()
            saveServers()
        }
    }
    
    private func loadServers() {
        if let data = UserDefaults.standard.data(forKey: serversKey),
           let decoded = try? JSONDecoder().decode([ServerConfig].self, from: data) {
            self.servers = decoded
        }
    }
}
