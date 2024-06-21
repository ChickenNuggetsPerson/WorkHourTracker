//
//  TimerSystem.swift
//  WorkTracker
//
//  Created by Hayden Steele on 6/20/24.
//

import Foundation


class TimerSystem : ObservableObject {
    static let shared = TimerSystem()
    
    
    @Published var running : Bool {
        didSet {
            UserDefaults.standard.set(self.running, forKey: "running")
        }
    }
    @Published var jobState : JobTypes {
        didSet {
            UserDefaults.standard.set(self.jobState.rawValue, forKey: "jobType")
        }
    }
    @Published var startTime : Date {
        didSet {
            UserDefaults.standard.set(self.startTime, forKey: "startTime")
        }
    }
    @Published var jobDescription : String {
        didSet {
            UserDefaults.standard.set(self.jobDescription, forKey: "desc")
        }
    }
    
    
    
    init() {
        if let storedTime = UserDefaults.standard.object(forKey: "startTime") as? Date {
            self.startTime = storedTime
    
        } else {
            print("Could not read")
            self.startTime = roundTime(time: Date())
        }
        
        self.running = UserDefaults.standard.bool(forKey: "running")
        self.jobState = JobTypes(rawValue: UserDefaults.standard.string(forKey: "jobType") ?? JobTypes.Manager.rawValue)!
        
        self.jobDescription = UserDefaults.standard.string(forKey: "desc") ?? ""
        
        self.enableDisableLiveAcitivty()
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
        UserDefaults.standard.set(self.running, forKey: "running")
        self.startTime = roundTime(time: Date())
        self.enableDisableLiveAcitivty()
    }
    func stopTimer() {
        self.running = false
        UserDefaults.standard.set(self.running, forKey: "running")
        self.jobDescription = ""
        self.enableDisableLiveAcitivty()
    }
    
    func save() {
        let start = self.startTime
        let stop = roundTime(time: Date())
        
        CoreDataManager.shared.createJobEntry(
            desc: self.jobDescription,
            jobID: getIDFromJob(type: self.jobState),
            startTime: start,
            endTime: stop
        )
    }

    
}
