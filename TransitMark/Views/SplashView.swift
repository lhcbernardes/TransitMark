//
//  SplashView.swift
//  TransitMark
//

import SwiftUI

struct SplashView: View {
    @State private var symbolAppeared = false
    @State private var wordmarkAppeared = false

    var body: some View {
        ZStack {
            Brand.darkBackground
                .ignoresSafeArea()

            VStack(spacing: 20) {
                BrandSymbol(color: Brand.amber, glowing: true)
                    .frame(width: 180, height: 180)
                    .scaleEffect(symbolAppeared ? 1.0 : 0.86)
                    .opacity(symbolAppeared ? 1.0 : 0.0)

                Text("TransitMark")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .tracking(0.4)
                    .foregroundStyle(Brand.amber)
                    .opacity(wordmarkAppeared ? 1.0 : 0.0)
            }
        }
        .task {
            withAnimation(.easeOut(duration: 0.5)) {
                symbolAppeared = true
            }
            try? await Task.sleep(for: .milliseconds(180))
            withAnimation(.easeOut(duration: 0.45)) {
                wordmarkAppeared = true
            }
        }
    }
}

#Preview {
    SplashView()
}
