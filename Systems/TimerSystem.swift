//
//  TimerSystem.swift
//  WorkTracker
//
//  Created by Hayden Steele on 6/20/24.
//

import Foundation
import WidgetKit


public struct TimerStatus : Equatable {
    var running : Bool = false
    var jobState : JobTypes = .undef
    var startTime : Date = Date()
    
    
    
    
    func toJSONString() -> String {
        let dict : [String: String] = [
            "running": self.running ? "true" : "false",
            "jobState": self.jobState.rawValue,
            "startTime": self.startTime.description,
       ]
        do {
            let data = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
            return String(data: data, encoding: .utf8)!
        } catch {
            return ""
        }
    }
    static func fromJSONString(_ str: String) -> TimerStatus {
        do {
            let jsonData = str.data(using: .utf8)!
            let jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as! [String: String]

            var stats = TimerStatus()
            stats.running = jsonDict["running"] == "true"
            stats.jobState = JobTypes(rawValue: jsonDict["jobState"]!) ?? .undef
            stats.startTime = convertStringToDate(jsonDict["startTime"]!)
            
            return stats
        } catch {
            return TimerStatus()
        }
    }
}



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
    

    
    func acceptWatchStatus(state: TimerStatus) {
        let prevRunning = self.running
        
        self.running = state.running
        self.jobState = state.jobState
        self.startTime = roundTime(time: state.startTime)
        
        if (!prevRunning && state.running) { // Timer Started
            self.startTime = roundTime(time: Date())
            self.enableDisableLiveAcitivty()
            return
        }
        if (prevRunning && !state.running) { // Timer Stopped
        
            if (roundTime(time: self.startTime) != roundTime(time: Date())) {
                self.save()
            }
            
            self.enableDisableLiveAcitivty()
            return
        }
        
        // Data Updated
        self.updateLiveActivity()
    }
    
    
    
    func toggleTimer() { // Start - Stop Button
        self.running.toggle()
        if (self.running) {
            self.startTimer()
        } else {
            self.stopTimer()
        }
        
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
        #if os(iOS)
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
        #endif
    }
    func updateLiveActivity(saveState: Bool = false) {
    #if os(iOS)
        LiveActivitySystem.shared.updateActivity(
            startTime: self.startTime,
            jobState: self.jobState.rawValue,
            jobColor: getJobColor(jobID: self.jobState.rawValue),
            saveState: saveState
        )
    #endif
    }
    func updateLiveActivity(saveState: Bool, newTitle: String) {
    #if os(iOS)
        LiveActivitySystem.shared.updateActivity(
            startTime: self.startTime,
            jobState: newTitle,
            jobColor: getJobColor(jobID: self.jobState.rawValue),
            saveState: saveState
        )
    #endif
    }
    
}
