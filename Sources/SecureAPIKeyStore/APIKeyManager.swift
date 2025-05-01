//
//  APIKeyManager.swift
//  SecureAPIKeyStore
//
//  Created by Eli Manjarrez on 5/1/25.
//

import Foundation

@MainActor
public class APIKeyManager: ObservableObject {
    @Published public private(set) var apiKeys: [String: String] = [:]
    private let store = SecureAPIKeyStore()

    public init(serviceIdentifiers: [String]) {
        Task {
            for service in serviceIdentifiers {
                if let key = try? store.load(for: service) {
                    apiKeys[service] = key
                }
            }
        }
    }

    public func saveKey(_ key: String, for service: String) async {
        do {
            try store.save(key, for: service)
            apiKeys[service] = key
        } catch {
            print("Error saving API key for \(service): \(error)")
        }
    }

    public func deleteKey(for service: String) async {
        do {
            try store.delete(for: service)
            apiKeys.removeValue(forKey: service)
        } catch {
            print("Error deleting API key for \(service): \(error)")
        }
    }
}
