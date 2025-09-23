import SwiftUI

struct SettingsView: View {
    @State private var apiKey = Config.newsAPIKey

    var body: some View {
        Form {
            Section(header: Text("API Configuration")) {
                TextField("NewsAPI Key", text: $apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            Section(header: Text("App Settings")) {
                Toggle("Dark Mode", isOn: .constant(false))
                Button("Save Settings") {
                    // Save settings logic
                }
            }
        }
        .navigationTitle("Settings")
    }
}
