import Foundation
import Security

class AuthManager {
    static let shared = AuthManager()

    func authenticateWithTOTP(username: String, password: String, totp: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "\(Config.apiBaseURL)/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["username": username, "password": password, "totp": totp]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            do {
                let response = try JSONDecoder().decode([String: String].self, from: data)
                if let token = response["token"] {
                    completion(.success(token))
                } else {
                    completion(.failure(NSError(domain: "No token", code: 0)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func storeCredentials(username: String, password: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: username,
            kSecValueData as String: password.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    func retrieveCredentials(username: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: username,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var dataTypeRef: AnyObject? = nil
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == noErr {
            return String(data: dataTypeRef as! Data, encoding: .utf8)
        }
        return nil
    }
}
