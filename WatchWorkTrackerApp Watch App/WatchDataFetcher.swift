//
//  WatchDataFetcher.swift
//  WorkTracker
//
//  Created by Hayden Steele on 7/30/24.
//

import Foundation
import Observation
import SwiftUI


@Observable
class WatchDataFetcher {
    static var shared = WatchDataFetcher()
    
    
    // Observable Data	
    public var error : Bool = false
    public var currentTimerStatus : TimerStatus = TimerStatus()
    public var jobEntries : [JobEntry]? = nil
    
    
    
    init() {
        
        // Add Data Reciveing Callback
        DataTransferSystem.shared.dataReceived = { (key, message) in
            print("WATCH: Key \(key)")
            print("WATCH: Message \(message)")
            
            if (key == DataTransferSystem.Messages.ReplyEntries.rawValue) { // Accept the entries reply
                
                do {
                    let data : String = message as! String
                    
                    let jsonData = data.data(using: .utf8)
                    let jsonArray = try JSONSerialization.jsonObject(with: jsonData!, options: []) as! [[String: String]]
                    
                    self.jobEntries = []
                    
                    withAnimation {
                        for jsonDict in jsonArray {
                            let entity = JobEntry()
                            entity.fromDictionary(dictionary: jsonDict)
                            self.jobEntries?.append(entity)
                        }
                    }
                } catch {
                    self.jobEntries = nil
                    self.error = true
                }
                
                
            }
            
            if (key == DataTransferSystem.Messages.ReplyTimer.rawValue) { // Accept the timer reply
                
                let data : String = message as! String
                
                withAnimation {
                    self.currentTimerStatus = TimerStatus(data)
                }
                
            }
            
        }
        
        
        DispatchQueue.main.async {
            self.fetchTimerStatus()
            self.fetchJobEntires(pprd: getCurrentPayperiod())
        }
    }
    
    
    
    /// Sends a fetch request to the iPhone asking for the current ``TimerStatus``
    func fetchTimerStatus() {
//        withAnimation {
//            self.currentTimerStatus.jobState = .undef
//        }
        
        let result = DataTransferSystem.shared.sendMessage(DataTransferSystem.Messages.RequestTimer.rawValue, "") {error in
            print(error)
            self.error = true
        }
        self.error = !result
    }
    
    
    
    /// Sends a the  ``TimerStatus`` to the iPhone
    /// - Parameter status: The new status to send
    func sendTimerStatus(status : TimerStatus) {
        let result = DataTransferSystem.shared.sendMessage(DataTransferSystem.Messages.SendTimerState.rawValue, status.toJSONString()) { error in
            print(error)
            self.error = true
        }
        self.error = !result
        
        if (!self.error) {
            self.fetchTimerStatus()
        }
    }
    
    /// Sends a the currently stored ``TimerStatus`` to the iPhone
    func sendTimerStatus() {
        self.sendTimerStatus(status: self.currentTimerStatus)
    }
    
    
    /// Sends a fetch request to the iPhone for a ``JobEntry`` array with the selected ``PayPeriod`` view bounds
    /// - Parameter pprd: The ``PayPeriod`` range for the requested ``JobEntry`` array
    func fetchJobEntires(pprd : PayPeriod) {
        withAnimation {
            self.jobEntries = nil
            self.error = false
        }
        
        let result = DataTransferSystem.shared.sendMessage(DataTransferSystem.Messages.RequestEntries.rawValue, pprd.toString(full: true, fileSafe: true), { error in
            print(error)
            self.error = true
        })
        self.error = !result
    }
}
