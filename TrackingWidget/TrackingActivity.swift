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
    
    func getInterval(state: TimeTrackingAttributes.ContentState) -> ClosedRange<Date> {
        
        let start = state.startTime
        let end = start.addHours(hours: 12)

        
        return start...end
    }

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimeTrackingAttributes.self) { context in
            
            LargeLiveActivityView(context: context, timeRange: self.getInterval(state: context.state))
                .padding()
                .activityBackgroundTint(.black)
    
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    LargeLiveActivityView(context: context, timeRange: self.getInterval(state: context.state))
                        .contentTransition(.numericText())
                }
                DynamicIslandExpandedRegion(.leading) {
                    
                }
                DynamicIslandExpandedRegion(.trailing) {
        
                }

            }
            compactLeading: {
                DynamicIslandView(context: context, pos: 0, timeRange: self.getInterval(state: context.state))
            } compactTrailing: {
                DynamicIslandView(context: context, pos: 1, timeRange: self.getInterval(state: context.state))
            } minimal: {
                DynamicIslandView(context: context, pos: 2, timeRange: self.getInterval(state: context.state))
            }
            .keylineTint(context.state.jobColor)
        }

    }
}



struct LargeLiveActivityView: View {
    let context: ActivityViewContext<TimeTrackingAttributes>
    var saveState : Bool { context.state.saveState }
    let timeRange : ClosedRange<Date>
    
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
            
                
                if (
                    context.state.saveState ||
                    context.state.jobType == "Saved" ||
                    context.state.jobType == "Canceled"
                ) {
                    Text(context.state.startTime.hrsOffset(relativeTo: roundTime(time: Date())).toHrsString())
                        .font(.title2)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .monospaced()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .clipped()
                } else {
                    Text(
                        timerInterval: self.timeRange,
                        countsDown: false
                    )
                    .font(.title2)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .monospaced()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .clipped()
                }
                
        
                
            }
            
            .padding()
            .contentTransition(.numericText())
        }
       
    }
}




struct DynamicIslandView: View {
    let context : ActivityViewContext<TimeTrackingAttributes>
    let pos : Int
    var timeRange : ClosedRange<Date>
    
    func getAbriviation(str: String) -> String {
        let components = str.components(separatedBy: .whitespacesAndNewlines)
        if (components.count == 1) {
            return str
        }
        let firstLetters = components.compactMap() { $0.first }
        return String(firstLetters).uppercased()
    }
    
    
    
    var body: some View {
        VStack() {
            if (self.pos == 0) { // Compact Leading
                Text(self.getAbriviation(str: context.state.jobType))
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(context.state.jobColor)
                    .padding(.leading, 5)
                
            } else if (self.pos == 1) { // Compact Trailing
               
                Text(
                    timerInterval: self.timeRange,
                    countsDown: false
                )
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(context.state.jobColor)
                    .monospaced()
                    .frame(maxWidth: 45)
                    .minimumScaleFactor(0.5)
                
                
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




