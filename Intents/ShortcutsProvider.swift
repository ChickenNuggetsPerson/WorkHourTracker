//
//  ShortcutsProvider.swift
//  WorkTracker
//
//  Created by Hayden Steele on 6/21/24.
//

import Foundation
import AppIntents

struct ShortcutsProvider : AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        
        
        AppShortcut(
            intent: StartTimerIntent(),
            phrases: [
                "Tell \(.applicationName) to start the timer",
                "Start the \(.applicationName)",
                "I am \(.applicationName)"
            ],
            shortTitle: "Start Work Tracker",
            systemImageName: "clock.badge.checkmark"
        )
        
        AppShortcut(
            intent: StopTimerIntent(),
            phrases: [
                "Tell \(.applicationName) to stop the timer",
                "Stop the \(.applicationName)",
                "I am done \(.applicationName)"
            ],
            shortTitle: "Stop Work Tracker",
            systemImageName: "clock.badge.xmark"
        )
        
        AppShortcut(
            intent: ToggleTimerIntent(),
            phrases: [
                "Toggle the \(.applicationName)"
            ],
            shortTitle: "Toggle Work Tracker",
            systemImageName: "clock"
        )
    }
}
