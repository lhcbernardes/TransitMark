//
//  TipJarView.swift
//  TransitMark
//

import StoreKit
import SwiftUI

struct TipJarView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var service = TipJarService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    content
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .navigationTitle("Apoiar o dev")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .task { await service.loadProductsIfNeeded() }
            .alert(
                "Obrigado! ❤️",
                isPresented: thanksAlertBinding,
                actions: {
                    Button("De nada") { service.resetPurchaseState() }
                },
                message: {
                    Text("Seu apoio mantém o TransitMark em desenvolvimento.")
                }
            )
            .alert(
                "Algo deu errado",
                isPresented: errorAlertBinding,
                actions: {
                    Button("OK") { service.resetPurchaseState() }
                },
                message: {
                    Text(errorMessage ?? String(localized: "Tente novamente em instantes."))
                }
            )
            .sensoryFeedback(.success, trigger: successTrigger)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Curtindo o app?")
                .font(.system(.title2, design: .rounded, weight: .bold))
            Text("TransitMark é mantido por um desenvolvedor independente. Se ele te ajudou em alguma viagem, um café cai super bem.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 12)
    }

    @ViewBuilder
    private var content: some View {
        switch service.loadState {
        case .idle, .loading:
            loadingState
        case .failed(let message):
            failureState(message: message)
        case .loaded:
            productsList
        }
    }

    private var loadingState: some View {
        HStack(spacing: 8) {
            ProgressView()
            Text("Carregando opções...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 32)
    }

    private func failureState(message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.title)
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Tentar de novo") {
                Task { await service.loadProductsIfNeeded() }
            }
            .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var productsList: some View {
        VStack(spacing: 12) {
            ForEach(TipProduct.all) { tip in
                productRow(for: tip)
            }
        }
    }

    @ViewBuilder
    private func productRow(for tip: TipProduct) -> some View {
        let product = service.products[tip.id]
        let priceLabel = product?.displayPrice ?? "—"
        let isPurchasing = isPurchasing(tip.id)
        let isUnavailable = product == nil

        Button {
            Task { await service.purchase(tip) }
        } label: {
            HStack(spacing: 14) {
                Text(tip.emoji)
                    .font(.system(size: 32))
                    .frame(width: 48, height: 48)
                    .background(
                        Circle().fill(Color.accentColor.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(tip.title)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(tip.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if isPurchasing {
                    ProgressView()
                } else {
                    Text(priceLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(isUnavailable ? Color.gray : Color.accentColor)
                        )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing || isUnavailable)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tip.title), \(priceLabel)")
    }

    private func isPurchasing(_ id: String) -> Bool {
        if case .purchasing(let purchasingID) = service.purchaseState, purchasingID == id {
            return true
        }
        return false
    }

    private var thanksAlertBinding: Binding<Bool> {
        Binding(
            get: { if case .success = service.purchaseState { return true } else { return false } },
            set: { newValue in if !newValue { service.resetPurchaseState() } }
        )
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { if case .failed = service.purchaseState { return true } else { return false } },
            set: { newValue in if !newValue { service.resetPurchaseState() } }
        )
    }

    private var errorMessage: String? {
        if case .failed(let message) = service.purchaseState { return message }
        return nil
    }

    private var successTrigger: Int {
        if case .success = service.purchaseState { return 1 } else { return 0 }
    }
}

#Preview {
    TipJarView()
}
