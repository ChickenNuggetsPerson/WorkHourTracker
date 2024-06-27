//
//  TrackingWidget.swift
//  TrackingWidget
//
//  Created by Hayden Steele on 5/29/24.
//

import WidgetKit
import SwiftUI
import ActivityKit



struct TrackingActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimeTrackingAttributes.self) { context in
            
            LargeLiveActivityView(context: context)
                .padding()
    
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    LargeLiveActivityView(context: context)
                        .contentTransition(.numericText())
                }
                DynamicIslandExpandedRegion(.leading) {
                    
                }
                DynamicIslandExpandedRegion(.trailing) {
        
                }

            }
            compactLeading: {
                DynamicIslandView(context: context, pos: 0)
            } compactTrailing: {
                DynamicIslandView(context: context, pos: 1)
            } minimal: {
                DynamicIslandView(context: context, pos: 2)
            }
            .keylineTint(context.state.jobColor)
        }

    }
}



struct LargeLiveActivityView: View {
    let context: ActivityViewContext<TimeTrackingAttributes>
    var saveState : Bool { context.state.saveState }
    
    var body: some View {
       
        ZStack() {
            Color.black.ignoresSafeArea()
            
            
            
            VStack(alignment: .center) {
                
                ZStack() {

                    HStack() {
                        if (saveState) {
                        
                            Button(intent: ChangeSaveStateIntent(newState: false)) {
                                Text("No")
                                    .font(.title2)
                                    .fontWeight(.black)
                                    .foregroundColor(context.state.jobColor.darkened(by: 0.2))
                                    .multilineTextAlignment(.center)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                            
                            Button(intent: StopTimerIntent()) {
                                Text("Yes")
                                    .font(.title2)
                                    .fontWeight(.black)
                                    .foregroundColor(context.state.jobColor.darkened(by: 0.2))
                                    .multilineTextAlignment(.center)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                        }
                    }
                    
                    Button(intent: ChangeSaveStateIntent(newState: !saveState)) {
                        Text(context.state.jobType)
                            .font(.title)
                            .fontWeight(.black)
                            .foregroundColor(context.state.jobColor)
                            .multilineTextAlignment(.center)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                }
                
                Text(context.state.startTime, style: .timer)
                    .font(.title2)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .monospaced()
        
                
            }
            
            .padding()
            .contentTransition(.numericText())
        }
       
    }
}




struct DynamicIslandView: View {
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
    
    var body: some View {
        HStack() {
            if (self.pos == 0) { // Compact Leading
                Text(self.getAbriviation(str: context.state.jobType))
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(context.state.jobColor)
                
            } else if (self.pos == 1) { // Compact Trailing
                Image(systemName: "clock")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundColor(context.state.jobColor)
            } else { // Minimal
                Text(self.getAbriviation(str: context.state.jobType))
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(context.state.jobColor)
            
            }
        }
        .contentTransition(.numericText())
        
    }
}
