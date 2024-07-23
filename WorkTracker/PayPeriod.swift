//
//  PayPeriod.swift
//  WorkTracker
//
//  Created by Hayden Steele on 7/22/24.
//

import Foundation



struct PayPeriod : Equatable, Sendable, Hashable {
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


func getCurrentWeek() -> PayPeriod {
    let dateRange = Calendar.current.dateInterval(of: .weekOfYear, for: Date())
    return PayPeriod(startDate: dateRange!.start, endDate: dateRange!.end)
}
