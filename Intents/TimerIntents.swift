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
    static var parameterSummary: some ParameterSummary {
        Summary("Stop the work tracker")
    }
    
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
    static var parameterSummary: some ParameterSummary {
        Summary("Start a \(\.$jobType) Timer")
    }
    
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








// Timer Status Intent Stuff
struct TimerStatusResult: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Timer Status")
    
    @Property(title: "Running")
    var running: Bool
    
    @Property(title: "Job Title")
    var jobTitle: String
    
    @Property(title: "Start Time")
    var startTime: Date
    
    @Property(title: "End Time")
    var endTime : Date

    static var defaultQuery = TimerStatusResultQuery()

    // Provide an identifier for the entity
    var id: String {
        jobTitle
    }

    // Define display representation for the entity
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(jobTitle) - \(running ? "Running" : "Stopped")",
            subtitle: LocalizedStringResource(
                stringLiteral: running ? String(startTime.hrsOffset(relativeTo: endTime)) + " hrs" : ""
            ),
            image: DisplayRepresentation.Image(
                systemName: running ? "timer" : "pause.circle"
            )
        )
    }
}
struct TimerStatusResultQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [TimerStatusResult] {
        return []
    }

    func suggestedEntities() async throws -> [TimerStatusResult] {
        return []
    }
}
struct GetTimerStatusIntent : AppIntent {
    static var title: LocalizedStringResource = "Get Tracker Status"
    static var description = IntentDescription("Gets the current running state of the tracker.")
    static var openAppWhenRun: Bool = false
    
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<TimerStatusResult> {
        
        let status = TimerStatusResult()
        status.running = TimerSystem.shared.running
        status.jobTitle = TimerSystem.shared.jobState.rawValue
        status.startTime = TimerSystem.shared.startTime
        status.endTime = roundTime(time: Date())
        
        return .result(value: status)
    }
}












