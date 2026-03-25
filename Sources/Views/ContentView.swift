import SwiftUI
import CoreLocation

struct ContentView: View {
    @EnvironmentObject var trackingService: TrackingService
    @State private var showingAddServer = false
    @State private var editingServer: ServerConfig? = nil
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Live Coordinates")) {
                    if let location = trackingService.locationService.lastLocation {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(formatCoordinate(location.coordinate.latitude, isLat: true))
                                .font(.system(size: 34, weight: .bold))
                            Text(formatCoordinate(location.coordinate.longitude, isLat: false))
                                .font(.system(size: 34, weight: .bold))
                        }
                        .padding(.vertical, 8)
                        
                        if let lastSend = trackingService.lastSendDate {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                Text("Last update: \(lastSend, style: .relative) ago")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Waiting for location...")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: HStack {
                    Text("Configured Servers")
                    Spacer()
                    Text("Long-press to edit").font(.caption).foregroundColor(.secondary).textCase(.none)
                }, footer: Text("Servers marked with green are currently transmitting live coordinate data.")) {
                    ForEach(trackingService.servers) { server in
                        ServerRow(server: server)
                            .onLongPressGesture {
                                editingServer = server
                                showingAddServer = true
                            }
                    }
                    .onDelete(perform: deleteServer)
                    
                    Button {
                        editingServer = nil
                        showingAddServer = true
                    } label: {
                        Label("Add Server", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Toggle("Track", isOn: $trackingService.isTracking)
                        .onChange(of: trackingService.isTracking) { newValue in
                            if newValue {
                                trackingService.startTracking()
                            } else {
                                trackingService.stopTracking()
                            }
                        }
                        .labelsHidden()
                }
            }
            .sheet(isPresented: $showingAddServer) {
                AddServerView(editingServer: $editingServer)
            }
        }
    }
    
    private func deleteServer(at offsets: IndexSet) {
        trackingService.servers.remove(atOffsets: offsets)
        trackingService.saveServers()
    }
    
    private func formatCoordinate(_ value: Double, isLat: Bool) -> String {
        let direction = isLat ? (value >= 0 ? "N" : "S") : (value >= 0 ? "E" : "W")
        return String(format: "%.4f° %@", abs(value), direction)
    }
}

struct ServerRow: View {
    let server: ServerConfig
    @EnvironmentObject var trackingService: TrackingService
    
    var body: some View {
        HStack {
            Circle()
                .fill(server.isActive ? Color.green : Color.red)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading) {
                Text(server.name)
                    .font(.headline)
                Text(server.urlString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { server.isActive },
                set: { _ in trackingService.toggleServerActive(server.id) }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}
