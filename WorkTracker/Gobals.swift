//
//  Gobals.swift
//  WorkTracker
//
//  Created by Hayden Steele on 5/28/24.
//


import Foundation
import SwiftUI
import Combine
import AppIntents


func roundTime(time: Date) -> Date {
    var components = time.getDateComponents()
    components.second = 0;
 
    let modded = Int(components.minute ?? 0) % 15
    var off = 0
    if (modded >= 7) {
        off = 15 - modded
    } else {
        off = -modded
    }
    
    components.minute = (components.minute ?? 0) + off
    if ((components.minute ?? 0) >= 60) {
        components.minute = 0;
        components.hour = (components.hour ?? 0) + 1
    }
    
    return Calendar.current.date(from: components) ?? Date()
}



extension Date {
    
    func addDays(days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: days, to: self)!
    }
    func addHours(hours: Int) -> Date {
        return Calendar.current.date(byAdding: .hour, value: hours, to: self)!
    }
    func addHours(hours: Double) -> Date {
        let hrs : Int = Int(floor(hours))
        var mins = hours - floor(hours)
        mins *= 60
        
        return self.addHours(hours: hrs).addMinutes(minutes: Int(mins))
    }
    func addMinutes(minutes: Int) -> Date {
        return Calendar.current.date(byAdding: .minute, value: minutes, to: self)!
    }
    func addSeconds(seconds: Int) -> Date {
        return Calendar.current.date(byAdding: .second, value: seconds, to: self)!
    }
    
    
    func clearTime() -> Date {
        var components = self.getDateComponents()
        components.second = 0
        components.minute = 0
        components.hour = 0
        return Calendar.current.date(from: components) ?? Date()
    }
    func edgeDay() -> Date {
        var components = self.getDateComponents()
        components.second = 59
        components.minute = 59
        components.hour = 23
        return Calendar.current.date(from: components) ?? Date()
    }
    
    
   
    func hrsOffset(relativeTo: Date = Date()) -> Double {
        return floor(relativeTo.timeIntervalSince(self) / 36) / 100
    }
    func hrsOffset(relativeTo: Date = Date()) -> String {
        return self.hrsOffset(relativeTo: relativeTo).toHrsString()
    }
    
    
    func getDateComponents() -> DateComponents {
        return Calendar.current.dateComponents([.era, .year, .month, .day, .hour, .minute], from: self)
    }
    
    
    
    
    func timecardDayString() -> String { //     Tue July 26, 2024
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E MMM d, yyyy"
        return dateFormatter.string(from: self)
    }
    
    func toHeaderText() -> String { //          Monday: 1/05/24
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE: M/d/yy"
        return dateFormatter.string(from: self)
    }
    
    func getTimeText() -> String { //           12:00 PM
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    func toDate() -> String { //                July 4, 2024
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        return dateFormatter.string(from: self)
    }
}





enum JobTypes : String, CaseIterable, AppEnum {
    
    case JRTech = "Junior Tech"
    case SRTech = "Senior Tech"
    case Manager = "Rentals Manager"
    case IT = "IT"
    case undef
    
    var id: String { rawValue }
       
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "JobTypes")
    }
       
    static var caseDisplayRepresentations: [JobTypes : DisplayRepresentation] {
        [
           .JRTech: DisplayRepresentation(title: "Junior Tech"),
           .SRTech: DisplayRepresentation(title: "Senior Tech"),
           .Manager: DisplayRepresentation(title: "Rentals Manager"),
           .IT: DisplayRepresentation(title: "IT"),
           .undef: DisplayRepresentation(title: "Undef")
        ]
    }
    
    static var siriDisplayRepresentations: [JobTypes : DisplayRepresentation] {
        caseDisplayRepresentations.filter { $0.key != .IT && $0.key != .undef }
    }
}

func getIDFromJob(type: JobTypes) -> String {
    switch (type) {
        case .JRTech:
            return "JRTECH"
        case .SRTech:
            return "SRTECH"
        case .Manager:
            return "MANAGER"
        case .IT:
            return "IT"
        case .undef:
            return ""
    }
}
func getJobFromID(id: String) -> JobTypes {
    switch (id) {
        case "JRTECH":
            return .JRTech
        case "SRTECH":
            return .SRTech
        case "MANAGER":
            return .Manager
        case "IT":
            return .IT
        
        default:
            return .undef
    }
    
}
func getPayFromJob(id: String, hrs: Double) -> Double {
    
    var rate = 0.0
    
    switch (getJobFromID(id: id)) {
        case .JRTech:
            rate = 15.6
        case .SRTech:
            rate = 35
        case .Manager:
            rate = 35
        case .IT:
            rate = 16.5
        case .undef:
            rate = 0
    }
    
    return rate * hrs * 0.88
}


func getJobColor(jobID: String) -> Color {
    
    switch(jobID) {
        case JobTypes.JRTech.rawValue:
            return Color.init(hex: "#FF6463")
        case JobTypes.SRTech.rawValue:
            return Color.green
        case JobTypes.Manager.rawValue:
            return Color.blue
        case JobTypes.IT.rawValue:
            return Color.purple
        
        default:
            return Color.gray
    }
}


typealias JobHoursDict = [ JobTypes : Double ]
extension [JobEntry] {
    func getHoursTotals() -> JobHoursDict {
        var jobHours : JobHoursDict = [:]
        for job in JobTypes.allCases {
            jobHours[job] = 0.0
        }
        
        for entry in self {
            let hrs : Double = entry.startTime.hrsOffset(relativeTo: entry.endTime)
            let jobID = getJobFromID(id: entry.jobTypeID)
            jobHours[jobID]! += hrs
        }
        
        return jobHours
    }
}
extension JobHoursDict {
    func toText() -> String {
        var infoTXT = ""
        
        for job in JobTypes.allCases {
            let hrs = self[job] ?? 0.0
            if (hrs == 0.0) { continue; }
            
            infoTXT += "\n"
            infoTXT += job.rawValue
            infoTXT += ": "
            infoTXT += String(hrs)
            infoTXT += " hrs"
        }
        
        return infoTXT
    }
}



extension Double {
    func toString() -> String {
        return String(floor(self * 100) / 100)
    }
    func toHrsString() -> String {
        if (self == 1.0) {
            return self.toString() + " hr"
        } else {
            return self.toString() + " hrs"
        }
    }
    func toMoneyString() -> String {
        return "$" + self.toString()
    }
}

class EmptyObject {}







