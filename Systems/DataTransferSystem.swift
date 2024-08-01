//
//  DataTransferSystem.swift
//  WorkTracker
//
//  Created by Hayden Steele on 7/30/24.
//

import Foundation
import WatchConnectivity


class DataTransferSystem: NSObject, WCSessionDelegate {
    static var shared = DataTransferSystem()
    
    public enum Messages : String {
        case RequestEntries = "Request Entries"
        case ReplyEntries = "Reply Entries"
        
        // From the Watch's POV
        case RequestTimer = "Request Timer"
        case ReplyTimer = "Reply Timer"
        case SendTimerState = "Send Timer State"
    }
    
    
    private var session: WCSession = WCSession.default

    func wakeUpSystem() {
        #if os(iOS)
        print("IPHONE: Waking Up Transfer System")
        #else
        print("WATCH: Waking Up Transfer System")
        #endif
    }
    init(session: WCSession = .default) {
        #if os(iOS)
        print("IPHONE: Init DataTransferrClass")
        #else
        print("WATCH: Init DataTransferrClass")
        #endif
        
        self.session = session

        super.init()

        self.session.delegate = self
        self.connect()
    }
    
    
    func connect() {
        guard WCSession.isSupported() else {
            print("WCSession is not supported")
            return
        }
        
        session.activate()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) { }

    func sessionDidDeactivate(_ session: WCSession) { }
    #endif
    
    
    func sendMessage(_ key: String, _ message: String, _ errorHandler: ((Error) -> Void)?) -> Bool {
        if session.isReachable {
            #if os(iOS)
            print("IPHONE: Sending Message (\(key), \(message))")
            #else
            print("WATCH: Sending Message (\(key), \(message))")
            #endif
            session.sendMessage([key : message], replyHandler: nil) { (error) in
                print(error.localizedDescription)
                if let errorHandler = errorHandler {
                    errorHandler(error)
                }
            }
            return true
        } else {
            #if os(iOS)
            print("IPHONE: Source Not Reachable")
            #else
            print("WATCH: Source Not Reachable")
            #endif
            return false
        }
    }
    
    
    #if os(iOS)
    var dataReceived: ((String, Any) -> Void)? = { (key, message) in // iPhone
        print("iPhone: Data Recieved: \(key)")
        print("iPhone: Data Recieved: \(message)")
        
        handleRecivedData(key: key, message: message)
    }
    #else
    var dataReceived: ((String, Any) -> Void)? // Watch
    #endif

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        guard dataReceived != nil else {
            print("Received data, but 'dataReceived' handler is not provided")
            return
        }
            
        DispatchQueue.main.async {
            if let dataReceived = self.dataReceived {
                for pair in message {
                    dataReceived(pair.key, pair.value)
                }
            }
        }
    }
}





#if os(iOS)



func handleRecivedData(key : String, message: Any) {
    
    
    if (key == DataTransferSystem.Messages.RequestEntries.rawValue) { // Watch Requested Entries
        
        let range: String = message as! String
        
        let entries = DataStorageSystem.shared.fetchJobEntries(dateRange: PayPeriod(entityID: range).range)
        let jsonArray = entries.map { $0.toDict(stripDesc: true) }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted)
            let jsonString = String(data: jsonData, encoding: .utf8)
            
            DataTransferSystem.shared.sendMessage(DataTransferSystem.Messages.ReplyEntries.rawValue, jsonString ?? "[]", { error in
                print(error)
            })
        } catch { }
        
    }
    
    
    if (key == DataTransferSystem.Messages.RequestTimer.rawValue) { // Watch Requested Timer
        
        
        var timerState = TimerStatus()
        timerState.running = TimerSystem.shared.running
        timerState.jobState = TimerSystem.shared.jobState
        
        DataTransferSystem.shared.sendMessage(DataTransferSystem.Messages.ReplyTimer.rawValue, timerState.toJSONString(), { error in
            print(error)
        })
        
    }
    
    
    
    if (key == DataTransferSystem.Messages.SendTimerState.rawValue) { // Watch Set Timer
        
        let data: String = message as! String
        var newTimerState = TimerStatus(data)
        
        if (newTimerState.jobState == .undef) {
            print("Error: New timer state from watch is undefined")
            return
        }
        
        TimerSystem.shared.acceptWatchStatus(state: newTimerState)
    }
    
    
}



#endif
