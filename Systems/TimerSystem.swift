//
//  TimerSystem.swift
//  WorkTracker
//
//  Created by Hayden Steele on 6/20/24.
//

import Foundation
import WidgetKit

class TimerSystem : ObservableObject {
    static let shared = TimerSystem()
    
    let userDefaults = UserDefaults(suiteName: "group.com.steele.Worktracker.sharedData")
    
    @Published var running : Bool {
        didSet {
            userDefaults!.set(self.running, forKey: "running")
        }
    }
    @Published var jobState : JobTypes {
        didSet {
            userDefaults!.set(self.jobState.rawValue, forKey: "jobType")
        }
    }
    @Published var startTime : Date {
        didSet {
            userDefaults!.set(self.startTime, forKey: "startTime")
        }
    }
    @Published var jobDescription : String {
        didSet {
            userDefaults!.set(self.jobDescription, forKey: "desc")
        }
    }
    
    var isValidTime : Bool {
        self.startTime.hrsOffset(relativeTo: roundTime(time: Date())) != 0.0
    }
    
    
    init() {
        if let storedTime = userDefaults!.object(forKey: "startTime") as? Date {
            self.startTime = storedTime
    
        } else {
            print("Could not read")
            self.startTime = roundTime(time: Date())
        }
        
        self.running = userDefaults!.bool(forKey: "running")
        
        self.jobState = JobTypes(rawValue: userDefaults!.string(forKey: "jobType") ?? JobTypes.Manager.rawValue)!
        
        self.jobDescription = userDefaults!.string(forKey: "desc") ?? ""
        
        
        self.enableDisableLiveAcitivty()
    }
    

    
    
    func toggleTimer() { // Start - Stop Button
        self.running.toggle()
        if (self.running) {
            self.startTimer()
        } else {
            self.stopTimer()
        }
        
        RumbleSystem.shared.rumble()
    }
    
    func startTimer() {
        self.running = true
        self.startTime = roundTime(time: Date())
        self.enableDisableLiveAcitivty()
    }
    func stopTimer() {
        self.running = false
        self.jobDescription = ""
        self.enableDisableLiveAcitivty()
        self.startTime = roundTime(time: Date())
    }
    
    func save() {
        let start = self.startTime
        let stop = roundTime(time: Date())
        
        DataStorageSystem.shared.createEntry(
            jobTypeID: getIDFromJob(type: self.jobState),
            startTime: start,
            endTime: stop,
            desc: self.jobDescription,
            undoable: false
        )
    }
    
    
    func shiftTimer(shiftMins: Int) {
        self.startTime = roundTime(time: self.startTime.addMinutes(minutes: shiftMins))
        self.updateLiveActivity()
    }
    
    
    func enableDisableLiveAcitivty() {
        if (self.running) {
            LiveActivitySystem.shared.stopLiveActivity()
            
            LiveActivitySystem.shared.startLiveActivity(
                startTime: self.startTime,
                jobState: self.jobState.rawValue,
                jobColor: getJobColor(jobID: self.jobState.rawValue)
            )
        } else {
            LiveActivitySystem.shared.stopLiveActivity()
        }
    }
    func updateLiveActivity(saveState: Bool = false) {
        LiveActivitySystem.shared.updateActivity(
            startTime: self.startTime,
            jobState: self.jobState.rawValue,
            jobColor: getJobColor(jobID: self.jobState.rawValue),
            saveState: saveState
        )
    }
    func updateLiveActivity(saveState: Bool, newTitle: String) {
        LiveActivitySystem.shared.updateActivity(
            startTime: self.startTime,
            jobState: newTitle,
            jobColor: getJobColor(jobID: self.jobState.rawValue),
            saveState: saveState
        )
    }
}
