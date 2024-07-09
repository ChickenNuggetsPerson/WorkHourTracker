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

// NULL Object identifier binding -> Binding<ObjectIdentifier?>(get: { nil }, set: { _ in })

struct PayPeriod : Equatable, Sendable {
    var startDate: Date
    var endDate: Date
    
    init(startDate: Date, endDate: Date) {
        self.startDate = startDate.clearTime()
        self.endDate = endDate.edgeDay()
    }
    init(entityID : String) {
        let dates = entityID.components(separatedBy: "_")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
                
        self.startDate = dateFormatter.date(from: dates[0]) ?? Date()
        self.endDate = dateFormatter.date(from: dates[1]) ?? Date()
        
        self.startDate = self.startDate.clearTime()
        self.endDate = self.endDate.edgeDay()
    }
    
    var isCurrent : Bool { return self == getCurrentPayperiod() }
    
    var range : ClosedRange<Date> { self.startDate...self.endDate }
    
    func toString(
        full: Bool = false,
        fileSafe: Bool = false
    ) -> String {
        let dateFormatter = DateFormatter()
        
        if (fileSafe) {
            
            dateFormatter.dateFormat = "MM-dd-yyyy"
            
            return dateFormatter.string(from: startDate) + "_" + dateFormatter.string(from: endDate)
            
        } else {
            
            
            if (full) {
                dateFormatter.dateFormat = "MM/dd/yyyy"
            } else {
                dateFormatter.dateFormat = "M/dd"
            }
            
            return dateFormatter.string(from: startDate) + " - " + dateFormatter.string(from: endDate)
            
            
        }
        
    }
}



func getCurrentPayperiod() -> PayPeriod {
    return getPayPeriod(refDay: Date())
}
func getPayPeriod(refDay : Date) -> PayPeriod {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    
    var now = refDay

    var start = Date()
    var end = formatter.date(from: "2024-05-18") ?? Date()
    
    
    now = now.clearTime()
    end = end.clearTime()

    while (now > end) {
        end = end.addDays(days: 14)
    }
    
    start = end.addDays(days: -13)
    
    return PayPeriod(startDate: start.clearTime(), endDate: end.edgeDay())
}



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
func dateToTime(date: Date) -> String {
    let hour = Calendar.current.component(.hour, from: date)
    let minutes = Calendar.current.component(.minute, from: date)
    
    return String(
        (hour == 0 || hour == 12) ? 12 : hour % 12)
        + ":"
        + (minutes == 0 ? "00" : String(minutes))
        + (hour >= 12 ? " PM" : " AM"
    )
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
        let result = floor(relativeTo.timeIntervalSince(self) / 36) / 100
        
        return String(result) + ((result == 1.0) ? " hr" : " hrs")
    }
    
    
    func getDateComponents() -> DateComponents {
        return Calendar.current.dateComponents([.era, .year, .month, .day, .hour, .minute], from: self)
    }
    
    func timecardDayString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E MMM d, yyyy"
        return dateFormatter.string(from: self)
    }
    
    func toHeaderText() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE: M/d/yy"
        return dateFormatter.string(from: self)
    }
    
    func getTimeText() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    func toDate() -> String {
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
    
    return rate * hrs
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


class EmptyClass {}
