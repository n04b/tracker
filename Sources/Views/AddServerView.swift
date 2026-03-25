import SwiftUI

struct AddServerView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var trackingService: TrackingService
    
    @Binding var editingServer: ServerConfig?
    
    @State private var name: String = ""
    @State private var urlString: String = ""
    @State private var isActive: Bool = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Server Details")) {
                    TextField("Name (e.g., Primary Relay)", text: $name)
                    TextField("URL (e.g., https://example.com/api/location)", text: $urlString)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Toggle("Active", isOn: $isActive)
                }
            }
            .navigationTitle(editingServer == nil ? "Add Server" : "Edit Server")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    save()
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(name.isEmpty || urlString.isEmpty || URL(string: urlString) == nil)
            )
            .onAppear {
                if let server = editingServer {
                    name = server.name
                    urlString = server.urlString
                    isActive = server.isActive
                }
            }
        }
    }
    
    private func save() {
        if let server = editingServer {
            var updated = server
            updated.name = name
            updated.urlString = urlString
            updated.isActive = isActive
            trackingService.updateServer(updated)
        } else {
            let newServer = ServerConfig(name: name, urlString: urlString, isActive: isActive)
            trackingService.servers.append(newServer)
            trackingService.saveServers()
        }
    }
}
