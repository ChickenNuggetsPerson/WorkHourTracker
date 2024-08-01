//
//  LiveActivitySystem.swift
//  WorkTracker
//
//  Created by Hayden Steele on 5/30/24.
//


import Foundation
import SwiftUI
#if os(iOS)
import ActivityKit
#endif

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
        
        let content = ActivityContent<TimeTrackingAttributes.ContentState>(
            state: state,
            staleDate: Date().addMinutes(minutes: 30)
        )
        
        let attributes = TimeTrackingAttributes()
        
        do {
            let activity = try Activity<TimeTrackingAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            
            print("Starting Live Activity: \(activity.id)")
        } catch {
            print("error starting activitiy: \(error.localizedDescription)")
            
        }

    }
    func stopLiveActivity() {
        // End Live activity
        print("Stopping Live Activity")
        
        let state = TimeTrackingAttributes.ContentState(
            startTime: Date(),
            jobType: "",
            jobColor: .white,
            saveState: false
        )
        
        let content = ActivityContent<TimeTrackingAttributes.ContentState>(
            state: state,
            staleDate: Date()
        )
        
        // End Stray Activities
        for activity in Activity<TimeTrackingAttributes>.activities {
            Task {
                await activity.end(content, dismissalPolicy: .immediate)
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
            let content = ActivityContent<TimeTrackingAttributes.ContentState>(
                state: contentState,
                staleDate: Date().addMinutes(minutes: 30)
            )
            
            for activity in Activity<TimeTrackingAttributes>.activities {
                await activity.update(content)
            }
        }
    }

}
