//
//  WatchJobEntryView.swift
//  WatchWorkTrackerApp Watch App
//
//  Created by Hayden Steele on 7/30/24.
//


import Foundation
import SwiftUI

struct WatchJobEntryView: View {
    
    @State private var entryID : UUID?
    
    var entryJobID : String
    var entryStart : Date
    var entryEnd : Date
    var entryDesc : String
    
    init( // Main List
        job: JobEntry
    ) {
        
        self.entryID = job.entryID
        self.entryJobID = job.jobTypeID
        self.entryStart = job.startTime
        self.entryEnd = job.endTime
        self.entryDesc = job.desc

    }
    
    init( // Preview
        jobTypeID : String,
        startTime : Date,
        endTime : Date,
        jobDesc : String
    ) {
        
        self.entryID = UUID()
        self.entryJobID = jobTypeID
        self.entryStart = startTime
        self.entryEnd = endTime
        self.entryDesc = jobDesc
    }
    
    var body: some View {
        VStack() {
            
            ZStack() {
                
                HStack() {
                    VStack(alignment: .leading) {
                                          
                        Text(getJobFromID(id: self.entryJobID).rawValue)
                            .fontWeight(.black)
                            .foregroundColor(
                                getJobColor(jobID: getJobFromID(id: self.entryJobID).rawValue)
                            )
                            .font(.headline)
                        
                        Text(self.entryStart.toDate())
                            .foregroundColor(.white)
                            .font(.subheadline)
                            .fontWeight(.bold)
                        
                        Text(
                            self.entryStart.getTimeText()
                            + " -> "
                            + self.entryStart.hrsOffset(relativeTo: self.entryEnd).toHrsString()
                        )
                            .foregroundColor(.white)
                            .font(.footnote)
                            .fontWeight(.bold)
                        
                    }
                    
                    Spacer()
                }
                

        
            }
            .padding()
            
        } // VStack
        .padding([.leading, .trailing], 3)
        .padding([.top, .bottom], 5)
        .background(
            GeometryReader { geometry in


                Rectangle()
                    .cornerRadius(16)
                    .foregroundColor(Color.init(hex: "0f0f0f"))
                    .transformEffect(.init(translationX: 5, y: 3))
                

                Rectangle()
                    .cornerRadius(15)
                    .foregroundColor(Color.init(hex: "1c1c1e"))

            }
        )
        
        .contentTransition(.numericText())
        
       
    }

}


#Preview {
    WatchJobEntryView(
        jobTypeID: getIDFromJob(type: .Manager),
        startTime: roundTime(time: Date()),
        endTime: roundTime(time: Date().addHours(hours: 1.5)),
        jobDesc: ""
    )
}

