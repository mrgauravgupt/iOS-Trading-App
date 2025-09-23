import Foundation

class WebSocketManager: NSObject, URLSessionWebSocketDelegate {
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession!
    var onMessageReceived: ((String) -> Void)?

    override init() {
        super.init()
        if #available(iOS 15.0, *) {
            // Initialize session with delegate for iOS 15+
            session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue.main)
        } else {
            // Fallback for older iOS versions
            session = URLSession(configuration: .default)
        }
    }
    
    @available(iOS 15.0, *)
    func connect(to url: URL) {
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.delegate = self
        webSocketTask?.resume()
        receiveMessage()
    }

    func disconnect() {
        if #available(iOS 15.0, *) {
            webSocketTask?.cancel(with: .goingAway, reason: nil)
        }
    }

    @available(iOS 15.0, *)
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("WebSocket error: \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.onMessageReceived?(text)
                case .data(let data):
                    print("Received data: \(data)")
                @unknown default:
                    break
                }
                self?.receiveMessage() // Continue receiving
            }
        }
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket connected")
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket closed")
    }

    @available(iOS 15.0, *)
    func connectToZerodhaWebSocket(token: String) {
        let url = URL(string: "wss://ws.kite.trade/?token=\(token)")!
        connect(to: url)
    }

    func parseMessage(_ message: String) -> MarketData? {
        // Placeholder for parsing WebSocket message
        // This would parse the JSON message and return MarketData
        return nil
    }

    func startDataStreaming() {
        // Placeholder for starting data streaming pipeline
        // This would integrate with Zerodha WebSocket and process data
    }
}