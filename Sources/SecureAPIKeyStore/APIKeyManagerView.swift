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
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                // Column 1: Name expands
                                Text(service.displayName)
                                    .lineLimit(1)
                                    .truncationMode(.tail)

                                Spacer(minLength: 8)

                                // Column 2: Status (fixed width, right aligned)
                                Group {
                                    if manager.currentService == service {
                                        Text("Active")
                                            .foregroundColor(.red)
                                            .frame(width: 90, alignment: .trailing)
                                    } else {
                                        Button("Activate") {
                                            withAnimation { manager.setCurrentService(service) }
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                        .foregroundColor(.blue)
                                        .frame(width: 90, alignment: .trailing)
                                    }
                                }

                                // Column 3: Edit (fixed width, right aligned)
                                Group {
                                    if service != .local {
                                        Button {
                                            editingService = service
                                        } label: {
                                            Image(systemName: "pencil")
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                        .frame(width: 28, alignment: .trailing)
                                    } else {
                                        // keep column width even when hidden
                                        Color.clear.frame(width: 28, height: 1)
                                    }
                                }
                            }
                            .deleteDisabled(service == .local)
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
#if DEBUG
                    .toolbar {
                        Button(action: {
                            for service in Service.allCases {
                                switch service {
                                case .local, .new:
                                    break
                                default:
                                    _ = manager.deleteKey(for: service)
                                }
                            }
                            APIKeyManager.shared.setCurrentService(.local)
                        }) {
                            Image(systemName: "x.circle")
                        }
                    }
#endif
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

    @State private var selectedService: Service = .local
    @State private var apiKey: String = ""
    @State private var makeActive = false
    @State private var showDeletionConfirmation = false
    @Environment(\.openURL) private var openURL

    // A secure field with a built-in clear (x) button on the trailing edge
    private struct ClearableSecureField: View {
        @Binding var text: String
        var title: String

        var body: some View {
            ZStack(alignment: .trailing) {
                SecureField(title, text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .padding(.trailing, 30) // space for button
                if !text.isEmpty {
                    Button(action: { text.removeAll() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .imageScale(.medium)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Clear text")
                    .padding(.trailing, 4)
                }
            }
        }
    }

    var isEditing: Bool { service != .new }

    var body: some View {
        NavigationView {
            Form {
                if isEditing {
                    Text("\(service?.displayName ?? "Unknown Service")")
                } else {
                    Picker("Service", selection: $selectedService) {
                        ForEach(Service.allCases.filter { manager.getKey(for: $0) == nil && $0 != .new }) { svc in
                            Text(svc.displayName).tag(svc)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                ClearableSecureField(text: $apiKey, title: "API Key")
                Toggle("Make Active", isOn: $makeActive)
                Section {
                    Button {
                        if let url = isEditing ? service?.apiURL : selectedService.apiURL {
                            openURL(url)
                        }
                    } label: {
                        Label("Get a key", systemImage: "safari")
                    }
                } footer: {
                    Text("Launches Safari to help you obtain an API key")
                }
                if isEditing, let service, service != .local {
                    Section {
                        Button("Delete", role: .destructive) {
                            showDeletionConfirmation = true
                        }
                        .confirmationDialog(
                            "Are you sure you want to delete this item?",
                            isPresented: $showDeletionConfirmation,
                            titleVisibility: .visible
                        ) {
                            Button("Delete", role: .destructive) {
                                manager.deleteKey(for: service)
                                onDismiss()
                            }
                            Button("Cancel", role: .cancel) {
                                showDeletionConfirmation = false
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit API Key" : "Add API Key")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onDismiss)
                }
                if let service {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let targetService: Service = isEditing ? (service ?? selectedService) : selectedService
                            manager.saveKey(apiKey, for: targetService)
                            if makeActive {
                                manager.setCurrentService(targetService)
                            }
                            onDismiss()
                        }
                        .disabled(apiKey.isEmpty)
                    }
                }
            }
        }
        .onAppear {
            let unsavedServices: [Service] = Service.allCases.filter { manager.getKey(for: $0) == nil && $0 != .new }
            self.selectedService = unsavedServices.first ?? .local
            if let svc = service {
                apiKey = manager.getKey(for: svc) ?? ""
                makeActive = manager.currentService == svc || !isEditing
            }
        }
    }
}

