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
    
    var somethingIsHighlighted : Bool { self.highlightedJob != nil }
    var isHighlighted : Bool {
        previewMode ? 
        false :
        self.highlightedJob == self.entryID
    }
    
    
    @State private var entryID : UUID?
    
    var entryJobID : String
    var entryStart : Date
    var entryEnd : Date
    var entryDesc : String
    
    private var previewMode : Bool
    private var miniPreviewMode : Bool
    
    @State private var isDetectingHold : Bool = false

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
        self.miniPreviewMode = false
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
        self.miniPreviewMode = false
    }
    
    init( // Preview
        jobTypeID : String,
        startTime : Date,
        endTime : Date,
        jobDesc : String,
        miniPreview: Bool
    ) {
        self._highlightedJob = .constant(nil)
        self._editJobBinding = .constant(nil)
        
        self.entryID = UUID()
        
        self.entryJobID = jobTypeID
        self.entryStart = startTime
        self.entryEnd = endTime
        self.entryDesc = jobDesc
    
        self.previewMode = true
        self.miniPreviewMode = true
    }
    
    var body: some View {
        VStack() {
            
            Button(action: {
                if (self.previewMode) {
                    return;
                }
                
                if (self.isHighlighted) {
                    self.highlightedJob = nil
                } else {
                    self.highlightedJob = self.entryID
                }
                
                RumbleSystem.shared.rumble()
            }) {
                
                ZStack() {
                    
                    HStack() {
                        VStack(alignment: .leading) {
                                              
                            Text(getJobFromID(id: self.entryJobID).rawValue)
                                .fontWeight(.black)
                                .foregroundColor(
                                    getJobColor(jobID: getJobFromID(id: self.entryJobID).rawValue)
                                )
                                .font(.title2)
                            
                            Text(self.entryStart.toDate())
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
                    }
                    
                    
                    
                    if (!self.miniPreviewMode) {
                        VStack {
                            
                            let totalTime: Double = self.entryStart.hrsOffset(relativeTo: self.entryEnd)
                            HStack() {
                                
                                Spacer()
                                
                                Text(totalTime.toHrsString())
                                .foregroundColor(.white)
                                .font(.title2)
                                .fontWeight(.black)
                                .monospaced()
                                
                            }
                            
                            if (self.isHighlighted) {
                                HStack() {
                                    
                                    Spacer()
                                    
                                    Text(
                                       getPayFromJob(id: self.entryJobID, hrs: totalTime).toMoneyString()
                                    )
                                    .foregroundColor(.gray)
                                    .font(.title2)
                                    .fontWeight(.black)
                                    .monospaced()
                                    
                                    
                                }
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        
                    }
                        
            
                }
                .padding(.bottom, self.isHighlighted ? 0 : -7)
                
            } // Button
            .padding()
            .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
                if (previewMode) {return}
                
                withAnimation {
                    self.isDetectingHold = pressing
                }
            }, perform: {
                // Optional: Perform an action on long press
            })
            
            VStack() {
                if (self.isHighlighted) {
                    Divider()
                    
                    VStack(alignment: .leading) {
                        
                        HStack() {
                            Text(self.entryDesc != "" ? "Job Description:" : "No Description:")
                                .font(.title2)
                                .fontWeight(.black)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button("", systemImage: "pencil") {
                                // Edit mode
                                self.editJobBinding = self.entryID
                            }
                            .fontWeight(.black)
                            .font(.title2)
                        }
                        
                        
                        ScrollView {
                            if (self.entryDesc != "") {
                                Text(self.entryDesc)
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .monospaced()
                                    .padding()
                                    .frame(minWidth: 300)
                            }
                        }
                        .background(Color.black.darkened(by: -0.05))
                        .cornerRadius(15)
                        .frame(maxHeight: 300)
                        
                        
                    }
                    .padding(0)
                    .transition(.opacity.combined(with: .scale(0.1, anchor: .top)))
                    .animation(.snappy(duration: 0.3), value: self.isHighlighted)
                    .clipped()
                    .padding(.bottom)
                } // Highlighted If Statement
            } // VStack
            .padding([.leading, .trailing])
            
        } // VStack
        .padding([.leading, .trailing])
        .padding([.top, .bottom], 5)
        .background(
            GeometryReader { geometry in

                if (!self.miniPreviewMode) {
                    Rectangle()
                        .cornerRadius(25)
                        .foregroundColor(Color.init(hex: "0f0f0f"))
                        .transformEffect(.init(translationX: 8, y: 5))
                }

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
        
        .animation(.bouncy, value: self.isDetectingHold)
        .animation(.snappy, value: self.isHighlighted)
        .contentTransition(.numericText())
        
        .padding([.top, .bottom], self.isDetectingHold ? 5 : 0)
        .scaleEffect(self.isDetectingHold ? 0.95 : 1)
        
        .draggable(self.render()!) {
            ListItemView(
                jobTypeID: self.entryJobID,
                startTime: self.entryStart,
                endTime: self.entryEnd,
                jobDesc: "",
                miniPreview: true
            )
        }
    }
    
    @MainActor func render() -> Image? {
 
        let renderer = ImageRenderer(
            content: ListItemView(
                        jobTypeID: self.entryJobID,
                        startTime: self.entryStart,
                        endTime: self.entryEnd,
                        jobDesc: "",
                        miniPreview: true
            ).body
        )

        renderer.scale = 8

        if let uiImage = renderer.uiImage {
            return Image(uiImage: uiImage)
        }
        
        return nil
   }
}


#Preview {
    PayPeriodView(
        period: getCurrentPayperiod()
    )
    .modelContainer(DataStorageSystem.shared.container)
    .modelContext(DataStorageSystem.shared.context)
//    
//    EmptyView()
}
