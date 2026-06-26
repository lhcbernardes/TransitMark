//
//  MaxBrightnessModifier.swift
//  TransitMark
//

import SwiftUI
import UIKit

private struct MaxBrightnessModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    @State private var previousBrightness: CGFloat?

    func body(content: Content) -> some View {
        content
            .onAppear { applyMaximum() }
            .onDisappear { restore() }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active: applyMaximum()
                case .inactive, .background: restore()
                @unknown default: break
                }
            }
    }

    private func applyMaximum() {
        guard !isRunningInPreview, let screen = currentScreen else { return }
        if previousBrightness == nil {
            previousBrightness = screen.brightness
        }
        screen.brightness = 1.0
    }

    private func restore() {
        guard !isRunningInPreview, let screen = currentScreen else { return }
        if let previousBrightness {
            screen.brightness = previousBrightness
        }
        previousBrightness = nil
    }

    private var currentScreen: UIScreen? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .screen
    }

    private var isRunningInPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}

extension View {
    func maxBrightnessWhilePresented() -> some View {
        modifier(MaxBrightnessModifier())
    }
}
