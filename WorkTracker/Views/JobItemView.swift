//
//  JobItemView.swift
//  WorkTracker
//
//  Created by Hayden Steele on 6/20/24.
//

import Foundation
import SwiftUI

struct ListItemView: View {
    
    @Binding var highlightedJob : UUID?
    @Binding var editJobBinding : UUID?
    
    @State var previewHighlightToggle : Bool = false;
    var somethingIsHighlighted : Bool { self.highlightedJob != nil }
    var isHighlighted : Bool {
        previewMode ? 
        previewHighlightToggle :
        self.highlightedJob == self.entryID
    }
    
    
    @State private var entryID : UUID?
    
    private var entryJobID : String
    private var entryStart : Date
    private var entryEnd : Date
    private var entryDesc : String
    
    private var previewMode : Bool

    init( // Main List
        job: JobEntry,
        highlightedJob: Binding<UUID?>,
        editJob: Binding<UUID?>,
        preview: Bool
    ) {
    
        self._highlightedJob = highlightedJob
        self._editJobBinding = editJob
        
        self.entryID = job.entryID
        self.entryJobID = job.jobTypeID
        self.entryStart = job.startTime
        self.entryEnd = job.endTime
        self.entryDesc = job.desc

        self.previewMode = preview
    }
    
    init( // Preview
        jobTypeID : String,
        startTime : Date,
        endTime : Date,
        jobDesc : String,
        highlightedJob: Binding<UUID?>,
        preview: Bool
    ) {
        self._highlightedJob = highlightedJob
        self._editJobBinding = highlightedJob
        
        self.entryID = UUID()
        
        self.entryJobID = jobTypeID
        self.entryStart = startTime
        self.entryEnd = endTime
        self.entryDesc = jobDesc
    
        self.previewMode = preview
    }
    
    
    var body: some View {
        HStack() {
            
            Button(action: {
                if (self.previewMode) {
                    
                    self.previewHighlightToggle.toggle()
                    
                    return;
                }
                
                if (self.isHighlighted) {
                    self.highlightedJob = nil
                } else {
                    self.highlightedJob = self.entryID
                }
                
                RumbleSystem.shared.rumble()
            }) {
                
                VStack(alignment: .leading) {
                    
                    
                    HStack() {
                        
                        VStack(alignment: .leading) {
                            let color = getJobColor(jobID: getJobFromID(id: self.entryJobID).rawValue)
                            
                            Text(getJobFromID(id: self.entryJobID).rawValue)
                                .fontWeight(.black)
                                .foregroundColor(color)
                                .font(.title2)
                            
                            Text(self.entryStart, style: .date)
                                .foregroundColor(.white)
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Text(
                                self.entryStart.getTimeText()
                                + " - "
                                + self.entryEnd.getTimeText()
                            )
                                .foregroundColor(.white)
                                .font(.title3)
                                .fontWeight(.bold)
                            
                        }
                        
                        Spacer()
                        
                        VStack() {
                            
                            let num = self.entryStart.hrsOffset(relativeTo: self.entryEnd)
                            
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
                    
                    
                    
                    if (self.isHighlighted) {
                        VStack(alignment: .leading) {
                            Divider()
                            
                            HStack() {
                                Text("Job Description:")
                                    .font(.title2)
                                    .fontWeight(.black)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                if (!self.previewMode) {
                                    Button("", systemImage: "pencil") {
                                        // Edit mode
                                        
                                        self.editJobBinding = self.entryID
                                        
                                    }
                                    .fontWeight(.black)
                                    .font(.title2)
                                }
                            }
                            
                            
                            HStack() {
                                Text(self.entryDesc)
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .monospaced()
                            }
                        }
                    }
                } // VStack
                
            } // Button
            .padding()
            
        } // HStack
        .padding([.leading, .trailing])
        .padding([.top, .bottom], 5)
        .background(
            GeometryReader { geometry in
                Rectangle()
                .cornerRadius(25)
                .foregroundColor(Color.init(hex: "1c1c1e"))
            }
        )
        .opacity(
            self.previewMode ? 1 : (!self.somethingIsHighlighted ? 1 : (self.isHighlighted ? 1 : 0.4))
        )
        .blur(
            radius: self.previewMode ? 0 : (!self.somethingIsHighlighted ? 0 : (self.isHighlighted ? 0 : 4))
        )
        .animation(.bouncy, value: self.previewHighlightToggle)
        .contentTransition(.numericText())
    }
}




#Preview {
    ListItemView(
        jobTypeID: getIDFromJob(type: .Manager),
        startTime: Date().addHours(hours: -1).addMinutes(minutes: -15),
        endTime: Date(),
        jobDesc: "- Super Cool Job",
        highlightedJob: Binding<UUID?>(get: { nil }, set: { _ in }),
        preview: true
    )
}
