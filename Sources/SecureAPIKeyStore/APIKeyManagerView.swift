//
//  SwiftUIView.swift
//  SecureAPIKeyStore
//
//  Created by Eli Manjarrez on 5/1/25.
//

import SwiftUI

public struct APIKeyManagerView: View {
    @ObservedObject var manager: APIKeyManager
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
                        Button(action: {
                            editingService = .new
                        }) {
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
                                    Text("Active").foregroundColor(.red)
                                } else {
                                    Button("Activate") {
                                        withAnimation {
                                            manager.setCurrentService(service)
                                        }
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    .foregroundColor(.blue)
                                }
                                Button {
                                    editingService = service
                                } label: {
                                    Image(systemName: "pencil")
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let service = manager.storedServices[index]
                                manager.deleteKey(for: service)
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    .navigationTitle("API Key Manager")
                    .toolbar {
                        Button(action: {
                            editingService = .new
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(item: $editingService) { service in
                APIKeyEditorView(
                    manager: manager,
                    service: service,
                    onDismiss: {
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

    var isEditing: Bool { service != .new }

    var body: some View {
        NavigationView {
            Form {
                if isEditing {
                    Text("\(service?.displayName ?? "Unknown Service")")
                } else {
                    Picker("Service", selection: $selectedService) {
                        ForEach(Service.allCases.filter { manager.getKey(for: $0) == nil && $0 != .new }) { svc in
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
                        let svc = selectedService ?? selectedService
                        if let svc {
                            manager.saveKey(apiKey, for: svc)
                            if makeActive {
                                manager.setCurrentService(svc)
                            }
                        }
                        onDismiss()
                    }
                    .disabled(apiKey.isEmpty || (!isEditing && selectedService == nil))
                }
            }
        }
        .onAppear {
            let unsavedServices: [Service] = Service.allCases.filter { manager.getKey(for: $0) == nil && $0 != .new }
            self.selectedService = unsavedServices.first
            if let svc = service {
                apiKey = manager.getKey(for: svc) ?? ""
                makeActive = manager.currentService == svc
            }
        }
    }
}
