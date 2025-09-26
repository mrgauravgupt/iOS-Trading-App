import SwiftUI
import AuthenticationServices
import UIKit
import WebKit
import CryptoKit

struct LoginView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var isLoggingIn = false
    @State private var showSuccess = false
    @State private var isExchangingToken = false
    private let authManager = ZerodhaAuthManager()

    var body: some View {
        VStack(spacing: 16) {
            Text("Zerodha Login Required").font(.title2).fontWeight(.semibold)
            Text("Enter API key and complete login to obtain an access token.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            CredentialsFields()
            Button(action: startLogin) {
                if isLoggingIn { ProgressView() } else { Text("Login with Zerodha") }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoggingIn || (Config.zerodhaAPIKey().isEmpty))
            Text("Login requires valid Zerodha API key and will open the official login page. After login, your access token will be fetched automatically.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .alert("Connected", isPresented: $showSuccess) {
            Button("OK") { presentationMode.wrappedValue.dismiss() }
        } message: {
            Text("Access token saved. You're connected to Kite.")
        }
    }

    private func startLogin() {
        guard !Config.zerodhaAPIKey().isEmpty else { return }
        isLoggingIn = true
        // Present WKWebView-based login; after redirect, auto-exchange request_token -> access_token.
        authManager.startLoginInWebView(present: { webView in
            // Show SwiftUI sheet with the provided webview
            DispatchQueue.main.async {
                TemporaryWebLogin.shared.present(webView: webView)
            }
        }, completion: { result in
            DispatchQueue.main.async {
                isLoggingIn = false
                switch result {
                case .success(let requestToken):
                    // Dismiss web view immediately after getting request token
                    TemporaryWebLogin.shared.isPresented = false
                    // Start exchanging token
                    isExchangingToken = true
                    exchangeRequestToken(requestToken)
                case .failure(let error):
                    TemporaryWebLogin.shared.isPresented = false
                    print("Login failed: \(error.localizedDescription)")
                }
            }
        })
    }

    // Exchange request_token for access_token and persist it
    private func exchangeRequestToken(_ requestToken: String) {
        let apiKey = Config.zerodhaAPIKey()
        let secret = Config.zerodhaAPISecret()
        guard !apiKey.isEmpty, !secret.isEmpty else {
            isExchangingToken = false
            print("Missing API Key/Secret; save them in Settings first.")
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
            DispatchQueue.main.async {
                self.isExchangingToken = false
                if let err = err { print("Exchange failed: \(err.localizedDescription)"); return }
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let dataObj = json["data"] as? [String: Any],
                      let access = dataObj["access_token"] as? String else {
                    print("Exchange failed: Invalid response")
                    return
                }
                do {
                    _ = try KeychainHelper.shared.save(access, forKey: "ZerodhaAccessToken")
                    // Show success alert; dismiss on OK
                    self.showSuccess = true
                } catch {
                    print("Keychain save error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

    private func sha256Hex(_ text: String) -> String {
        let data = Data(text.utf8)
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}

private struct CredentialsFields: View {
    @State private var apiKey = Config.zerodhaAPIKey()
    @State private var accessToken = Config.zerodhaAccessToken()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Zerodha API Key", text: $apiKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            SecureField("Access Token (optional; will be filled after login)", text: $accessToken)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            HStack {
                Button("Save") {
                    do {
                        _ = try KeychainHelper.shared.save(apiKey, forKey: "ZerodhaAPIKey")
                        _ = try KeychainHelper.shared.save(accessToken, forKey: "ZerodhaAccessToken")
                    } catch {
                        print("Keychain save error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

// Helper presenter to show a SwiftUI sheet for the WKWebView without UIKit plumbing spread around
final class TemporaryWebLogin: ObservableObject {
    static let shared = TemporaryWebLogin()
    @Published var isPresented = false
    private(set) var webView: WKWebView?

    func present(webView: WKWebView) {
        self.webView = webView
        self.isPresented = true
    }
}

// Minimal ASWebAuthenticationPresentationContextProviding adapter (kept for ASWebAuth if needed later)
final class AuthPresentationProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Best-effort: return the first key window
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}