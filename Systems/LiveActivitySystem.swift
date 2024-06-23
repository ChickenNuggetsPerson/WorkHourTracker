//
//  LiveActivitySystem.swift
//  WorkTracker
//
//  Created by Hayden Steele on 5/30/24.
//

import Foundation
import ActivityKit
import SwiftUI

class LiveActivitySystem {
    static let shared = LiveActivitySystem()
        
    func startLiveActivity(
        startTime: Date = Date(),
        jobState: String = "",
        jobColor: Color = Color.white
    ) {
        
        let state = TimeTrackingAttributes.ContentState(
            startTime: startTime,
            jobType: jobState,
            jobColor: jobColor,
            saveState: false
        )
        
        let attributes = TimeTrackingAttributes()
        
        try? Activity<TimeTrackingAttributes>.request(
            attributes: attributes,
            contentState: state,
            pushType: nil
        )

        print("Starting Live Activity")
    }
    func stopLiveActivity() {
        // End Live activity
        print("Stopping Live Activity")
        
        // End Stray Activities
        for activity in Activity<TimeTrackingAttributes>.activities {
            Task {
                await activity.end(dismissalPolicy: .immediate)
                print("Ended activity: \(activity.id)")
            }
        }
    }
    
    
    func updateActivity(
        startTime: Date = Date(),
        jobState: String = "",
        jobColor: Color = Color.white,
        saveState: Bool = false
    ) {
        Task {
            let contentState = TimeTrackingAttributes.ContentState(
                startTime: startTime,
                jobType: jobState,
                jobColor: jobColor,
                saveState: saveState
            )
            
            for activity in Activity<TimeTrackingAttributes>.activities {
                await activity.update(using: contentState)
            }
        }
    }
    
}
