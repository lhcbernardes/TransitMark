//
//  TransitMarkApp.swift
//  TransitMark
//
//  Created by Leandro Henrique Cavalcanti Bernardes on 22/06/26.
//

import SwiftUI
import SwiftData

@main
struct TransitMarkApp: App {
    @State private var showingSplash = true

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Trip.self,
            Flight.self,
            Stay.self,
            Activity.self,
        ])

        let cloudConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        if let container = try? ModelContainer(for: schema, configurations: [cloudConfig]) {
            return container
        }

        let localConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [localConfig])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                if showingSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                        .task {
                            try? await Task.sleep(for: .milliseconds(1400))
                            withAnimation(.easeOut(duration: 0.45)) {
                                showingSplash = false
                            }
                        }
                }
            }
            .task {
                await NotificationScheduler.shared.requestPermissionIfNeeded()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
