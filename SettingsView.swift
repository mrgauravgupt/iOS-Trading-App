import SwiftUI
import WebKit
import UIKit
import CryptoKit

struct SettingsView: View {
    // Existing keys
    @State private var apiKey = Config.newsAPIKey
    @State private var zerodhaAPIKeyText = Config.zerodhaAPIKey()
    @State private var zerodhaAPISecretText = Config.zerodhaAPISecret()
    @State private var zerodhaRedirectURLText = Config.zerodhaRedirectURL()
    @State private var zerodhaAccessTokenText = Config.zerodhaAccessToken()
    @AppStorage("isDarkMode") private var isDarkMode = false

    // UX feedback
    @State private var showInfoAlert = false
    @State private var infoAlertTitle = ""
    @State private var infoAlertMessage = ""

    // Connection test
    @State private var connectionStatus: String = ""
    private let client = ZerodhaAPIClient()
    private let authManager = ZerodhaAuthManager()

    // Web login sheet
    @State private var showWebLogin = false
    @State private var webView: WKWebView? = nil

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Header
                    VStack(spacing: 4) {
                        Text("Kite Connect Setup")
                            .font(.title)
                            .fontWeight(.semibold)
                        Text("Securely connect your Zerodha account")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    // Card: Zerodha Credentials
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Zerodha Credentials")
                            .font(.headline)
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
                        TextField("Redirect URL (must match in Zerodha console)", text: $zerodhaRedirectURLText)
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
                            Button(action: saveZerodhaCreds) {
                                Label("Save", systemImage: "tray.and.arrow.down")
                            }
                            .buttonStyle(.bordered)

                            Button(action: { startZerodhaLoginInWebView() }) {
                                Label("Login with Zerodha", systemImage: "link")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(zerodhaAPIKeyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                      zerodhaAPISecretText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                      !isValidURL(zerodhaRedirectURLText))
                        }
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Card: Test Connection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Connection Test")
                            .font(.headline)
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
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Card: News API & Appearance
                    VStack(alignment: .leading, spacing: 12) {
                        Text("General Settings")
                            .font(.headline)
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
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Spacer(minLength: 24)
                }
                .padding(.horizontal)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Settings")
        }
        .onAppear {
            if let savedNews = KeychainHelper.shared.read("NewsAPIKey") { apiKey = savedNews }
            if let savedAPIKey = KeychainHelper.shared.read("ZerodhaAPIKey") { zerodhaAPIKeyText = savedAPIKey }
            if let savedSecret = KeychainHelper.shared.read("ZerodhaAPISecret") { zerodhaAPISecretText = savedSecret }
            if let savedRedirect = KeychainHelper.shared.read("ZerodhaRedirectURL") { zerodhaRedirectURLText = savedRedirect }
            if let savedAccess = KeychainHelper.shared.read("ZerodhaAccessToken") { zerodhaAccessTokenText = savedAccess }
        }
        .alert(infoAlertTitle, isPresented: $showInfoAlert) {
            Button("OK", role: .cancel) {}
        } message: { Text(infoAlertMessage) }
        .sheet(isPresented: $showWebLogin) {
            NavigationView {
                ZStack {
                    if let wv = webView {
                        WebViewContainer(webView: wv)
                            .edgesIgnoringSafeArea(.bottom)
                    } else {
                        ProgressView("Loading...")
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") { showWebLogin = false }
                    }
                }
            }
            .presentationDetents([.large])
        }
    }

    // MARK: - Actions
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
        do { _ = try KeychainHelper.shared.save(apiKey, forKey: "NewsAPIKey")
            infoAlert(title: "Saved", message: "News API key saved to Keychain.")
        } catch { infoAlert(title: "Error", message: "Failed to save News API key: \(error.localizedDescription)") }
    }

    private func saveZerodhaCreds() {
        do {
            _ = try KeychainHelper.shared.save(zerodhaAPIKeyText, forKey: "ZerodhaAPIKey")
            _ = try KeychainHelper.shared.save(zerodhaAPISecretText, forKey: "ZerodhaAPISecret")
            _ = try KeychainHelper.shared.save(zerodhaRedirectURLText, forKey: "ZerodhaRedirectURL")
            _ = try KeychainHelper.shared.save(zerodhaAccessTokenText, forKey: "ZerodhaAccessToken")
            infoAlert(title: "Saved", message: "Zerodha API Key, Secret, Redirect URL, and Access Token saved.")
        } catch {
            infoAlert(title: "Error", message: "Failed to save Zerodha creds: \(error.localizedDescription)")
        }
    }

    private func startZerodhaLoginInWebView() {
        // Persist values first
        saveZerodhaCreds()
        authManager.startLoginInWebView(present: { webView in
            self.webView = webView
            self.showWebLogin = true
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
                    self.showWebLogin = false
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

// Simple container to render WKWebView inside SwiftUI
struct WebViewContainer: UIViewRepresentable {
    let webView: WKWebView
    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}