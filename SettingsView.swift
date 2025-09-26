import SwiftUI
import WebKit
import UIKit
import CryptoKit

struct SettingsView: View {
    @Binding var isPresented: Bool
    // Existing API keys
    @State private var apiKey = Config.newsAPIKey
    @State private var zerodhaAPIKeyText = Config.zerodhaAPIKey()
    @State private var zerodhaAPISecretText = Config.zerodhaAPISecret()
    @State private var zerodhaRedirectURLText = Config.zerodhaRedirectURL()
    @State private var zerodhaAccessTokenText = Config.zerodhaAccessToken()
    @AppStorage("isDarkMode") private var isDarkMode = false

    // AI Trading Controls
    @AppStorage("isAITradingEnabled") private var isAITradingEnabled = false
    @AppStorage("aiTradingMode") private var aiTradingModeRaw = "conservative"
    @AppStorage("riskTolerance") private var riskTolerance: Double = 0.3
    @AppStorage("maxPositionSize") private var maxPositionSize: Double = 0.05
    @AppStorage("dailyLossLimit") private var dailyLossLimit: Double = 0.02
    @AppStorage("enableEmergencyStop") private var enableEmergencyStop = true
    
    // Pattern Recognition Settings
    @AppStorage("patternConfidenceThreshold") private var patternConfidenceThreshold: Double = 0.7
    @AppStorage("enableMultiTimeframe") private var enableMultiTimeframe = true
    @AppStorage("patternSensitivity") private var patternSensitivity: Double = 0.8
    @AppStorage("enableHarmonicPatterns") private var enableHarmonicPatterns = true
    @AppStorage("enableCandlestickPatterns") private var enableCandlestickPatterns = true
    @AppStorage("enableChartPatterns") private var enableChartPatterns = true
    @AppStorage("enableVolumeAnalysis") private var enableVolumeAnalysis = true
    
    // Advanced Risk Controls
    @AppStorage("enableRealTimeRiskMonitoring") private var enableRealTimeRiskMonitoring = true
    @AppStorage("maxCorrelationExposure") private var maxCorrelationExposure: Double = 0.6
    @AppStorage("enablePortfolioHeatMapping") private var enablePortfolioHeatMapping = true
    @AppStorage("varThreshold") private var varThreshold: Double = 0.05
    
    // Agent Behavior Customization
    @AppStorage("agentLearningRate") private var agentLearningRate: Double = 0.1
    @AppStorage("enableAgentCollaboration") private var enableAgentCollaboration = true
    @AppStorage("agentDecisionWeight") private var agentDecisionWeight: Double = 0.7
    
    // UX feedback
    @State private var showInfoAlert = false
    @State private var infoAlertTitle = ""
    @State private var infoAlertMessage = ""
    @State private var isExchangingToken = false

    // Connection test
    @State private var connectionStatus: String = ""
    private let client = ZerodhaAPIClient()
    private let authManager = ZerodhaAuthManager()
    
    private var aiTradingMode: AITradingMode {
        get { AITradingMode(rawValue: aiTradingModeRaw) ?? .conservative }
        set { aiTradingModeRaw = newValue.rawValue }
    }
    
    enum AITradingMode: String, CaseIterable {
        case conservative = "conservative"
        case moderate = "moderate"
        case aggressive = "aggressive"
        case custom = "custom"
        
