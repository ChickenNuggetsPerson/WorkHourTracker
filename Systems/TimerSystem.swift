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
    
    
    init() {}
    init(running: Bool, jobState: JobTypes) {
        self.running = running
        self.jobState = jobState
    }
    init(running: Bool, jobState: JobTypes, startTime: Date) {
        self.running = running
        self.jobState = jobState
        self.startTime = startTime
    }
    init(_ str: String) {
        self.fromJSONString(str)
    }
    
    
    /// Converts the ``TimerStatus`` to a JSON String
    /// - Returns: The JSON String representaion
    func toJSONString() -> String {
        let dict : [String: String] = [
            "running": self.running ? "true" : "false",
            "jobState": self.jobState.rawValue,
            "startTime": self.startTime.description
       ]
        do {
            let data = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
            return String(data: data, encoding: .utf8)!
        } catch {
            return ""
        }
    }
    
    
    /// Creates a ``TimerStatus`` Struct from a JSON String
    /// - Parameter str: The JSON representation of the object
    /// - Returns: The parsed ``TimerStatus``
    mutating func fromJSONString(_ str: String) {
        do {
            let jsonData = str.data(using: .utf8)!
            let jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as! [String: String]
            
            self.running = jsonDict["running"] == "true"
            self.jobState = JobTypes(rawValue: jsonDict["jobState"]!) ?? .undef
            self.startTime = convertStringToDate(jsonDict["startTime"] ?? "")
            
        } catch {
            
        }
    }
}






/// The System used by the whole app to use the timer. Make sure to use ``TimerSystem.shared`` instead of making new instances of this class. This ensures the timer is maintained across instances.
class TimerSystem : ObservableObject {
    static let shared = TimerSystem()
    
    private let userDefaults = UserDefaults(suiteName: "group.com.steele.Worktracker.sharedData")
    
    
    /// The current running state of the timer
    @Published var running : Bool {
        didSet {
            userDefaults!.set(self.running, forKey: "running")
        }
    }
    
    
    /// The current ``JobTypes`` of the timer
    @Published var jobState : JobTypes {
        didSet {
            userDefaults!.set(self.jobState.rawValue, forKey: "jobType")
        }
    }
    
    
    /// The time that the timer started
    @Published var startTime : Date {
        didSet {
            userDefaults!.set(self.startTime, forKey: "startTime")
        }
    }
    
    
    /// The currently stored job description
    @Published var jobDescription : String {
        didSet {
            userDefaults!.set(self.jobDescription, forKey: "desc")
        }
    }
    
    
    /// Returns true if the timer can be saved. This means that the rounded ``TimerSystem.startTime`` is not equal to the currnet rounded time
    var isValidTime : Bool {
        self.startTime.hrsOffset(relativeTo: roundTime(time: Date())) != 0.0
    }
    
    
    
    /// Initializes all stored properties 
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
    

    func acceptNotificationStatus(state: TimerStatus) {
        let prevRunning = self.running
        
        self.running = state.running
        self.jobState = state.jobState
        
        if (!prevRunning && state.running) { // Timer Started
            self.startTime = roundTime(time: state.startTime)
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
    func acceptWatchStatus(state: TimerStatus) {
        let prevRunning = self.running
        
        self.running = state.running
        self.jobState = state.jobState
        
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
