import Foundation
import WebKit

protocol ZerodhaAuthenticator {
    func startLoginInWebView(present: @escaping (_ webView: WKWebView) -> Void,
                             completion: @escaping (Result<String, Error>) -> Void)
}

/// WKWebView-based auth for a 100% on-device flow.
/// Intercepts final redirect to registered HTTPS redirect URL and extracts request_token for exchange.
final class ZerodhaAuthManager: NSObject, ZerodhaAuthenticator, WKNavigationDelegate {
    private var completion: ((Result<String, Error>) -> Void)?
    private var redirectHost: String = ""
    private var redirectPath: String = ""

    func startLoginInWebView(present: @escaping (_ webView: WKWebView) -> Void,
                             completion: @escaping (Result<String, Error>) -> Void) {
        let apiKey = Config.zerodhaAPIKey()
        guard !apiKey.isEmpty else {
            completion(.failure(NSError(domain: "Zerodha", code: 400, userInfo: [NSLocalizedDescriptionKey: "Missing Zerodha API key."])) )
            return
        }
        self.completion = completion
        // Parse configured redirect URL for match
        if let redirect = URL(string: Config.zerodhaRedirectURL()) {
            self.redirectHost = redirect.host ?? ""
            self.redirectPath = redirect.path
        }
        var components = URLComponents(string: "https://kite.trade/connect/login")!
        components.queryItems = [
            URLQueryItem(name: "v", value: "3"),
            URLQueryItem(name: "api_key", value: apiKey)
        ]
        guard let url = components.url else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }

        let webView = WKWebView()
        webView.navigationDelegate = self
        webView.configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        webView.load(URLRequest(url: url))
        present(webView)
    }

    // Intercept final redirect and extract request_token
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.allow); return }
        if let host = url.host, host == redirectHost, url.path == redirectPath,
           let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let requestToken = comps.queryItems?.first(where: { $0.name == "request_token" })?.value {
            decisionHandler(.cancel)
            completion?(.success(requestToken))
            self.completion = nil
            return
        }
        decisionHandler(.allow)
    }
}