//
//  WorkTrackerApp.swift
//  WorkTracker
//
//  Created by Hayden Steele on 5/28/24.
//

import SwiftUI
import CoreData


class GlobalData: ObservableObject {
    static let shared = GlobalData()
    
    @Published var currentPage: Pages = Pages.Main
}



@main
struct WorkTrackerApp: App {
    
    @ObservedObject var globalData = GlobalData.shared
    let coreDataManager = CoreDataManager.shared

    var body: some Scene {
        WindowGroup {
            VStack() {
                contentView(for: globalData.currentPage)
                    .environment(\.managedObjectContext, coreDataManager.context)
                    .animation(.spring, value: globalData.currentPage)
                    .environment(\.colorScheme, .dark)
            }
        }
        
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

    var color: Color {
        switch self {
            case .Main:
                return .orange
            case .PayPeriod:
                return .orange

        }
    }
}










struct NavView: View {
    
    var activePage : Pages
    @ObservedObject var globalData = GlobalData.shared
    
    var body: some View {
        HStack() {
            ForEach(Pages.allCases.filter { p in
                return p != activePage
            }, id: \.self) { page in
                
                Button(page.rawValue) {
                    globalData.currentPage = page
                }
                .padding()
                .background(page.color)
                .foregroundColor(.white)
                .font(.title2)
                .fontWeight(.black)
                .multilineTextAlignment(.center)
                .cornerRadius(15) 
                .shadow(color: Color(hex: "b55612"), radius: 0, x: 0, y: 5)
            }
        }
    }
}



