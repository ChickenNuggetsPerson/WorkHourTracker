//
//  Gobals.swift
//  WorkTracker
//
//  Created by Hayden Steele on 5/28/24.
//


import Foundation
import SwiftUI
import Combine

struct PayPeriod {
    var startDate: Date
    var endDate: Date
    
    func getRange() -> ClosedRange<Date> {
        return self.startDate.clearTime()...self.endDate.edgeDay()
    }
    
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
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    
    var now = Date()

    var start = Date()
    var end = formatter.date(from: "2024-05-18") ?? Date()
    
    
    now = now.clearTime()
    end = end.clearTime()

    while (now > end) {
        end = end.addDays(days: 14)
    }
    
    start = end.addDays(days: -13)
    
    return PayPeriod(startDate: start, endDate: end)
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
    func addMinutes(minutes: Int) -> Date {
        return Calendar.current.date(byAdding: .minute, value: minutes, to: self)!
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
    
    func getDateComponents() -> DateComponents {
        return Calendar.current.dateComponents([.era, .year, .month, .day, .hour, .minute], from: self)
    }
    
    func dayString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E - MMM d, yyyy"
        return dateFormatter.string(from: self)
    }
}





enum JobTypes : String, CaseIterable {
    case JRTech = "Junior Tech"
    case SRTech = "Senior Tech"
    case Manager = "Rentals Manager"
    case IT = "IT"
    case undef
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






func getJobColor(running: Bool, jobID: String) -> Color {
    if (!running) {
        return Color.gray
    }
    
    switch(jobID) {
        case JobTypes.JRTech.rawValue:
            return Color.orange
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
