//
//  DynamicIslandIntents.swift
//  WorkTracker
//
//  Created by Hayden Steele on 6/23/24.
//

import Foundation
import AppIntents


// Dynamic Island Buttons
struct EnableSaveStateIntent : AppIntent, LiveActivityIntent {
    static var title: LocalizedStringResource = "Enables Save State"
    static var description = IntentDescription("Enables the dynamic island save state")
    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = false
    
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
    static var isDiscoverable: Bool = false
    
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
    static var isDiscoverable: Bool = false
    
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
    static var isDiscoverable: Bool = false
    
    @MainActor
    func perform() async throws -> some IntentResult {
        
        if (!TimerSystem.shared.running) {
            return .result()
        }
        
        TimerSystem.shared.shiftTimer(shiftMins: 15)
        
        return .result()
    }
    
}
