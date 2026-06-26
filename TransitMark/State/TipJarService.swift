//
//  TipJarService.swift
//  TransitMark
//

import Foundation
import StoreKit

@Observable
@MainActor
final class TipJarService {

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    enum PurchaseState: Equatable {
        case idle
        case purchasing(productID: String)
        case success(productID: String)
        case failed(String)
    }

    private(set) var loadState: LoadState = .idle
    private(set) var purchaseState: PurchaseState = .idle
    private(set) var products: [String: Product] = [:]

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                if case let .verified(transaction) = update {
                    await transaction.finish()
                    await self?.markSuccess(productID: transaction.productID)
                }
            }
        }
    }

    func loadProductsIfNeeded() async {
        switch loadState {
        case .loaded, .loading: return
        default: break
        }
        loadState = .loading

        do {
            let storeProducts = try await Product.products(for: TipProduct.allIDs)
            var indexed: [String: Product] = [:]
            for product in storeProducts {
                indexed[product.id] = product
            }
            products = indexed
            loadState = .loaded
        } catch {
            loadState = .failed(String(localized: "Não foi possível carregar os produtos."))
        }
    }

    func purchase(_ tip: TipProduct) async {
        guard let product = products[tip.id] else {
            purchaseState = .failed(String(localized: "Produto indisponível no momento."))
            return
        }

        purchaseState = .purchasing(productID: tip.id)

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case let .verified(transaction) = verification {
                    await transaction.finish()
                    purchaseState = .success(productID: tip.id)
                } else {
                    purchaseState = .failed(String(localized: "A transação não pôde ser verificada."))
                }
            case .userCancelled:
                purchaseState = .idle
            case .pending:
                purchaseState = .failed(String(localized: "Compra pendente — aguarde aprovação."))
            @unknown default:
                purchaseState = .failed(String(localized: "Estado de compra desconhecido."))
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    func resetPurchaseState() {
        purchaseState = .idle
    }

    private func markSuccess(productID: String) {
        purchaseState = .success(productID: productID)
    }
}
