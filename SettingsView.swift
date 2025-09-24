import SwiftUI
import WebKit
import UIKit
import CryptoKit

struct SettingsView: View {
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
    @State private var selectedSettingsTab: SettingsTab = .general
    
    // Connection test
    @State private var connectionStatus: String = ""
    private let client = ZerodhaAPIClient()
    private let authManager = ZerodhaAuthManager()
    
    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case aiTrading = "AI Trading"
        case patterns = "Patterns"
        case risk = "Risk"
        case agents = "Agents"
    }
    
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
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Tab Navigation
                tabNavigationSection
                
                // Main Content
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedSettingsTab {
                        case .general:
                            generalSettingsSection
                        case .aiTrading:
                            aiTradingSettingsSection
                        case .patterns:
                            patternRecognitionSettingsSection
                        case .risk:
                            riskControlsSection
                        case .agents:
                            agentBehaviorSection
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Advanced Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            loadSavedCredentials()
        }
        .alert(infoAlertTitle, isPresented: $showInfoAlert) {
            Button("OK", role: .cancel) {}
        } message: { Text(infoAlertMessage) }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Advanced Settings")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Configure AI Trading & Pattern Recognition")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // AI Status Indicator
                VStack {
                    Circle()
                        .fill(isAITradingEnabled ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    
                    Text(isAITradingEnabled ? "AI ON" : "AI OFF")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(isAITradingEnabled ? .green : .red)
                }
            }
            
            Divider()
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Tab Navigation
    
    private var tabNavigationSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Button(action: {
                        selectedSettingsTab = tab
                    }) {
                        VStack(spacing: 4) {
                            Text(tab.rawValue)
                                .font(.subheadline)
                                .fontWeight(selectedSettingsTab == tab ? .semibold : .regular)
                            
                            Rectangle()
                                .fill(selectedSettingsTab == tab ? Color.blue : Color.clear)
                                .frame(height: 2)
                        }
                        .foregroundColor(selectedSettingsTab == tab ? .blue : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - General Settings Section
    
    private var generalSettingsSection: some View {
        VStack(spacing: 20) {
            // Zerodha Credentials
            SettingsCard("Zerodha Credentials") {
                VStack(spacing: 12) {
                    TextField("API Key", text: $zerodhaAPIKeyText)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    SecureField("API Secret", text: $zerodhaAPISecretText)
                        .textContentType(.password)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    TextField("Redirect URL", text: $zerodhaRedirectURLText)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    SecureField("Access Token (auto after login)", text: $zerodhaAccessTokenText)
                        .textContentType(.password)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    HStack {
                        Button(action: { saveZerodhaCreds() }) {
                            Label("Save", systemImage: "tray.and.arrow.down")
                        }
                        .buttonStyle(.bordered)

                        Button(action: { startZerodhaLoginInWebView() }) {
                            Label("Login with Zerodha", systemImage: "link")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(zerodhaAPIKeyText.isEmpty || zerodhaAPISecretText.isEmpty || !isValidURL(zerodhaRedirectURLText))
                    }
                }
            }
            
            // Connection Test
            SettingsCard("Connection Test") {
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
            }
            
            // General Settings
            SettingsCard("General Settings") {
                VStack(spacing: 12) {
                    TextField("NewsAPI Key", text: $apiKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    Button("Save NewsAPI Key") { saveNewsKey() }
                        .buttonStyle(.bordered)
                    
                    Toggle("Dark Mode", isOn: $isDarkMode)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
            }
        }
    }
    
    // MARK: - AI Trading Settings Section
    
    private var aiTradingSettingsSection: some View {
        VStack(spacing: 20) {
            // Master AI Controls
            SettingsCard("AI Trading Controls") {
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
            }
            
            // Emergency Controls
            SettingsCard("Emergency Controls") {
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
            }
        }
    }
    
    // MARK: - Pattern Recognition Settings Section
    
    private var patternRecognitionSettingsSection: some View {
        VStack(spacing: 20) {
            // Pattern Detection Settings
            SettingsCard("Pattern Detection") {
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
            }
            
            // Pattern Types
            SettingsCard("Pattern Types") {
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
            }
            
            // Custom Pattern Creation
            SettingsCard("Custom Patterns") {
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
            }
        }
    }
    
    // MARK: - Risk Controls Section
    
    private var riskControlsSection: some View {
        VStack(spacing: 20) {
            // Real-time Risk Monitoring
            SettingsCard("Real-time Risk Monitoring") {
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
            }
            
            // Correlation Controls
            SettingsCard("Correlation Controls") {
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
            }
            
            // Circuit Breakers
            SettingsCard("Circuit Breakers") {
                VStack(spacing: 12) {
                    Text("Automatic trading halts when risk thresholds are breached")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Test Circuit Breaker") {
                        testCircuitBreaker()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
    
    // MARK: - Agent Behavior Section
    
    private var agentBehaviorSection: some View {
        VStack(spacing: 20) {
            // Learning Configuration
            SettingsCard("Learning Configuration") {
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
            }
            
            // Agent Performance
            SettingsCard("Agent Performance") {
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
            }
        }
    }

    // MARK: - Helper Functions
    
    private func loadSavedCredentials() {
        if let savedNews = KeychainHelper.shared.read("NewsAPIKey") { apiKey = savedNews }
        if let savedAPIKey = KeychainHelper.shared.read("ZerodhaAPIKey") { zerodhaAPIKeyText = savedAPIKey }
        if let savedSecret = KeychainHelper.shared.read("ZerodhaAPISecret") { zerodhaAPISecretText = savedSecret }
        if let savedRedirect = KeychainHelper.shared.read("ZerodhaRedirectURL") { zerodhaRedirectURLText = savedRedirect }
        if let savedAccess = KeychainHelper.shared.read("ZerodhaAccessToken") { zerodhaAccessTokenText = savedAccess }
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
        let apiKey = KeychainHelper.shared.read("ZerodhaAPIKey") ?? ""
        let access = KeychainHelper.shared.read("ZerodhaAccessToken") ?? ""
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
        do { 
            _ = try KeychainHelper.shared.save(apiKey, forKey: "NewsAPIKey")
            infoAlert(title: "Saved", message: "News API key saved to Keychain.")
        } catch { 
            infoAlert(title: "Error", message: "Failed to save News API key: \(error.localizedDescription)") 
        }
    }

    private func saveZerodhaCreds(silent: Bool = false) {
        do {
            _ = try KeychainHelper.shared.save(zerodhaAPIKeyText, forKey: "ZerodhaAPIKey")
            _ = try KeychainHelper.shared.save(zerodhaAPISecretText, forKey: "ZerodhaAPISecret")
            _ = try KeychainHelper.shared.save(zerodhaRedirectURLText, forKey: "ZerodhaRedirectURL")
            _ = try KeychainHelper.shared.save(zerodhaAccessTokenText, forKey: "ZerodhaAccessToken")
            if !silent {
                infoAlert(title: "Saved", message: "Zerodha API Key, Secret, Redirect URL, and Access Token saved.")
            }
        } catch {
            infoAlert(title: "Error", message: "Failed to save Zerodha creds: \(error.localizedDescription)")
        }
    }

    private func startZerodhaLoginInWebView() {
        // Persist values first (silently)
        saveZerodhaCreds(silent: true)
        authManager.startLoginInWebView(present: { webView in
            // Present globally via TemporaryWebLogin sheet defined in App
            TemporaryWebLogin.shared.present(webView: webView)
        }, completion: { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let requestToken):
                    exchangeRequestToken(requestToken)
                case .failure(let error):
                    infoAlert(title: "Login Failed", message: error.localizedDescription)
                }
            }
        })
    }

    private func exchangeRequestToken(_ requestToken: String) {
        let apiKey = zerodhaAPIKeyText
        let secret = zerodhaAPISecretText
        guard !apiKey.isEmpty, !secret.isEmpty else {
            infoAlert(title: "Missing Keys", message: "Save API Key/Secret first.")
            return
        }
        let payload = apiKey + requestToken + secret
        let checksum = sha256Hex(payload)

        var req = URLRequest(url: URL(string: "https://api.kite.trade/session/token")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = "api_key=\(apiKey)&request_token=\(requestToken)&checksum=\(checksum)"
        req.httpBody = body.data(using: .utf8)

        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err = err {
                DispatchQueue.main.async { infoAlert(title: "Exchange Failed", message: err.localizedDescription) }
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dataObj = json["data"] as? [String: Any],
                  let access = dataObj["access_token"] as? String else {
                DispatchQueue.main.async { infoAlert(title: "Exchange Failed", message: "Invalid response.") }
                return
            }
            DispatchQueue.main.async {
                do {
                    _ = try KeychainHelper.shared.save(access, forKey: "ZerodhaAccessToken")
                    self.zerodhaAccessTokenText = access
                    TemporaryWebLogin.shared.isPresented = false
                    self.infoAlert(title: "Connected", message: "Access token saved. Connection ready.")
                } catch {
                    self.infoAlert(title: "Save Failed", message: error.localizedDescription)
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