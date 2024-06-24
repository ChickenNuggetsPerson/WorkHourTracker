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
            
            LargeLiveActivityView(context: context)
    
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    LargeLiveActivityView(context: context)
                        .animation(.bouncy, value: context.state.startTime)
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
    
    var body: some View {
       
        ZStack() {
            Color.black.ignoresSafeArea()
            
            let saveState : Bool = context.state.saveState
            
            VStack(alignment: .center) {
                
                Button(intent: EnableSaveStateIntent()) {
                    Text(context.state.jobType)
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(context.state.jobColor)
                        .multilineTextAlignment(.center)
                }
                    .buttonStyle(PlainButtonStyle())
                
                HStack() {
                    
                    if (!saveState) {
                        Button("-15",intent: Sub15MinIntent())
                            .disabled(
                                !saveState && context.state.startTime.addMinutes(minutes: 15) > Date()
                            )
                    } else {
                        Button("No", intent: DisableSaveStateIntent())
                    }
                    
                    Spacer()
                    
                    if (!context.state.saveState) {
                        Text(context.state.startTime, style: .timer)
                            .font(.title2)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .monospaced()
                    } else {
                        Text(
                            String(context.state.startTime.hrsOffset(relativeTo: roundTime(time: Date())))
                            + " hrs"
                        )
                            .font(.title2)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .monospaced()
                    }
                
                    Spacer()
                    
                    if (!saveState) {
                        Button("+15",intent: Add15MinIntent())
                    } else {
                        Button("Yes", intent: StopTimerIntent())
                    }
                    
                }
                
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
