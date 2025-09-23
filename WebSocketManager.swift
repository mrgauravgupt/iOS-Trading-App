import Foundation

class WebSocketManager: NSObject, URLSessionWebSocketDelegate {
    private var webSocketTask: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
    var onMessageReceived: ((String) -> Void)?

    func connect(to url: URL) {
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.delegate = self
        webSocketTask?.resume()
        receiveMessage()
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }

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
