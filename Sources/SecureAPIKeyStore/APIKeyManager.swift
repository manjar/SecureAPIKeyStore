//
//  APIKeyManager.swift
//  SecureAPIKeyStore
//
//  Created by Eli Manjarrez on 5/1/25.
//
import Foundation
import Combine

@MainActor
public class APIKeyManager: ObservableObject {
    public static let shared = APIKeyManager()

    @Published private(set) var keys: [Service: String] = [:]
    @Published public var currentService: Service? = nil

    private let keychain = SecureKeychainHelper()
    private let currentServiceKey = "APIKeyManager.currentService"

    public init() {
        loadKeysFromKeychain()
        if let rawValue = UserDefaults.standard.string(forKey: currentServiceKey) {
            currentService = Service(rawValue: rawValue)
        }
        if currentService == nil {
            setCurrentService(.local)
        }
        if getKey(for: .local) == nil {
            saveKey("No key needed", for: .local)
        }
    }

    public func getKey(for service: Service) -> String? {
        keys[service]
    }

    public func saveKey(_ key: String, for service: Service) {
        keys[service] = key
        keychain.set(key, forKey: service.rawValue)
        objectWillChange.send()
    }

    public func deleteKey(for service: Service) {
        let wasActive = service == currentService
        keys.removeValue(forKey: service)
        keychain.delete(forKey: service.rawValue)
        if currentService == service {
            currentService = nil
        }
        // fall back on local if the active API key was deleted
        if wasActive {
            setCurrentService(.local)
        }
        objectWillChange.send()
    }

    public func setCurrentService(_ service: Service) {
        if keys[service] != nil {
            currentService = service
            UserDefaults.standard.set(service.rawValue, forKey: currentServiceKey)
        }
    }
    
    public var storedServices: [Service] {
        Service.allCases.filter { keys[$0] != nil }
    }

    private func loadKeysFromKeychain() {
        for service in Service.allCases {
            if let key = keychain.get(forKey: service.rawValue) {
                keys[service] = key
            }
        }
    }
}

public enum Service: String, CaseIterable, Identifiable, Codable, Hashable {
    case local  = "local"
    case openAI = "OpenAI"
    case gemini = "Gemini"
    case new    = "new"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .openAI: return "OpenAI"
        case .gemini: return "Gemini"
        case .local:  return "Apple Intelligence"
        case .new:    return ""
        }
    }
    
    public var apiURL: URL? {
        switch self {
        case .openAI: return URL(string: "https://platform.openai.com/")
        case .gemini: return URL(string: "https://aistudio.google.com/")
        default:
            return nil
        }
    }
}
