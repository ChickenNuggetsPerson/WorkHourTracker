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
            try? await Task.sleep(nanoseconds: 2_000_000_000)
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
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        
            TimerSystem.shared.stopTimer()
            
        } else {
            TimerSystem.shared.startTimer()
        }
    
        return .result()
    }
}





struct EnableSaveStateIntent : AppIntent, LiveActivityIntent {
    static var title: LocalizedStringResource = "Enables Save State"
    static var description = IntentDescription("Enables the dynamic island save state")
    static var openAppWhenRun: Bool = false
    
    @MainActor
    func perform() async throws -> some IntentResult {
        TimerSystem.shared.updateLiveActivity(
            saveState: true,
            newTitle: TimerSystem.shared.isValidTime ? "Save Job?" : "Cancel Job?"
        )
        return .result()
    }
}
struct DisableSaveStateIntent : AppIntent, LiveActivityIntent {
    static var title: LocalizedStringResource = "Disable Save State"
    static var description = IntentDescription("Disables the dynamic island save state")
    static var openAppWhenRun: Bool = false
    
    @MainActor
    func perform() async throws -> some IntentResult {
        TimerSystem.shared.updateLiveActivity(saveState: false)
        return .result()
    }
}





struct Add15MinIntent : AppIntent, LiveActivityIntent {
    static var title: LocalizedStringResource = "Add 15 Minutes"
    static var description = IntentDescription("Adds 15 minutes to the tracker time")
    static var openAppWhenRun: Bool = false
    
    @MainActor
    func perform() async throws -> some IntentResult {
        
        if (!TimerSystem.shared.running) {
            return .result()
        }
        
        TimerSystem.shared.shiftTimer(shiftMins: -15)
        
        return .result()
    }
    
}
struct Sub15MinIntent : AppIntent, LiveActivityIntent {
    static var title: LocalizedStringResource = "Subtract 15 Minutes"
    static var description = IntentDescription("Subtracts 15 minutes from the tracker time")
    static var openAppWhenRun: Bool = false
    
    @MainActor
    func perform() async throws -> some IntentResult {
        
        if (!TimerSystem.shared.running) {
            return .result()
        }
        
        TimerSystem.shared.shiftTimer(shiftMins: 15)
        
        return .result()
    }
    
}
