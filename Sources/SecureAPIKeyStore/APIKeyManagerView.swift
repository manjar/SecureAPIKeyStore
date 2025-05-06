//
//  SwiftUIView.swift
//  SecureAPIKeyStore
//
//  Created by Eli Manjarrez on 5/1/25.
//

import SwiftUI

public struct APIKeyManagerView: View {
    @ObservedObject var manager: APIKeyManager
    @State private var showEditor = false
    @State private var editingService: Service? = nil

    public init(manager: APIKeyManager) {
        self.manager = manager
    }

    public var body: some View {
        NavigationView {
            VStack {
                if manager.storedServices.isEmpty {
                    VStack(spacing: 16) {
                        Text("Your API keys will be saved here.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Button(action: { showEditor = true }) {
                            Label("Add API Key", systemImage: "plus")
                        }
                    }
                } else {
                    List {
                        ForEach(manager.storedServices, id: \..self) { service in
                            HStack {
                                Text(service.displayName)
                                Spacer()
                                if manager.currentService == service {
                                    Text("In Use").foregroundColor(.blue)
                                } else {
                                    Button("Use") {
                                        manager.setCurrentService(service)
                                    }
                                }
                                Button("Edit") {
                                    editingService = service
                                    showEditor = true
                                }
                                Button(role: .destructive) {
                                    manager.deleteKey(for: service)
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    .navigationTitle("API Key Manager")
                    .toolbar {
                        Button(action: { showEditor = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                APIKeyEditorView(
                    manager: manager,
                    service: editingService,
                    onDismiss: {
                        showEditor = false
                        editingService = nil
                    }
                )
            }
        }
    }
}

// MARK: - APIKeyEditorView

struct APIKeyEditorView: View {
    @ObservedObject var manager: APIKeyManager
    var service: Service?
    var onDismiss: () -> Void

    @State private var selectedService: Service? = nil
    @State private var apiKey: String = ""
    @State private var makeActive = false

    var isEditing: Bool { service != nil }

    var body: some View {
        NavigationView {
            Form {
                if !isEditing {
                    Picker("Service", selection: $selectedService) {
                        ForEach(Service.allCases.filter { manager.getKey(for: $0) == nil }) { svc in
                            Text(svc.displayName).tag(Optional(svc))
                        }
                    }
                }

                SecureField("API Key", text: $apiKey)
                Toggle("Make Active", isOn: $makeActive)
            }
            .navigationTitle(isEditing ? "Edit API Key" : "Add API Key")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onDismiss)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let svc = service ?? selectedService
                        if let svc {
                            manager.saveKey(apiKey, for: svc)
                            if makeActive {
                                manager.setCurrentService(svc)
                            }
                        }
                        onDismiss()
                    }.disabled(apiKey.isEmpty || (!isEditing && selectedService == nil))
                }
            }
        }
        .onAppear {
            selectedService = service
            if let svc = service {
                apiKey = manager.getKey(for: svc) ?? ""
                makeActive = manager.currentService == svc
            }
        }
    }
}
