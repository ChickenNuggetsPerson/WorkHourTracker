//
//  DynamicIslandIntents.swift
//  WorkTracker
//
//  Created by Hayden Steele on 6/23/24.
//

import Foundation
import AppIntents


// Dynamic Island Buttons
struct ChangeSaveStateIntent : AppIntent, LiveActivityIntent {
    static var title: LocalizedStringResource = "Change Dynamic Island Save State"
    static var description = IntentDescription("Changes the dynamic islands save state")
    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = false
    
    @Parameter(title: "New State", description: "")
    var newState: Bool
    
    init() {
        self.newState = false
    }
    init (newState: Bool) {
        self.newState = newState
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        
        if (self.newState) {
            TimerSystem.shared.updateLiveActivity(
                saveState: true,
                newTitle: TimerSystem.shared.isValidTime ? "Save Job?" : "Cancel Job?"
            )
            
            try await Task.sleep(until: .now + .seconds(5))
            
            if (TimerSystem.shared.running) {
                TimerSystem.shared.updateLiveActivity(saveState: false)
            }
            
        } else {
            TimerSystem.shared.updateLiveActivity(saveState: false)
        }
        
        return .result()
    }
}
