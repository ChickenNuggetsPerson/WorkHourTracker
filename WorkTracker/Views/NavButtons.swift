//
//  NavButtons.swift
//  WorkTracker
//
//  Created by Hayden Steele on 7/11/24.
//

import Foundation
import SwiftUI


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
