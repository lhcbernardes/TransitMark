//
//  TipProduct.swift
//  TransitMark
//

import Foundation

struct TipProduct: Identifiable, Hashable {
    let id: String
    let emoji: String
    let title: String
    let subtitle: String

    static let all: [TipProduct] = [
        TipProduct(
            id: "com.lhcbernardes.transitmark.tip.coffee",
            emoji: "☕️",
            title: "Café",
            subtitle: "Um cafezinho pra agradecer."
        ),
        TipProduct(
            id: "com.lhcbernardes.transitmark.tip.snack",
            emoji: "🥐",
            title: "Lanche de aeroporto",
            subtitle: "Um lanche enquanto espero o portão abrir."
        ),
        TipProduct(
            id: "com.lhcbernardes.transitmark.tip.meal",
            emoji: "🍝",
            title: "Jantar na viagem",
            subtitle: "Um jantar pra fechar o dia bem."
        ),
        TipProduct(
            id: "com.lhcbernardes.transitmark.tip.upgrade",
            emoji: "✈️",
            title: "Upgrade na classe",
            subtitle: "Pra continuar viajando alto."
        )
    ]

    static var allIDs: Set<String> { Set(all.map(\.id)) }
}
