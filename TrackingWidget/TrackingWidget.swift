//
//  TrackingWidget.swift
//  TrackingWidgetExtension
//
//  Created by Hayden Steele on 6/26/24.
//

import Foundation
import SwiftUI
import WidgetKit


struct TrackingWidgetEntry: TimelineEntry {
    var date: Date
    
    var jobTypeID : String
    var startTime : Date
    var endTime : Date
}


struct TrackingWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TrackingWidgetEntry {
        
        return TrackingWidgetEntry(
            date: Date(),
            jobTypeID: getIDFromJob(type: .Manager),
            startTime: roundTime(time: Date().addMinutes(minutes: -30)),
            endTime: roundTime(time: Date())
        )
    }
    
    
    func getSnapshot(in context: Context, completion: @escaping (TrackingWidgetEntry) -> Void) {
       
        if (context.isPreview) {
            completion(TrackingWidgetEntry(
                date: Date(),
                jobTypeID: getIDFromJob(type: .Manager),
                startTime: roundTime(time: Date().addMinutes(minutes: -30)),
                endTime: roundTime(time: Date())
            )
)
        } else {
            let entry = TrackingWidgetEntry(
                date: Date(),
                jobTypeID: getIDFromJob(type: .Manager),
                startTime: Date().addMinutes(minutes: -30),
                endTime: Date()
            )

            completion(entry)
        }
    }
    
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TrackingWidgetEntry>) -> Void) {
        
        var entries : [TrackingWidgetEntry] = []
        
//        let currentDate = Date()
//        for minOff in 0 ..< 4 {
//            
//        }
//        let entryDate = currentDate.addMinutes(minutes: 15)
        
        let entry = TrackingWidgetEntry(
            date: Date(),
            jobTypeID: getIDFromJob(type: .Manager),
            startTime: Date().addMinutes(minutes: -30),
            endTime: Date()
        )
        entries.append(entry)
        
        let timeline = Timeline(entries: entries, policy: .never)
        completion(timeline)
    }
    
    typealias Entry = TrackingWidgetEntry

}






struct TrackingWidget : Widget {
    let kind: String = "Widget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TrackingWidgetProvider()) { entry in
            
            TrackingWidgetView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName("Timer Widget")
        .description("Shows the current state of the tracker.")
    }
}





struct TrackingWidgetView : View {
    var entry: TrackingWidgetProvider.Entry
    
    var body: some View {
        ZStack() {
            VStack(alignment: .leading) {
                
                
                HStack() {
                    
                    VStack(alignment: .leading) {
                        let color = getJobColor(jobID: getJobFromID(id: self.entry.jobTypeID).rawValue)
                        
                        Text(getJobFromID(id: self.entry.jobTypeID).rawValue)
                            .fontWeight(.black)
                            .foregroundColor(color)
                            .font(.title2)
                        
                        Text(self.entry.startTime, style: .date)
                            .foregroundColor(.white)
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text(
                            self.entry.startTime.getTimeText()
                            + " - "
                            + self.entry.endTime.getTimeText()
                        )
                            .foregroundColor(.white)
                            .font(.title3)
                            .fontWeight(.bold)
                        
                    }
                    
                    Spacer()
                    
                    VStack() {
                        
                        let num = self.entry.startTime.hrsOffset(relativeTo: self.entry.endTime)
                        
                        Text(
                            String(num)
                            + ((num == 1.0) ? " hr" : " hrs")
                        )
                        .foregroundColor(.white)
                        .font(.title2)
                        .fontWeight(.black)
                        .monospaced()
                    }
                        
            
                }
            } // VStack
        }
    }
}



#Preview(as: .systemMedium) {
    TrackingWidget()
} timeline: {
    TrackingWidgetEntry(
        date: Date(),
        jobTypeID: getIDFromJob(type: .Manager),
        startTime: Date().addMinutes(minutes: -30),
        endTime: Date()
    )
}
