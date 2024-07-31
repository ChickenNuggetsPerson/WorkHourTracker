//
//  ContentView.swift
//  WatchWorkTrackerApp Watch App
//
//  Created by Hayden Steele on 7/30/24.
//

import SwiftUI

struct WatchScrollView: View {
    
    @State var dataFetcher = WatchDataFetcher.shared
    
    @State var viewRange : PayPeriod = getCurrentPayperiod()
    
    var body: some View {
        
        ScrollView {
            
            Text("PayPeriod:")
                .fontWeight(.black)
                .font(.title3)
                .foregroundStyle(.white.darkened(by: 0.1))

            Text(self.viewRange.toString())
                .fontWeight(.bold)
                .font(.title3)
                .foregroundStyle(.gray)


            Divider()
                .padding()

            WatchEntryScrollItems(
               jobEntries: $dataFetcher.jobEntries,
               error: $dataFetcher.error
            )

        }
        
    }
}








struct WatchEntryScrollItems: View {
    @Binding var jobEntries : [JobEntry]?
    @Binding var error: Bool
    
    @State var animVal = 0.8
    
    private enum ViewState {
        case Loading
        case PresentingData
        case Error
    }
    private var currentViewState : ViewState {
        if (ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" ) {
            if (self.error) {
                return .Error
            }
        }
       
        if (self.jobEntries == nil) {
            return .Loading
        }
        return .PresentingData
    }
    
    var body: some View {
        VStack {
            
            
            switch currentViewState {
            case .Loading:
                Text("Loading Data...")
                    .opacity(self.animVal)
                    .onAppear {
                        var repeatingAnimation: Animation {
                                Animation
                                    .easeInOut(duration: 2)
                                    .repeatForever()
                        }
                        
                        withAnimation(repeatingAnimation) {
                            self.animVal = 1
                        }
                    }
                
                
                
            case .PresentingData:
                
                if (self.jobEntries!.isEmpty) {
                    
                    Text("No Data 😐")
                    
                } else {
                    
                    
                    ForEach(self.jobEntries!.indices, id: \.self) { i in
                        
                        if (i == 0 || !Calendar.current.isDate(self.jobEntries![i].startTime, inSameDayAs: self.jobEntries![i-1].startTime)) {
                            
                            WatchDayDivider(
                                day: self.jobEntries![i].startTime,
                                blur: false
                            )
                            .ignoresSafeArea()
                        }
                        
                        WatchJobEntryView(
                            job: self.jobEntries![i]
                        )
                        .modifier(WatchScrollTransition())
                    
                        
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.2, anchor: .center)))
                    
                }
                
                
            case .Error:
                Text("Error Fetching Data")
            }
            
            
        }
    }
}

struct WatchDayDivider: View {
    var day: Date
    var blur: Bool
    
    var body: some View {
        HStack() {
            
            Text(self.day.toDate())
            .foregroundColor(
                self.blur ? .gray : Color(hex: "#9f9f9f")
            )
            .font(.caption)
            .fontWeight(.black)
            .monospaced()
            .blur(radius: self.blur ? 5 : 0)
            
            Spacer()
            
        }
        .padding([.leading, .trailing], 20)
        .padding(.top, 15)
        .transition(.move(edge: .leading))
        .id(self.day.toDate())
        
        .modifier(WatchScrollTransition())
    }
}

struct WatchScrollTransition: ViewModifier {


    func body(content: Content) -> some View {
        Group {
            content
                .scrollTransition(ScrollTransitionConfiguration.interactive.threshold(.visible(0.2))) { content, phase in
                    content
                        .scaleEffect(phase.isIdentity ? 1 : 0.98, anchor: .center)
                        .blur(radius: phase.isIdentity ? 0 : 2)
                        .opacity(phase.isIdentity ? 1 : 0.9)
                        .offset(y: phase.value * 4)
                }
        }
    }
}






#Preview() {
    WatchScrollView()
}
