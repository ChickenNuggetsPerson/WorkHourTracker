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



func createAndSharePDF(entries : [JobEntry], payperiod: PayPeriod) {
    
    
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
        text.draw(at: CGPoint(x: 20, y: 20), withAttributes: boldTitle)

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
            
            if let entryDate = entry.startTime?.getDateComponents().day {
                if (entryDate != previousDate) { // Diff Day

                    yOffset += 10
                    
                    context.cgContext.move(to: CGPoint(x: 20, y: yOffset))
                    context.cgContext.addLine(to: CGPoint(x: 575, y: yOffset))
                    context.cgContext.setStrokeColor(UIColor.black.cgColor)
                    context.cgContext.setLineWidth(1)
                    context.cgContext.strokePath()
                    
                    yOffset += 10
                    
                    entry.startTime?.timecardDayString().draw(at: CGPoint(x: jobXpos, y: yOffset), withAttributes: smallTitle)
                    
                    
                    yOffset += 15
                    
                    previousDate = entryDate
                    
                }
           }
            
            // Job Text
            (getJobFromID(id: entry.jobID ?? "Error").rawValue).draw(at: CGPoint(x: jobXpos, y: yOffset), withAttributes: normalText)
            
            // Start Text
            (dateToTime(date: entry.startTime ?? Date())).draw(at: CGPoint(x: starTimeXPos, y: yOffset), withAttributes: normalText)
            
            // End Text
            (dateToTime(date: entry.endTime ?? Date())).draw(at: CGPoint(x: endTimeXPos, y: yOffset), withAttributes: normalText)
            
            // Total Time
            (String(entry.startTime?.hrsOffset(relativeTo: entry.endTime ?? Date()) ?? -100) + " hrs").draw(at: CGPoint(x: totalTimeXPos, y: yOffset), withAttributes: normalText)
            
            // Desc
            let desc = entry.desc ?? ""
            let (wrappedDesc, lines) = wrapText(
                str: desc,
                charWidth: 10,
                lineWidth: 250
            )
            wrappedDesc.draw(at: CGPoint(x: descXPos, y: yOffset), withAttributes: normalText)
            
            yOffset += 30 + (lines * 12)
            
            
            if (yOffset >= 800) {
                yOffset = 55
                context.beginPage()
            }
        }
    
    }
    
    

    // Save PDF to a temporary file
    do {
        let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            payperiod.toString(fileSafe: true) + ".pdf"
        )
        try data.write(to: temporaryURL)
        
        let items: [Any] = [temporaryURL]
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(controller, animated: true)
        
        
    } catch {}
}






func wrapText(str : String, charWidth : Int, lineWidth : Int) -> (String, Int) {
    
    var newStr = ""
    let words = str.split(separator: " ")
    
    var runningWidth = 0;
    var amtLines = 1
    
    for word in words {
        runningWidth += (word.count + 1) * charWidth
        newStr += word
        newStr += " "
        
        if (runningWidth > lineWidth) {
            newStr += "🤪\n"
            runningWidth = 0
            amtLines += 1
        }
        
        if (word.hasSuffix("\n") || word.hasPrefix("\n")) {
            runningWidth = 0
            amtLines += 1
        }
    }
    
    return (newStr, amtLines)
}
