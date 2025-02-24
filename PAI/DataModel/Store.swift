import Combine
import Foundation
import CryptoKit
import Security

class SessionConfigStore: ObservableObject {
    @Published var sessionConfig: SessionConfig
    private var cancellables = Set<AnyCancellable>()
    
    private let configKey = "sessionConfig"
    private let keychainKey = "com.example.myapp.sessionConfigEncryptionKey"
    private let encryptionKey: SymmetricKey
    
    init() {
        // Retrieve or generate the encryption key from the Keychain.
        if let keyData = KeychainHelper.load(key: keychainKey) {
            encryptionKey = SymmetricKey(data: keyData)
        } else {
            let newKey = SymmetricKey(size: .bits256)
            let newKeyData = newKey.withUnsafeBytes { Data($0) }
            let saved = KeychainHelper.save(key: keychainKey, data: newKeyData)
            if saved {
                encryptionKey = newKey
            } else {
                fatalError("Unable to save encryption key in Keychain")
            }
        }
        
        // Load the encrypted config from UserDefaults.
        if let data = UserDefaults.standard.data(forKey: configKey),
           let decryptedData = try? Self.decrypt(data: data, using: encryptionKey),
           let decodedConfig = try? JSONDecoder().decode(SessionConfig.self, from: decryptedData) {
            self.sessionConfig = decodedConfig
        } else {
            self.sessionConfig = SessionConfig() // Fallback to default settings.
        }
        
        // Subscribe to changes on sessionConfig so that when it changes, we save the config.
        $sessionConfig
            .sink { [weak self] _ in
                self?.saveConfig()
            }
            .store(in: &cancellables)
    }
    
    private func saveConfig() {
        if let encoded = try? JSONEncoder().encode(sessionConfig),
           let encrypted = try? Self.encrypt(data: encoded, using: encryptionKey) {
            UserDefaults.standard.set(encrypted, forKey: configKey)
        }
    }
    
    // Encrypts the data using AES-GCM.
    private static func encrypt(data: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        let nonceData = sealedBox.nonce.withUnsafeBytes { Data($0) }
        var combinedData = nonceData
        combinedData.append(sealedBox.ciphertext)
        combinedData.append(sealedBox.tag)
        return combinedData
    }
    
    // Decrypts data previously encrypted with AES-GCM.
    private static func decrypt(data: Data, using key: SymmetricKey) throws -> Data {
        let nonceSize = 12
        let tagSize = 16
        
        guard data.count > nonceSize + tagSize else {
            throw NSError(domain: "DecryptionError", code: -1, userInfo: nil)
        }
        
        let nonceData = data.prefix(nonceSize)
        let tagData = data.suffix(tagSize)
        let ciphertext = data.dropFirst(nonceSize).dropLast(tagSize)
        
        let nonce = try AES.GCM.Nonce(data: nonceData)
        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tagData)
        return try AES.GCM.open(sealedBox, using: key)
    }
}

// Keychain helper for reading and writing data.
class KeychainHelper {
    static func save(key: String, data: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        // Remove any existing item.
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    static func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue as Any,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == errSecSuccess {
            return dataTypeRef as? Data
        }
        return nil
    }
}
