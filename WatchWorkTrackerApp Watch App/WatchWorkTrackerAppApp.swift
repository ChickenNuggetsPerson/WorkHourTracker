//
//  WatchWorkTrackerAppApp.swift
//  WatchWorkTrackerApp Watch App
//
//  Created by Hayden Steele on 7/30/24.
//

import SwiftUI
import SwiftData

@main
struct WatchWorkTrackerApp_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                WatchTimerView()
                WatchScrollView()
            }
            .tabViewStyle(.verticalPage(transitionStyle: .identity))
        }
        .modelContainer(DataStorageSystem.shared.container)
        .modelContext(DataStorageSystem.shared.context)
    }
}
