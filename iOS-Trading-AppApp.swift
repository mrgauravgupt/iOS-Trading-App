import SwiftUI
import WebKit

@main
struct iOS_Trading_AppApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @StateObject private var webLogin = TemporaryWebLogin.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .sheet(isPresented: $webLogin.isPresented) {
                    if let wv = webLogin.webView {
                        WebViewContainer(webView: wv)
                            .edgesIgnoringSafeArea(.bottom)
                    } else {
                        ProgressView("Loading...")
                    }
                }
        }
    }
}
