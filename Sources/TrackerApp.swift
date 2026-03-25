import SwiftUI

@main
struct TrackerApp: App {
    @StateObject private var trackingService = TrackingService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(trackingService)
        }
    }
}
