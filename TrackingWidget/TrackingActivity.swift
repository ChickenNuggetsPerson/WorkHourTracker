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
            
                
                if (context.state.saveState || context.state.jobType == "Saved") {
                    Text(context.state.startTime.hrsOffset(relativeTo: roundTime(time: Date())).toHrsString())
                        .font(.title2)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .monospaced()
                        .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale))
                } else {
                    Text(context.state.startTime, style: .timer)
                        .font(.title2)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .monospaced()
                        .transition(.move(edge: .top).combined(with: .opacity).combined(with: .scale))
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
    
    func getInterval() -> ClosedRange<Date> {
        
        let start = context.state.startTime
        let end = start.addHours(hours: 8)
        
        return start...end
    }
    
    var body: some View {
        HStack() {
            if (self.pos == 0) { // Compact Leading
                Text(self.getAbriviation(str: context.state.jobType))
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(context.state.jobColor)
            } else if (self.pos == 1) { // Compact Trailing
               
            
                ProgressView(
                    timerInterval: self.getInterval(),
                        countsDown: true,
                        label: {
                            EmptyView()
                        },
                        currentValueLabel: {
                            Image(systemName: "clock")
                                .font(.largeTitle)
                                .fontWeight(.black)
                                .foregroundColor(context.state.jobColor)
                        }
                    )
                    .progressViewStyle(.circular)
                    .tint(context.state.jobColor.darkened(by: 0.2))
            } else { // Minimal
                
                ProgressView(
                    timerInterval: self.getInterval(),
                        countsDown: true,
                        label: {
                            EmptyView()
                        },
                        currentValueLabel: {
                            Text(self.getAbriviation(str: context.state.jobType))
                                .font(.title)
                                .fontWeight(.black)
                                .foregroundColor(context.state.jobColor)
                        }
                    )
                    .progressViewStyle(.circular)
                    .tint(context.state.jobColor.darkened(by: 0.2))
                
            
            }
        }
        .contentTransition(.numericText())
        
    }
}




