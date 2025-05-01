//
//  SwiftUIView.swift
//  SecureAPIKeyStore
//
//  Created by Eli Manjarrez on 5/1/25.
//

import SwiftUI

public struct APIKeyManagerView: View {
    @StateObject private var keyManager: APIKeyManager
    @State private var newKey = ""
    @State private var selectedService: String

    private let services: [String]

    public init(services: [String]) {
        self.services = services
        self._selectedService = State(initialValue: services.first ?? "")
        self._keyManager = StateObject(wrappedValue: APIKeyManager(serviceIdentifiers: services))
    }

    public var body: some View {
        NavigationView {
            Form {
                Picker("Service", selection: $selectedService) {
                    ForEach(services, id: \.self) { service in
                        Text(service)
                    }
                }

                Section(header: Text("Enter API Key")) {
                    TextField("Paste API key here", text: $newKey)
                        .textContentType(.password)
//                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    Button("Save API Key") {
                        Task {
                            await keyManager.saveKey(newKey, for: selectedService)
                            newKey = ""
                        }
                    }
                }

                Section(header: Text("Saved Keys")) {
                    ForEach(services, id: \.self) { service in
                        if let key = keyManager.apiKeys[service] {
                            HStack {
                                Text(service)
                                Spacer()
                                Text("••••\(key.suffix(4))")
                                    .foregroundColor(.gray)
                                Button(role: .destructive) {
                                    Task {
                                        await keyManager.deleteKey(for: service)
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        } else {
                            Text("\(service): No key saved")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("API Key Manager")
        }
    }
}
