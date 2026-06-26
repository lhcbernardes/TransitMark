//
//  SettingsView.swift
//  TransitMark
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(PreferenceKey.colorScheme) private var colorSchemeChoice: String = "system"
    @AppStorage(PreferenceKey.language) private var languageChoice: String = "pt"

    @State private var showingTipJar = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Idioma") {
                    Picker("Idioma", selection: $languageChoice) {
                        Text("Português").tag("pt")
                        Text("English").tag("en")
                        Text("Español").tag("es")
                    }
                    .pickerStyle(.menu)
                }

                Section("Aparência") {
                    Picker("Tema", selection: $colorSchemeChoice) {
                        Text("Sistema").tag("system")
                        Text("Claro").tag("light")
                        Text("Escuro").tag("dark")
                    }
                    .pickerStyle(.segmented)
                }

                Section("Apoiar") {
                    Button {
                        showingTipJar = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.pink)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Apoiar o desenvolvedor")
                                    .foregroundStyle(.primary)
                                Text("Manter o TransitMark em desenvolvimento")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fechar") { dismiss() }
                }
            }
            .sheet(isPresented: $showingTipJar) {
                TipJarView()
            }
        }
    }
}

#Preview {
    SettingsView()
}
