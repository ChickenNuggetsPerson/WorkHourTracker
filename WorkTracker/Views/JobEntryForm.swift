//
//  JobEntryForm.swift
//  WorkTracker
//
//  Created by Hayden Steele on 6/24/24.
//

import Foundation
import SwiftUI

struct JobEntryForm: View {
    
    @Environment(\.modelContext) var modelContext
    
    @Binding var showingForm : Bool
    @Binding var editJobID : UUID?
    @Binding var actualHighlightID : UUID?
    
    @Binding var highlightDate : Date?
    
    @State var highlightedJob : UUID? = nil
    
    @State private var newEntryJobID : String
    @State private var newEntryStart : Date
    @State private var newEntryEnd : Date
    @State private var newEntryDesc : String
    
    private var newForm : Bool
    
    @State private var job: JobEntry?
    
    var validEntry : Bool {
        (self.newEntryStart != self.newEntryEnd) && (self.newEntryJobID != "")
    }
    
    
    init (
        showingForm : Binding<Bool>,
        hightlightJob : Binding<UUID?>,
        showDate : Binding<Date?>
    ) {
        self.newForm = true
        self.job = nil
        self._showingForm = showingForm
        self._editJobID = .constant(nil)
        self._actualHighlightID = hightlightJob
        self._highlightDate = showDate
        
        self.newEntryJobID = ""
        self.newEntryStart = roundTime(time: Date())
        self.newEntryEnd = roundTime(time: Date())
        self.newEntryDesc = ""
    }
    init (
        showingForm : Binding<Bool>,
        job : JobEntry,
        editJobId : Binding<UUID?>,
        hightlightJob : Binding<UUID?>,
        showDate : Binding<Date?>
    ) {
        self.newForm = false
        self.job = job
        self._showingForm = showingForm
        self._editJobID = editJobId
        self._actualHighlightID = hightlightJob
        self._highlightDate = showDate
        
        self.newEntryJobID = job.jobTypeID
        self.newEntryStart = job.startTime
        self.newEntryEnd = job.endTime
        self.newEntryDesc = job.desc
    }
    
    
    var body: some View {
        VStack() {
            Form {
                
                JobEntryView(
                    jobTypeID: self.newEntryJobID,
                    startTime: roundTime(time: self.newEntryStart),
                    endTime: roundTime(time: self.newEntryEnd),
                    jobDesc: self.newEntryDesc,
                    highlightedJob: $highlightedJob,
                    preview: true
                )
                .padding([.leading, .trailing], -30)
                .padding([.top, .bottom], -10)

                Section() {
                    
                    Button(action: {
                        if (self.newForm) {
                            self.addJob()
                        } else {
                            self.updateJob()
                        }
                    }) {
                        Text(self.newForm ? "Create" : "Edit")
                            .font(.title3)
                            .fontWeight(.black)
                            .foregroundColor(
                                self.validEntry ?
                                (self.newForm ? Color.blue : Color.orange)
                                : Color.gray
                            )
                            .animation(.easeInOut, value: self.validEntry)
                    }
                    .disabled(!self.validEntry)
                    
                    Button(action: {
                        self.closeForm()
                    }) {
                        Text("Close")
                            .font(.title3)
                            .fontWeight(.black)
                            .foregroundColor(Color.red)
                    }
                    
                }
                .frame(alignment: .center)
                .padding(0)
        
                Picker("Job Type:", selection: $newEntryJobID) {
                    ForEach(JobTypes.allCases.filter { e in
                        return (e != JobTypes.undef)
                    }, id: \.self) { jobType in
                        
                        Text(jobType.rawValue)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .tag(getIDFromJob(type: jobType))

                    }
                }
                .pickerStyle(.inline)
                
                
                Section("Time:") {
                    DatePicker(selection: $newEntryStart) {
                        Text("Start:")
                    }
                    .onChange(of: self.newEntryStart) { old, new in
                        
                        let newDiff = abs(old.hrsOffset(relativeTo: new))
                        if (newDiff > 12) {
                        
                            let offset : Double = old.hrsOffset(relativeTo: self.newEntryEnd)
                            self.newEntryEnd = new.addHours(hours: offset)
                        }
                    }
                    
                    DatePicker(
                        selection: $newEntryEnd,
                        in: self.newEntryStart...self.newEntryStart.addHours(hours: 23)
                    ) {
                        Text("End:")
                    }
                }
                
                Section("Description:") {
                    TextEditor(text: $newEntryDesc)
                }
                
                if (!self.newForm) {
                    Section("Delete:") {
                        Button(action: {
                            self.deleteJob()
                        }) {
                            Text("Delete Job")
                                .font(.title3)
                                .fontWeight(.black)
                                .foregroundColor(Color.red)
                        }
                    }
                }
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        
        .animation(.bouncy, value: self.newEntryJobID)
        .animation(.bouncy, value: self.newEntryStart)
        .animation(.bouncy, value: self.newEntryEnd)
        .animation(.bouncy, value: self.newEntryDesc)
    }
    
    private func closeForm() {
        
        withAnimation {
            if (!self.newForm) {
                self.editJobID = nil
            } else {
                self.showingForm = false;
            }
        }
        
        // Hide Keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
       
    }
    
    private func addJob() {
        
        var jobID : UUID?
        withAnimation {
            jobID = DataStorageSystem.shared.createEntry(
                jobTypeID: self.newEntryJobID,
                startTime: roundTime(time: self.newEntryStart),
                endTime: roundTime(time: self.newEntryEnd),
                desc: self.newEntryDesc,
                undoable: true
            )
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            actualHighlightID = jobID
            highlightDate = roundTime(time: self.newEntryStart)
        }
        
        self.closeForm()
    }
    private func updateJob() {

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                DataStorageSystem.shared.updateEntry(
                    entry: self.job!,
                    jobTypeID: self.newEntryJobID,
                    startTime: roundTime(time: self.newEntryStart),
                    endTime: roundTime(time: self.newEntryEnd),
                    desc: self.newEntryDesc
                )
            }
            
            highlightDate = roundTime(time: self.newEntryStart)
        }
        
        self.closeForm()
    }
    private func deleteJob() {
        
        highlightedJob = nil
        editJobID = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            DataStorageSystem.shared.deleteEntry(entry: self.job!)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            actualHighlightID = nil
        }
        
        self.closeForm()
    }

   
}


#Preview() {
    
    JobEntryForm(
        showingForm: .constant(true),
        hightlightJob: .constant(nil),
        showDate: .constant(nil)
    )
}
