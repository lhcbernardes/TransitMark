//
//  ContentView.swift
//  TransitMark
//
//  Created by Leandro Henrique Cavalcanti Bernardes on 22/06/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \Trip.createdAt, order: .reverse) private var trips: [Trip]
    @State private var showingTripsList = false
    @AppStorage(PreferenceKey.colorScheme) private var colorSchemeChoice: String = "system"
    @AppStorage(PreferenceKey.language) private var languageChoice: String = "pt"

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { timeline in
            StateView(
                trips: trips,
                date: timeline.date,
                onOpenTrips: { showingTripsList = true }
            )
        }
        .sheet(isPresented: $showingTripsList) {
            TripsListView(isPresentedAsSheet: true)
        }
        .preferredColorScheme(preferredColorScheme)
        .environment(\.locale, Locale(identifier: languageChoice))
        .task { WidgetSnapshotWriter.update(trips: trips) }
        .onChange(of: trips) { WidgetSnapshotWriter.update(trips: trips) }
    }

    private var preferredColorScheme: ColorScheme? {
        switch colorSchemeChoice {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}

private struct StateView: View {
    let trips: [Trip]
    let date: Date
    let onOpenTrips: () -> Void

    private var state: AppState {
        CurrentStateResolver().resolve(trips: trips, now: date)
    }

    private var liveActivityToken: String {
        if let flight = state.preBoardingFlight { return flight.id.uuidString }
        return ""
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            stateContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if state.allowsOverlayTripsButton {
                tripsButton
                    .padding(.bottom, 32)
            }
        }
        .task(id: liveActivityToken) {
            BoardingActivityController.shared.handle(state)
        }
    }

    @ViewBuilder
    private var stateContent: some View {
        switch state {
        case .preBoarding(let flight):
            PreBoardingView(flight: flight)
        case .inFlight(let flight, let stay):
            InFlightView(flight: flight, destinationStay: stay, now: date)
        case .landing(let flight, let stay):
            LandingView(flight: flight, destinationStay: stay)
        case .staying(let stay, let items):
            StayingView(currentStay: stay, upcomingItems: items, now: date)
        case .idle:
            TripsListView()
        }
    }

    private var tripsButton: some View {
        Button(action: onOpenTrips) {
            Label("Viagens", systemImage: "list.bullet")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 13)
                .background(.regularMaterial, in: Capsule())
                .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }
}

private extension AppState {
    var allowsOverlayTripsButton: Bool {
        switch self {
        case .idle: return false
        case .preBoarding, .inFlight, .landing, .staying: return true
        }
    }
}

#Preview("Lista de viagens") {
    ContentView()
        .modelContainer(for: Trip.self, inMemory: true)
}

#Preview("Pré-Embarque") {
    PreBoardingView(flight: SampleData.preBoardingFlight())
}

#Preview("Bordo") {
    InFlightView(
        flight: SampleData.preBoardingFlight(),
        destinationStay: SampleData.tokyoStay()
    )
}

#Preview("Pouso") {
    LandingView(
        flight: SampleData.preBoardingFlight(),
        destinationStay: SampleData.tokyoStay()
    )
}

#Preview("Estadia") {
    StayingView(
        currentStay: SampleData.tokyoStay(),
        upcomingItems: SampleData.tokyoDayItems()
    )
}