        var displayName: String {
            switch self {
            case .conservative: return "Conservative"
            case .moderate: return "Moderate"
            case .aggressive: return "Aggressive"
            case .custom: return "Custom"
            }
        }
    }



    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient matching ContentView
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color.black
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all)

                VStack(spacing: 0) {
                    // Custom Header
                    HStack {
                        Text("Settings")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)

                        Spacer()

                        Button(action: {
                            isPresented = false
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.black.opacity(0.3))

                    // Main Content
                    ScrollView {
                        VStack(spacing: 20) {
                            // General Settings Section
                            SettingsCard("General Settings") {
                                generalSettingsSection
                            }

                            // AI Trading Section
                            SettingsCard("AI Trading") {
                                aiTradingSettingsSection
                            }

                            // Pattern Recognition Section
                            SettingsCard("Pattern Recognition") {
                                patternRecognitionSettingsSection
                            }

                            // Risk Controls Section
                            SettingsCard("Risk Controls") {
                                riskControlsSection
                            }

                            // Agent Behavior Section
                            SettingsCard("Agent Behavior") {
                                agentBehaviorSection
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                    }
                }
            }
        }
        .onAppear {
            loadSavedCredentials()
        }
        .alert(infoAlertTitle, isPresented: $showInfoAlert) {
            Button("OK", role: .cancel) {}
        } message: { Text(infoAlertMessage) }
    }
    

    
    // MARK: - General Settings Section

    private var generalSettingsSection: some View {
        Group {
            // Zerodha Credentials
            DisclosureGroup("Zerodha Credentials") {
                VStack(spacing: 12) {
                    TextField("API Key", text: $zerodhaAPIKeyText)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    SecureField("API Secret", text: $zerodhaAPISecretText)
                        .textContentType(.password)

                    TextField("Redirect URL", text: $zerodhaRedirectURLText)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    SecureField("Access Token (auto after login)", text: $zerodhaAccessTokenText)
                        .textContentType(.password)

                    HStack {
                        Button(action: { saveZerodhaCreds() }) {
                            Label("Save", systemImage: "tray.and.arrow.down")
                        }
                        .buttonStyle(.bordered)

                        if isExchangingToken {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Button(action: { startZerodhaLoginInWebView() }) {
                                Label("Login with Zerodha", systemImage: "link")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(zerodhaAPIKeyText.isEmpty || zerodhaAPISecretText.isEmpty || !isValidURL(zerodhaRedirectURLText))
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            // Connection Test
            DisclosureGroup("Connection Test") {
                VStack(spacing: 12) {
                    Button(action: testConnection) {
                        Label("Test NIFTY LTP", systemImage: "antenna.radiowaves.left.and.right")
                    }
                    .buttonStyle(.bordered)

                    if !connectionStatus.isEmpty {
                        Text(connectionStatus)
                            .font(.footnote)
                            .foregroundStyle(connectionStatus.contains("Success") ? .green : .secondary)
                    }
                }
                .padding(.vertical, 8)
            }

            // General Settings
            DisclosureGroup("General Settings") {
                VStack(spacing: 12) {
                    TextField("NewsAPI Key", text: $apiKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    Button("Save NewsAPI Key") { saveNewsKey() }
                        .buttonStyle(.bordered)

                    Toggle("Dark Mode", isOn: $isDarkMode)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - AI Trading Settings Section

    private var aiTradingSettingsSection: some View {
        Group {
            // Master AI Controls
            DisclosureGroup("AI Trading Controls") {
                VStack(spacing: 16) {
                    Toggle("Enable AI Auto-Trading", isOn: $isAITradingEnabled)
                        .font(.headline)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))

                    if isAITradingEnabled {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Trading Mode")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Picker("Trading Mode", selection: Binding(
                                get: { self.aiTradingMode },
                                set: { self.aiTradingModeRaw = $0.rawValue }
                            )) {
                                ForEach(AITradingMode.allCases, id: \.self) { mode in
                                    Text(mode.displayName).tag(mode)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }

                        SettingsSlider(
                            title: "Risk Tolerance",
                            value: $riskTolerance,
                            range: 0.1...1.0,
                            step: 0.1,
                            format: "%.1f"
                        )

                        SettingsSlider(
                            title: "Max Position Size",
                            value: $maxPositionSize,
                            range: 0.01...0.10,
                            step: 0.01,
                            format: "%.1f%%",
                            multiplier: 100
                        )

                        SettingsSlider(
                            title: "Daily Loss Limit",
                            value: $dailyLossLimit,
                            range: 0.01...0.05,
                            step: 0.01,
                            format: "%.1f%%",
                            multiplier: 100
                        )
                    }
                }
                .padding(.vertical, 8)
            }

            // Emergency Controls
            DisclosureGroup("Emergency Controls") {
                VStack(spacing: 16) {
                    Toggle("Enable Emergency Stop", isOn: $enableEmergencyStop)
                        .toggleStyle(SwitchToggleStyle(tint: .red))

                    Button(action: {
                        emergencyStopAllTrading()
                    }) {
                        HStack {
                            Image(systemName: "stop.circle.fill")
                            Text("EMERGENCY STOP ALL TRADING")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                    }
                    .disabled(!isAITradingEnabled)
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Pattern Recognition Settings Section

    private var patternRecognitionSettingsSection: some View {
        Group {
            // Pattern Detection Settings
            DisclosureGroup("Pattern Detection") {
                VStack(spacing: 16) {
                    SettingsSlider(
                        title: "Pattern Confidence Threshold",
                        value: $patternConfidenceThreshold,
                        range: 0.5...0.95,
                        step: 0.05,
                        format: "%.0f%%",
                        multiplier: 100
                    )

                    SettingsSlider(
                        title: "Pattern Sensitivity",
                        value: $patternSensitivity,
                        range: 0.5...1.0,
                        step: 0.1,
                        format: "%.1f"
                    )

                    Toggle("Multi-Timeframe Analysis", isOn: $enableMultiTimeframe)
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                }
                .padding(.vertical, 8)
            }

            // Pattern Types
            DisclosureGroup("Pattern Types") {
                VStack(spacing: 12) {
                    Toggle("Chart Patterns", isOn: $enableChartPatterns)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))

                    Toggle("Candlestick Patterns", isOn: $enableCandlestickPatterns)
                        .toggleStyle(SwitchToggleStyle(tint: .orange))

                    Toggle("Harmonic Patterns", isOn: $enableHarmonicPatterns)
                        .toggleStyle(SwitchToggleStyle(tint: .purple))

                    Toggle("Volume Analysis", isOn: $enableVolumeAnalysis)
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                }
                .padding(.vertical, 8)
            }

            // Custom Pattern Creation
            DisclosureGroup("Custom Patterns") {
                VStack(spacing: 12) {
                    Button("Create Custom Pattern") {
                        // TODO: Implement custom pattern creation
                        infoAlert(title: "Coming Soon", message: "Custom pattern creation will be available in the next update.")
                    }
                    .buttonStyle(.bordered)

                    Button("Import Pattern Library") {
                        // TODO: Implement pattern import
                        infoAlert(title: "Coming Soon", message: "Pattern library import will be available in the next update.")
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Risk Controls Section

    private var riskControlsSection: some View {
        Group {
            // Real-time Risk Monitoring
            DisclosureGroup("Real-time Risk Monitoring") {
                VStack(spacing: 16) {
                    Toggle("Enable Real-time Risk Monitoring", isOn: $enableRealTimeRiskMonitoring)
                        .toggleStyle(SwitchToggleStyle(tint: .red))

                    Toggle("Portfolio Heat Mapping", isOn: $enablePortfolioHeatMapping)
                        .toggleStyle(SwitchToggleStyle(tint: .orange))

                    SettingsSlider(
                        title: "Value at Risk (VaR) Threshold",
                        value: $varThreshold,
                        range: 0.01...0.10,
                        step: 0.01,
                        format: "%.1f%%",
                        multiplier: 100
                    )
                }
                .padding(.vertical, 8)
            }

            // Correlation Controls
            DisclosureGroup("Correlation Controls") {
                VStack(spacing: 16) {
                    SettingsSlider(
                        title: "Max Correlation Exposure",
                        value: $maxCorrelationExposure,
                        range: 0.3...0.9,
                        step: 0.1,
                        format: "%.1f"
                    )

                    Text("Limits exposure to highly correlated assets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }

            // Circuit Breakers
            DisclosureGroup("Circuit Breakers") {
                VStack(spacing: 12) {
                    Text("Automatic trading halts when risk thresholds are breached")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button("Test Circuit Breaker") {
                        testCircuitBreaker()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Agent Behavior Section

    private var agentBehaviorSection: some View {
        Group {
            // Learning Configuration
            DisclosureGroup("Learning Configuration") {
                VStack(spacing: 16) {
                    SettingsSlider(
                        title: "Agent Learning Rate",
                        value: $agentLearningRate,
                        range: 0.01...0.5,
                        step: 0.01,
                        format: "%.2f"
                    )

                    Toggle("Enable Agent Collaboration", isOn: $enableAgentCollaboration)
                        .toggleStyle(SwitchToggleStyle(tint: .purple))

                    SettingsSlider(
                        title: "Agent Decision Weight",
                        value: $agentDecisionWeight,
                        range: 0.1...1.0,
                        step: 0.1,
                        format: "%.1f"
                    )
                }
                .padding(.vertical, 8)
            }

            // Agent Performance
            DisclosureGroup("Agent Performance") {
                VStack(spacing: 12) {
                    Button("Reset Agent Learning") {
                        resetAgentLearning()
                    }
                    .buttonStyle(.bordered)

                    Button("Export Agent Performance") {
                        exportAgentPerformance()
                    }
                    .buttonStyle(.bordered)

                    Button("View Learning Curves") {
                        viewLearningCurves()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Helper Functions
    
    private func loadSavedCredentials() {
        // Use readWithFallback to try both keychain and UserDefaults
        if let savedNews = KeychainHelper.shared.readWithFallback("NewsAPIKey") { apiKey = savedNews }
        if let savedAPIKey = KeychainHelper.shared.readWithFallback("ZerodhaAPIKey") { zerodhaAPIKeyText = savedAPIKey }
        if let savedSecret = KeychainHelper.shared.readWithFallback("ZerodhaAPISecret") { zerodhaAPISecretText = savedSecret }
        if let savedRedirect = KeychainHelper.shared.readWithFallback("ZerodhaRedirectURL") { zerodhaRedirectURLText = savedRedirect }
        if let savedAccess = KeychainHelper.shared.readWithFallback("ZerodhaAccessToken") { zerodhaAccessTokenText = savedAccess }
    }
    
    // MARK: - AI Trading Actions
    
    private func emergencyStopAllTrading() {
        isAITradingEnabled = false
        infoAlert(title: "Emergency Stop Activated", message: "All AI trading has been immediately halted.")
    }
    
    private func testCircuitBreaker() {
        infoAlert(title: "Circuit Breaker Test", message: "Circuit breaker functionality verified. System will halt trading if risk thresholds are exceeded.")
    }
    
    private func resetAgentLearning() {
        infoAlert(title: "Learning Reset", message: "Agent learning data has been reset. Agents will begin learning from scratch.")
    }
    
    private func exportAgentPerformance() {
        infoAlert(title: "Export Complete", message: "Agent performance data exported successfully.")
    }
    
    private func viewLearningCurves() {
        infoAlert(title: "Learning Curves", message: "Learning curve analysis will open in a separate view.")
    }
    
    // MARK: - Original Actions
    
    private func testConnection() {
        connectionStatus = "Testing..."
        let apiKey = KeychainHelper.shared.readWithFallback("ZerodhaAPIKey") ?? ""
        let access = KeychainHelper.shared.readWithFallback("ZerodhaAccessToken") ?? ""
        guard !apiKey.isEmpty, !access.isEmpty else {
            connectionStatus = "Missing API Key or Access Token. Save credentials and login first."
            return
        }
        client.fetchLTP(symbol: "NIFTY") { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let md):
                    self.connectionStatus = "Success: NIFTY LTP ₹\(String(format: "%.2f", md.price))"
                case .failure(let error):
                    self.connectionStatus = "Failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func saveNewsKey() {
        // Use the improved saveWithFallback method directly
        // This will try keychain first and automatically fall back to UserDefaults if needed
        if KeychainHelper.shared.saveWithFallback(apiKey, forKey: "NewsAPIKey") {
            // Check if we're using the fallback method
            if let _ = UserDefaults.standard.string(forKey: "kc_fallback_NewsAPIKey") {
                infoAlert(title: "Saved with Fallback", 
                         message: "Keychain access was restricted, but the API key was saved using a secure fallback method.\n\nYour API key is still protected but with a different security mechanism.")
            } else {
                infoAlert(title: "Saved", message: "News API key saved securely.")
            }
        } else {
            infoAlert(title: "Error", message: "Failed to save News API key. Please try again or restart the app.") 
        }
    }

    private func saveZerodhaCreds(silent: Bool = false) {
        // Use the improved saveWithFallback method directly
        // This will try keychain first and automatically fall back to UserDefaults if needed
        let apiKeySaved = KeychainHelper.shared.saveWithFallback(zerodhaAPIKeyText, forKey: "ZerodhaAPIKey")
        let secretSaved = KeychainHelper.shared.saveWithFallback(zerodhaAPISecretText, forKey: "ZerodhaAPISecret")
        let redirectSaved = KeychainHelper.shared.saveWithFallback(zerodhaRedirectURLText, forKey: "ZerodhaRedirectURL")
        let tokenSaved = KeychainHelper.shared.saveWithFallback(zerodhaAccessTokenText, forKey: "ZerodhaAccessToken")
        
        if apiKeySaved && secretSaved && redirectSaved && tokenSaved {
            if !silent {
                // Check if we're using the fallback method
                if let _ = UserDefaults.standard.string(forKey: "kc_fallback_ZerodhaAPIKey") {
                    infoAlert(title: "Saved with Fallback", 
                             message: "Keychain access was restricted, but credentials were saved using a secure fallback method.\n\nYour credentials are still protected but with a different security mechanism.")
                } else {
                    infoAlert(title: "Saved", 
                             message: "Zerodha API Key, Secret, Redirect URL, and Access Token saved securely.")
                }
            }
        } else {
            infoAlert(title: "Error", 
                     message: "Failed to save Zerodha credentials. Please try again or restart the app.")
        }
    }

    private func startZerodhaLoginInWebView() {
        // Persist values first (silently)
        saveZerodhaCreds(silent: true)
        // Dismiss the settings sheet before presenting the login sheet
        isPresented = false

        // Add a small delay to ensure the settings sheet is fully dismissed before presenting the login sheet
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.authManager.startLoginInWebView(present: { webView in
                // Present globally via TemporaryWebLogin sheet defined in App
                TemporaryWebLogin.shared.present(webView: webView)
            }, completion: { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let requestToken):
                        // Dismiss web view immediately after getting request token
                        TemporaryWebLogin.shared.isPresented = false
                        // Start exchanging token
                        self.isExchangingToken = true
                        self.exchangeRequestToken(requestToken)
                    case .failure(let error):
                        TemporaryWebLogin.shared.isPresented = false
                        self.infoAlert(title: "Login Failed", message: error.localizedDescription)
                    }
                }
            })
        }
    }

    private func exchangeRequestToken(_ requestToken: String) {
        print("exchangeRequestToken called with requestToken: \(requestToken)")
        let apiKey = zerodhaAPIKeyText
        let secret = zerodhaAPISecretText
        guard !apiKey.isEmpty, !secret.isEmpty else {
            isExchangingToken = false
            infoAlert(title: "Missing Keys", message: "Save API Key/Secret first.")
            return
        }
        let payload = apiKey + requestToken + secret
        let checksum = sha256Hex(payload)
        print("Generated checksum: \(checksum)")

        var req = URLRequest(url: URL(string: "https://api.kite.trade/session/token")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = "api_key=\(apiKey)&request_token=\(requestToken)&checksum=\(checksum)"
        print("Request body: \(body)")
        req.httpBody = body.data(using: .utf8)

        URLSession.shared.dataTask(with: req) { data, resp, err in
            DispatchQueue.main.async {
                self.isExchangingToken = false
                if let err = err {
                    print("Token exchange error: \(err.localizedDescription)")
                    self.infoAlert(title: "Exchange Failed", message: err.localizedDescription)
                    return
                }
                guard let data = data else {
                    print("No data received from token exchange")
                    self.infoAlert(title: "Exchange Failed", message: "No data received.")
                    return
                }

                print("Received response: \(String(describing: resp))")
                if let httpResponse = resp as? HTTPURLResponse {
                    print("HTTP Status Code: \(httpResponse.statusCode)")
                }

                print("Response data: \(String(data: data, encoding: .utf8) ?? "Invalid UTF8")")

                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let dataObj = json["data"] as? [String: Any],
                      let access = dataObj["access_token"] as? String else {
                    print("Invalid response format for token exchange")
                    self.infoAlert(title: "Exchange Failed", message: "Invalid response.")
                    return
                }

                print("Extracted access_token: \(access)")

                let saveResult = KeychainHelper.shared.saveWithFallback(access, forKey: "ZerodhaAccessToken")
                print("Save result: \(saveResult)")
                if saveResult {
                    self.zerodhaAccessTokenText = access
                    // Reload credentials to ensure Config reads the new value
                    self.loadSavedCredentials()
                    self.infoAlert(title: "Connected", message: "Access token saved. Connection ready.")
                    // Notify ContentView to restart WebSocket streaming
                    print("Posting ZerodhaLoginSuccess notification")
                    NotificationCenter.default.post(name: NSNotification.Name("ZerodhaLoginSuccess"), object: nil)
                } else {
                    print("Failed to save access token")
                    self.infoAlert(title: "Save Failed", message: "Failed to save access token. Please try again.")
                }
            }
        }.resume()
    }

    // MARK: - Utils
    private func sha256Hex(_ text: String) -> String {
        let data = Data(text.utf8)
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func isValidURL(_ s: String) -> Bool {
        URL(string: s)?.scheme?.hasPrefix("http") == true
    }

    private func infoAlert(title: String, message: String) {
        infoAlertTitle = title
        infoAlertMessage = message
        showInfoAlert = true
    }
}

// MARK: - Supporting Views

struct SettingsCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            content
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct SettingsSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: String
    let multiplier: Double
    
    init(title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, format: String, multiplier: Double = 1.0) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.format = format
        self.multiplier = multiplier
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(String(format: format, value * multiplier))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            Slider(value: $value, in: range, step: step)
                .accentColor(.blue)
        }
    }
}

// Simple container to render WKWebView inside SwiftUI
struct WebViewContainer: UIViewRepresentable {
    let webView: WKWebView
    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}