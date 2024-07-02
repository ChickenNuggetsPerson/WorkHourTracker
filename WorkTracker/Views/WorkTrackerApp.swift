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
            PayPeriodView(
                period: getCurrentPayperiod(),
                title: "Pay History:",
                color: Color.green
            )
                .transition(.move(edge: .trailing))
        }
        
    }
    
    
}













enum Pages : String, CaseIterable {
    case Main = "Main Page"
    case PayPeriod = "History Page"
}


struct NavView: View {
    
    var gotoPage : Pages
    @ObservedObject var globalData = GlobalData.shared
    
    var body: some View {
        HStack() {
            Button(action: {
                RumbleSystem.shared.rumble()
                globalData.currentPage = gotoPage
            }) {
                Text(gotoPage.rawValue)
                    .padding()
                    .background(Color.init(hex: "1c1c1e"))
                    .foregroundColor(.white)
                    .font(.title2)
                    .fontWeight(.black)
                    .multilineTextAlignment(.center)
                    .cornerRadius(15)
                    .shadow(color: Color(hex: "1c1c1e").darkened(by: 0.2), radius: 0, x: 0, y: 5)
                    
            }
        }
    }
}

#Preview {
    VStack() {
        Spacer()
        
        HStack() {
            Spacer()
            
            NavView(gotoPage: .PayPeriod, globalData: GlobalData.shared)
            
            Spacer()
        }
        
        Spacer()
    }
    .ignoresSafeArea()
    .background(.ultraThinMaterial)
}

