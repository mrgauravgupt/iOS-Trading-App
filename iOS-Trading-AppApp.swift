import SwiftUI
import WebKit

@main
struct iOS_Trading_AppApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @StateObject private var webLogin = TemporaryWebLogin.shared
    
    init() {
        // Initialize notification manager
        _ = NotificationManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .sheet(isPresented: $webLogin.isPresented) {
                    NavigationView {
                        if let wv = webLogin.webView {
                            WebViewContainer(webView: wv)
                                .navigationTitle("Zerodha Login")
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarLeading) {
                                        Button("Cancel") {
                                            webLogin.isPresented = false
                                        }
                                    }
                                }
                        } else {
                            VStack {
                                ProgressView("Loading...")
                                    .scaleEffect(1.5)
                                Text("Preparing login...")
                                    .padding(.top)
                            }
                            .navigationTitle("Zerodha Login")
                            .navigationBarTitleDisplayMode(.inline)
                        }
                    }
                }
        }
    }
}
