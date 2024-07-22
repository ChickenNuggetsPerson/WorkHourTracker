//
//  Sharesheet.swift
//  WorkTracker
//
//  Created by Hayden Steele on 5/31/24.
//

import Foundation
import SwiftUI
import UIKit
import PDFKit



//func createAndSharePDF(entries : [JobEntry], payperiod: PayPeriod, showingDesc: Bool) {
//    
//
//    // Save PDF to a temporary file
//    do {
//
//        let temporaryURL = createTimeCardPDF(
//            entries: entries,
//            payperiod: payperiod,
//            showingDesc: showingDesc
//        )
//        
//        let items: [Any] = [temporaryURL]
//        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
//        UIApplication.shared.windows.first?.rootViewController?.present(controller, animated: true)
//        
//    }
//}




func createTimeCardPDF(entries : [JobEntry], payperiod: PayPeriod, showingDesc: Bool) -> URL {
    
    var totalHours = 0.0
    
    let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842)) // A4 paper size
    
    let data = pdfRenderer.pdfData { context in
        
        context.beginPage()
        
        let boldTitle = [
            NSAttributedString.Key.font: UIFont.monospacedSystemFont(ofSize: 20, weight: .black)
        ]
        let smallTitle = [
            NSAttributedString.Key.font: UIFont.monospacedSystemFont(ofSize: 10, weight: .black)
        ]
        let normalText = [
            NSAttributedString.Key.font: UIFont.monospacedSystemFont(ofSize: 10, weight: .semibold)
        ]
        
        
        let text = "Timecard for: " + payperiod.toString(full: true)
        text.draw(at: CGPoint(x: 20, y: 30), withAttributes: boldTitle)
        
        var yOffset = 75
        
        let jobXpos = 20
        let starTimeXPos = 150
        let endTimeXPos = 230
        let totalTimeXPos = 300
        let descXPos = 380
        
        let titlesOff = 70
        "Type of Hours: ".draw(at: CGPoint(x: jobXpos, y: titlesOff), withAttributes: smallTitle)
        "Start Time: ".draw(at: CGPoint(x: starTimeXPos, y: titlesOff), withAttributes: smallTitle)
        "End Time: ".draw(at: CGPoint(x: endTimeXPos, y: titlesOff), withAttributes: smallTitle)
        "Duration: ".draw(at: CGPoint(x: totalTimeXPos, y: titlesOff), withAttributes: smallTitle)
        "Description: (If applicable)".draw(at: CGPoint(x: descXPos, y: titlesOff), withAttributes: smallTitle)
        
        var previousDate: Int? = nil
        
        for entry in entries {
            
            if let entryDate = entry.startTime.getDateComponents().day {
                if (entryDate != previousDate) { // Diff Day
                    
                    yOffset += 10
                    
                    // Draw line
                    context.cgContext.move(to: CGPoint(x: 20, y: yOffset))
                    context.cgContext.addLine(to: CGPoint(x: 575, y: yOffset))
                    context.cgContext.setStrokeColor(UIColor.black.cgColor)
                    context.cgContext.setLineWidth(1)
                    context.cgContext.strokePath()
                    
                    yOffset += 7
                    
                    // Day Header
                    (
                        entry.startTime.timecardDayString()
                        + " -> "
                        + String(entries.getEntriesFromDay(day: entry.startTime).sumAllHours())
                        + " hrs"
                    )
                    .draw(at: CGPoint(x: jobXpos, y: yOffset), withAttributes: smallTitle)
                    
                    
                    yOffset += 20
                    
                    previousDate = entryDate
                    
                }
            }
            
            // Job Text
            (getJobFromID(id: entry.jobTypeID).rawValue).draw(at: CGPoint(x: jobXpos, y: yOffset), withAttributes: normalText)
            
            // Start Text
            entry.startTime.getTimeText().draw(at: CGPoint(x: starTimeXPos, y: yOffset), withAttributes: normalText)
            
            // End Text
            entry.endTime.getTimeText().draw(at: CGPoint(x: endTimeXPos, y: yOffset), withAttributes: normalText)
            
            // Total Time
            entry.startTime.hrsOffset(relativeTo: entry.endTime).draw(at: CGPoint(x: totalTimeXPos, y: yOffset), withAttributes: normalText)
            
            // Desc
            let desc = entry.desc
            
            if (showingDesc) {
                let description = wrapText(
                    str: desc,
                    charWidth: 10,
                    lineWidth: 250
                )
                
                for sub in description {
                    String(sub).draw(at: CGPoint(x: descXPos, y: yOffset), withAttributes: normalText)
                    yOffset += 11
                    
                    if (yOffset >= 780) {
                        yOffset = 55
                        context.beginPage()
                    }
                }
                
                if (description.count != 0) {
                    yOffset -= 11
                }
            }
            
            
            yOffset += 15
            
            
            if (yOffset >= 780) {
                yOffset = 55
                context.beginPage()
            }
            
            totalHours += entry.startTime.hrsOffset(relativeTo: entry.endTime)
        } // End of entry loop
        
        
        yOffset += 10
        if (yOffset >= 710) {
            yOffset = 55
            context.beginPage()
        }
        
        // Draw line
        context.cgContext.move(to: CGPoint(x: 20, y: yOffset))
        context.cgContext.addLine(to: CGPoint(x: 575, y: yOffset))
        context.cgContext.setStrokeColor(UIColor.black.cgColor)
        context.cgContext.setLineWidth(1)
        context.cgContext.strokePath()
        
        yOffset += 7
        
        ("Total Hours: " + String(totalHours) + " hrs").draw(at: CGPoint(x: jobXpos, y: yOffset), withAttributes: smallTitle)
        yOffset += 5
        entries.getHoursTotals().toText().draw(at: CGPoint(x: jobXpos, y: yOffset), withAttributes: normalText)
        
    }
    
    
    
    // Save PDF to a temporary file
    do {
        let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            payperiod.toString(fileSafe: true) + ".pdf"
        )
        try data.write(to: temporaryURL)
        
        return temporaryURL
        
    } catch {
        return URL(fileURLWithPath: "")
    }
}




extension [JobEntry] {
    func getEntriesFromDay(day: Date) -> [JobEntry] {
        let desiredDay = day.clearTime()
        
        return self.filter { $0.startTime.clearTime() == desiredDay }
    }
    
    func sumAllHours() -> Double {
        var total = 0.0
        
        for entry in self {
            total += entry.startTime.hrsOffset(relativeTo: entry.endTime)
        }
        
        return total
    }
}



func wrapText(str : String, charWidth : Int, lineWidth : Int) -> [Substring] {
    
    var newStr = ""
    let words = str.split(separator: " ")
    
    var runningWidth = 0;
    
    for word in words {
        runningWidth += (word.count + 1) * charWidth
        newStr += word
        newStr += " "
        
        if (runningWidth > lineWidth) {
            newStr += "\n"
            runningWidth = 0
        }
        
        if (word.hasSuffix("\n") || word.hasPrefix("\n")) {
            runningWidth = 0
        }
    }
        
    return newStr.split(separator: "\n")
}
