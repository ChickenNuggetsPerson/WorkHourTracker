//
//  WorkTrackerApp.swift
//  WorkTracker
//
//  Created by Hayden Steele on 5/28/24.
//

import SwiftUI
import SwiftData


class GlobalData: ObservableObject {
    static let shared = GlobalData()
    
    @Published var currentPage: Pages = Pages.Main
}

enum Pages : String, CaseIterable {
    case Main = "Main Page"
    case PayPeriod = "History Page"
}

@main
struct WorkTrackerApp: App {

    @ObservedObject var globalData = GlobalData.shared

    var body: some Scene {
        WindowGroup {
            VStack() {
                contentView(for: globalData.currentPage)
                    .animation(.snappy, value: globalData.currentPage)
                    .environment(\.colorScheme, .dark)
            }
        }
        .modelContainer(DataStorageSystem.shared.container)
        .modelContext(DataStorageSystem.shared.context)
    
    }
    
    @ViewBuilder
    func contentView(for page: Pages) -> some View {
        switch page {
            case .Main:
                MainView()
                .transition(.move(edge: .leading))
            case .PayPeriod:
                PayPeriodView()
                .transition(.move(edge: .trailing))
        }
        
    }
    
    
}



