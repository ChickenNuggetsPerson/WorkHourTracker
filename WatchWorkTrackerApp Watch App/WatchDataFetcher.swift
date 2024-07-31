//
//  WatchDataFetcher.swift
//  WorkTracker
//
//  Created by Hayden Steele on 7/30/24.
//

import Foundation
import Observation

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
                    
                    for jsonDict in jsonArray {
                        let entity = JobEntry()
                        entity.fromDictionary(dictionary: jsonDict)
                        self.jobEntries?.append(entity)
                    }
                } catch {
                    self.jobEntries = nil
                    self.error = true
                }
                
                
            }
            
            if (key == DataTransferSystem.Messages.ReplyTimer.rawValue) { // Accept the timer reply
                
                do {
                    let data : String = message as! String
                    self.currentTimerStatus = TimerStatus.fromJSONString(data)
                } catch {
                    self.error = true
                }
                
                
            }
            
        }
        
        
        DispatchQueue.main.async {
            self.fetchTimerStatus()
            self.fetchJobEntires(pprd: getCurrentPayperiod())
        }
    }
    
    
    
    func fetchTimerStatus() {
        let result = DataTransferSystem.shared.sendMessage(DataTransferSystem.Messages.RequestTimer.rawValue, "") {error in
            print(error)
            self.error = true
        }
        self.error = !result
    }
    func sendTimerStatus() {
        let result = DataTransferSystem.shared.sendMessage(DataTransferSystem.Messages.SendTimerState.rawValue, self.currentTimerStatus.toJSONString()) { error in
            print(error)
            self.error = true
        }
        self.error = !result
        
        if (!self.error) {
            self.fetchTimerStatus()
        }
    }
    
    
    func fetchJobEntires(pprd : PayPeriod) {
        let result = DataTransferSystem.shared.sendMessage(DataTransferSystem.Messages.RequestEntries.rawValue, pprd.toString(full: true, fileSafe: true), { error in
            print(error)
            self.error = true
        })
        self.error = !result
    }
}
