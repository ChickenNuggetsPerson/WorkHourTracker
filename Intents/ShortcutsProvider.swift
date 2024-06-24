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
                "Start the \(.applicationName) timer",
                "Start the \(\.$jobType) timer with \(.applicationName)",
                "Start the \(\.$jobType) timer with \(.applicationName)",
                "Start the \(.applicationName) \(\.$jobType) timer",
                "Start the \(.applicationName) \(\.$jobType) job",
                "Start the \(\.$jobType) \(.applicationName) timer",
                "Start the \(\.$jobType) \(.applicationName) job"
            ],
            shortTitle: "Start Work Tracker",
            systemImageName: "clock.badge.checkmark"
        )
        
        AppShortcut(
            intent: StopTimerIntent(),
            phrases: [
                "Tell \(.applicationName) to stop the timer",
                "Stop the \(.applicationName)",
                "Stop the \(.applicationName) timer",
                "Stop the \(.applicationName) job",
            ],
            shortTitle: "Stop Work Tracker",
            systemImageName: "clock.badge.xmark"
        )
    }
}
