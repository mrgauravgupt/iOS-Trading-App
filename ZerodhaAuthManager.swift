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

        // Configure a fresh, non-persistent WKWebView to avoid process/config issues
        let config = WKWebViewConfiguration()
        config.processPool = WKProcessPool()
        config.websiteDataStore = .nonPersistent()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = .clear
        // Present on main thread first, then load
        DispatchQueue.main.async {
            present(webView)
            webView.load(URLRequest(url: url))
        }
    }

    // Intercept final redirect and extract request_token
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.allow); return }

        // Build components once
        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let scheme = url.scheme?.lowercased() ?? ""
        let host = url.host ?? ""
        let path = url.path.isEmpty ? "/" : url.path

        // Normalize configured redirect path (treat empty as "/" and trim trailing slash)
        let configuredPath = redirectPath.isEmpty ? "/" : redirectPath
        func normalize(_ p: String) -> String { p == "/" ? "/" : p.trimmingCharacters(in: CharacterSet(charactersIn: "/")) }

        // Determine if this navigation is the final redirect back to our app
        let isHTTPOrHTTPS = (scheme == "http" || scheme == "https")
        let looksLikeConfiguredHTTPS = isHTTPOrHTTPS && !redirectHost.isEmpty &&
            host.caseInsensitiveCompare(redirectHost) == .orderedSame &&
            normalize(path) == normalize(configuredPath)

        // If the redirect uses a custom app scheme (e.g., myapp://), WKWebView cannot open it.
        // Treat any non-http(s) URL as the final redirect we should intercept.
        let isCustomSchemeRedirect = !isHTTPOrHTTPS

        if looksLikeConfiguredHTTPS || isCustomSchemeRedirect {
            if let requestToken = comps?.queryItems?.first(where: { $0.name == "request_token" })?.value {
                decisionHandler(.cancel)
                completion?(.success(requestToken))
                self.completion = nil
                return
            }
        }

        decisionHandler(.allow)
    }
}