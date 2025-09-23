import SwiftUI

@main
struct iOS_Trading_AppApp: App {
    @State private var isDarkMode = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
