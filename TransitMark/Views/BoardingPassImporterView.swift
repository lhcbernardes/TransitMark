//
//  BoardingPassImporterView.swift
//  TransitMark
//

import SwiftUI
import SwiftData
import FoundationModels

struct BoardingPassImporterView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let trip: Trip

    private let model = SystemLanguageModel.default

    @State private var inputText = ""
    @State private var state: ImportState = .idle

    private enum ImportState {
        case idle
        case extracting
        case preview(ExtractedBoardingPass)
        case error(String)
    }

    var body: some View {
        NavigationStack {
            Group {
                switch model.availability {
                case .available:
                    mainContent
                case .unavailable(.appleIntelligenceNotEnabled):
                    unavailableView(
                        icon: "sparkles",
                        title: "Apple Intelligence necessário",
                        message: "Ative em Ajustes → Apple Intelligence & Siri."
                    )
                case .unavailable(.deviceNotEligible):
                    unavailableView(
                        icon: "iphone.slash",
                        title: "Dispositivo incompatível",
                        message: "Esta função requer um iPhone com suporte ao Apple Intelligence."
                    )
                case .unavailable(.modelNotReady):
                    unavailableView(
                        icon: "arrow.down.circle",
                        title: "Modelo em preparação",
                        message: "O Apple Intelligence ainda está sendo instalado. Tente novamente em instantes."
                    )
                case .unavailable:
                    unavailableView(
                        icon: "exclamationmark.triangle",
                        title: "Indisponível",
                        message: "O Apple Intelligence não está disponível no momento."
                    )
                }
            }
            .navigationTitle("Importar boarding pass")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }

    // MARK: - State views

    @ViewBuilder
    private var mainContent: some View {
        switch state {
        case .idle, .error:
            inputView
        case .extracting:
            loadingView
        case .preview(let pass):
            previewView(pass)
        }
    }

    private var inputView: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    TextEditor(text: $inputText)
                        .frame(minHeight: 180)
                        .font(.system(.footnote, design: .monospaced))
                } header: {
                    Text("Texto do cartão de embarque")
                } footer: {
                    Text("Cole o conteúdo copiado do app da companhia aérea, de um e-mail de confirmação ou de um PDF.")
                }

                if case .error(let msg) = state {
                    Section {
                        Label(msg, systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.callout)
                    }
                }
            }

            extractButton
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.4)
            Text("Extraindo dados do voo…")
                .font(.system(.callout, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private func previewView(_ pass: ExtractedBoardingPass) -> some View {
        VStack(spacing: 0) {
            Form {
                Section("Voo") {
                    LabeledContent("Companhia", value: pass.airline)
                    LabeledContent("Número", value: pass.flightNumber)
                }
                Section("Rota") {
                    LabeledContent("Origem", value: "\(pass.originCode) · \(pass.originName)")
                    LabeledContent("Destino", value: "\(pass.destinationCode) · \(pass.destinationName)")
                }
                Section("Horários") {
                    LabeledContent("Partida", value: formatted(pass.departureDateTimeISO))
                    LabeledContent("Chegada", value: formatted(pass.arrivalDateTimeISO))
                }
                let hasExtras = !pass.seat.isEmpty || !pass.gate.isEmpty
                    || !pass.confirmationCode.isEmpty || !pass.passengerName.isEmpty
                if hasExtras {
                    Section("Detalhes") {
                        if !pass.seat.isEmpty         { LabeledContent("Assento",    value: pass.seat) }
                        if !pass.gate.isEmpty         { LabeledContent("Portão",     value: pass.gate) }
                        if !pass.confirmationCode.isEmpty { LabeledContent("Reserva", value: pass.confirmationCode) }
                        if !pass.passengerName.isEmpty    { LabeledContent("Passageiro", value: pass.passengerName) }
                    }
                }
                Section {
                    Button("Tentar de novo") { state = .idle }
                        .foregroundStyle(.secondary)
                }
            }

            Button { save(pass) } label: {
                Label("Adicionar voo", systemImage: "plus.circle.fill")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    private func unavailableView(icon: String, title: String, message: String) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
        } description: {
            Text(message)
        }
    }

    // MARK: - Shared button

    private var extractButton: some View {
        let isEmpty = inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return Button {
            Task { await runExtraction() }
        } label: {
            Label("Extrair com Apple Intelligence", systemImage: "sparkles")
                .font(.system(.body, design: .rounded, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isEmpty ? Color.secondary.opacity(0.25) : Color.accentColor,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .foregroundStyle(isEmpty ? Color.secondary : Color.white)
        }
        .buttonStyle(.plain)
        .disabled(isEmpty)
    }

    // MARK: - Actions

    private func runExtraction() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        state = .extracting
        do {
            let pass = try await BoardingPassImporter.extract(from: text)
            state = .preview(pass)
        } catch {
            state = .error("Não foi possível extrair os dados. Verifique o texto e tente novamente.")
        }
    }

    private func save(_ pass: ExtractedBoardingPass) {
        let flight = BoardingPassImporter.toFlight(from: pass, trip: trip)
        modelContext.insert(flight)
        NotificationScheduler.shared.refresh(trip: trip)
        WidgetSnapshotWriter.update(trips: [trip])
        dismiss()
    }

    private func formatted(_ isoString: String) -> String {
        guard let date = BoardingPassImporter.parseDate(isoString) else { return isoString }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}
