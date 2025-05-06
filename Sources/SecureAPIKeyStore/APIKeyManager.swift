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
        keys.removeValue(forKey: service)
        keychain.delete(forKey: service.rawValue)
        if currentService == service {
            currentService = nil
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
    case openAI = "OpenAI"
    case gemini = "Gemini"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .openAI: return "OpenAI"
        case .gemini: return "Gemini"
        }
    }
}
