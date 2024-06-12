//
//  TrackingWidget.swift
//  TrackingWidget
//
//  Created by Hayden Steele on 5/29/24.
//

import WidgetKit
import SwiftUI
import ActivityKit



struct TrackingWidget: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimeTrackingAttributes.self) { context in
            TimeTrackingLiveActivityView(context: context)
            
            
        } dynamicIsland: { context in
            DynamicIsland {
                
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.jobType)
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(context.state.jobColor)
                        .multilineTextAlignment(.center)
                    Text(context.state.startTime, style: .relative)
                        .font(.title2)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .monospaced()
                }

                
                
            }
            compactLeading: {
                TimeTrackingSmallIslandView(context: context, pos: 0)
            } compactTrailing: {
                TimeTrackingSmallIslandView(context: context, pos: 1)
            } minimal: {
                TimeTrackingSmallIslandView(context: context, pos: 2)
            }
            .keylineTint(context.state.jobColor)
        }
    }
}






struct TimeTrackingLiveActivityView: View {
    let context: ActivityViewContext<TimeTrackingAttributes>
    
    var body: some View {
       
        ZStack() {
            Color.black
                .ignoresSafeArea()
            
            VStack(alignment: .center) {
                Text(context.state.jobType)
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(context.state.jobColor)
                    .multilineTextAlignment(.center)
                
                Text(context.state.startTime, style: .relative)
                    .font(.title2)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .monospaced()
            }
            
            .padding()
        }
       
    }
}






struct TimeTrackingSmallIslandView: View {
    let context: ActivityViewContext<TimeTrackingAttributes>
    let pos : Int
    
    func getAbriviation(str: String) -> String {
        let components = str.components(separatedBy: .whitespacesAndNewlines)
        if (components.count == 1) {
            return str
        }
        let firstLetters = components.compactMap() { $0.first }
        return String(firstLetters).uppercased()
    }
    
    func getTxt() -> String {
        return self.getAbriviation(str: context.state.jobType)
    }
    
    var body: some View {
        
        if (self.pos == 0) { // Compact Leading
            Text(getTxt())
                .font(.title)
                .fontWeight(.black)
                .foregroundColor(context.state.jobColor)
            
        } else if (self.pos == 1) { // Compact Trailing
            
            Image(systemName: "timer")
                .font(.largeTitle)
                .fontWeight(.black)
                .foregroundColor(context.state.jobColor)
            
        } else { // Minimal
            Text(getTxt())
                .font(.title)
                .fontWeight(.black)
                .foregroundColor(context.state.jobColor)
        }
    }
}



