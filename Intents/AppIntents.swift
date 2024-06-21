//
//  AppIntents.swift
//  WorkTracker
//
//  Created by Hayden Steele on 6/20/24.
//

import Foundation
import AppIntents
import SwiftUI

struct StopTimerIntent : AppIntent, LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Tracker"

    static var description = IntentDescription("Stops and saves the hour tracker")
    
    static var openAppWhenRun: Bool = false
    
    @MainActor
    func perform() async throws -> some IntentResult {
        
        if (!TimerSystem.shared.running) {
            return .result()
        }
        
        if (TimerSystem.shared.startTime != roundTime(time: Date())) {
            TimerSystem.shared.save()
        }
    
        TimerSystem.shared.stopTimer()
        
        return .result()
    }
    
}


struct StartTimerIntent : AppIntent, LiveActivityIntent {
    static var title: LocalizedStringResource = "Start Tracker"

    static var description = IntentDescription("Starts the work tracker")
    
    static var openAppWhenRun: Bool = false
    
    
    @Parameter(title: "Job Type", description: "The type of work being done.")
    var jobType: JobTypes
    
    @MainActor
    func perform() async throws -> some IntentResult {
        
        if (TimerSystem.shared.running) {
            return .result()
        }
        
        TimerSystem.shared.jobState = self.jobType
        TimerSystem.shared.startTimer()
        
        return .result()
    }
}



struct ToggleTimerIntent : AppIntent, LiveActivityIntent {
    static var title: LocalizedStringResource = "Toggle Tracker"

    static var description = IntentDescription("Starts or stops the timer")
    
    static var openAppWhenRun: Bool = false
    
    @MainActor
    func perform() async throws -> some IntentResult {
        
        if (TimerSystem.shared.running) {
            
            if (TimerSystem.shared.startTime != roundTime(time: Date())) {
                TimerSystem.shared.save()
            }
            TimerSystem.shared.stopTimer()
        } else {
            TimerSystem.shared.startTimer()
        }
    
        return .result()
    }
}
