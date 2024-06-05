//
//  PayPeriodView.swift
//  WorkTracker
//
//  Created by Hayden Steele on 5/31/24.
//

import Foundation
import SwiftUI
import UIKit


private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
}()




struct PayPeriodView: View {
    
    @Environment(\.managedObjectContext) private var viewContext

    @State var refresh: Bool = false
    
    private var currentPayPeriod : PayPeriod = getCurrentPayperiod()
    
    @State var payPeriod : PayPeriod
    @State var titleText: String
    @State var titleColor: Color
    
    var jobEntries: [JobEntry] {
        CoreDataManager.shared.fetchJobEntries(
            dateRange: self.payPeriod.getRange()).sorted { $0.startTime ?? Date() < $1.startTime ?? Date() }
    }
    var sortedJobEntries: [[JobEntry]] {
        return self.jobEntries.sortByDay()
    }

    var totalHoursString : String {
        var total = 0.0
        for job in self.jobEntries {
            total += job.startTime?.hrsOffset(relativeTo: job.endTime ?? Date()) ?? 0
        }
        return String(total)
    }
    
    
    
    @State var highlightedJob : ObjectIdentifier? = nil
    @State var editingJob : JobEntry? = nil
    var isEditing : Bool { self.editingJob != nil }
    
    @State var isShowingShareSheet : Bool = false;
    @State private var jsonData: String = ""
    
    
    @State private var showingDatesForm = false;
    
    @State private var showingNewEntryForm = false;
    @State private var newEntryJobID : String = ""
    @State private var newEntryStart : Date = roundTime(time: Date())
    @State private var newEntryEnd : Date = roundTime(time: Date())
    @State private var newEntryDesc : String = ""
   
    var validEntry : Bool {
        (self.newEntryStart != self.newEntryEnd) && (self.newEntryJobID != "")
    }
    
    
    init(
        period : PayPeriod = getCurrentPayperiod(),
        title: String = "Pay Period:",
        color: Color = Color.green
    ) {
        
        self.payPeriod = period
        self.titleText = title
        self.titleColor = color

    }

    
    
    var body: some View {
        
        ZStack() {
        
            Color.black.ignoresSafeArea(.all)
            
            if (self.showingDatesForm) { // Dates from
                Form {
                    Section("Choose Time Range:") {
                        DatePicker(selection: $payPeriod.startDate) {
                            Text("Start Time:")
                        }
                        
                        DatePicker(selection: $payPeriod.endDate, in: self.payPeriod.startDate...) {
                            Text("End Time:")
                        }
                    }
                    
                }
                .padding(.top, 150)
            } else {
                VStack() { // List
                    ScrollView() {

                        Color.black
                            .frame(height: 140)
                        
//                        let arr = self.sortedJobEntries
                    
                        ForEach(
                            self.jobEntries
                        ) { i in
                        
                            ListItem(
                                job: i,
                                highlightedJob: $highlightedJob,
                                editingJob: $editingJob
                            )

                            
                        } // For Each
                        .onDelete(perform: deleteJob)
    
                        
                    } // Scroll View
                    .scrollContentBackground(.hidden)
                    .listRowSpacing(10)
                    .padding(.bottom, 70)
                }
                .animation(.bouncy, value: self.highlightedJob)
            }
            
            
            
            VStack() { // Blurs
                
                Color.black
                    .opacity(self.refresh ? 0.5 : 0.500001)
                    .ignoresSafeArea(.all)
                    .background(.ultraThinMaterial)
                    .frame(maxHeight: 130)
//                    .padding(.top,
//                             self.isEditing ? -100 : 0
//                    )
                
                Spacer()
                
                Color.black
                    .opacity(0.5)
                    .ignoresSafeArea(.all)
                    .background(.ultraThinMaterial)
                    .frame(maxHeight: 80)
                
            }
            
            
            VStack() { // Menus
                Button(self.titleText) {
                    if (self.isEditing) { return }
                    withAnimation {
                        self.payPeriod = getCurrentPayperiod()
                    }
                }
                .foregroundColor(
                    self.currentPayPeriod == self.payPeriod ? self.titleColor : .gray
                )
                .font(.largeTitle)
                .fontWeight(.black)
            
                    
                HStack() {
                    Button(" ", systemImage: "arrow.left") {
                        if (self.isEditing) { return }
                        withAnimation {
                            self.shiftPayPeriod(forwards: false)
                        }
                    }
                    .foregroundColor(.yellow)
                    .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                    .fontWeight(.black)
                    
                    Spacer()
                    
                    Button(self.payPeriod.toString()) {
                        if (self.isEditing) { return }
                        withAnimation {
                            self.showingDatesForm.toggle()
                        }
                    }
                    .foregroundColor(self.showingDatesForm ? .cyan : .white)
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.01)
                        
                    
                    Spacer()
                    
                    Button(" ", systemImage: "arrow.right") {
                        if (self.isEditing) { return }
                        withAnimation {
                            self.shiftPayPeriod(forwards: true)
                        }
                    }
                    .foregroundColor(.yellow)
                    .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                    .fontWeight(.black)
                }
                .padding([.leading, .trailing], 30)
                
                Button(self.totalHoursString + " hrs") {
                    if (self.isEditing) { return }
                    createAndSharePDF(
                        entries: self.jobEntries,
                        payperiod: self.payPeriod
                    )
                    
                }
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.orange)
            
                
                
                Spacer()
                
                
                
                NavView(activePage: .PayPeriod)
                    .padding(.bottom, 0)

            }
            
            
            
            VStack() { // Add Button
                Spacer()
                HStack() {
                    Spacer()
                    Button("", systemImage: "plus") {
                        if (self.isEditing) { return }
                        self.showingNewEntryForm = true
                    }
                    .padding(20)
                    .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                    .fontWeight(.black)
                }
            }
            
            
            
            if (self.showingNewEntryForm) {
                VStack() {
                    Form {
                        
                        JobView(
                            jobID: self.newEntryJobID,
                            startTime: roundTime(time: self.newEntryStart),
                            endTime: roundTime(time: self.newEntryEnd)
                        )
                        
                        Section() {
                            
                            Button(action: {
                                self.addJob()
                            }) {
                                Text("Submit")
                                    .font(.title3)
                                    .fontWeight(.black)
                                    .foregroundColor(self.validEntry ? Color.blue : Color.gray)
                                    .animation(.easeInOut, value: self.validEntry)
                            }
                            .disabled(!self.validEntry)
                            
                            Button(action: {
                                self.resetNewJob()
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
                                return e != JobTypes.undef
                            }, id: \.self) { jobType in
                                
                                Text(jobType.rawValue)
                                    .tag(getIDFromJob(type: jobType))
        
                            }
                        }
                        .pickerStyle(.inline)
                        
                        
                        Section("Time:") {
                            DatePicker(selection: $newEntryStart) {
                                Text("Start Time:")
                            }
                            .onChange(of: newEntryStart) {
                                self.newEntryEnd = self.newEntryStart
                            }
                            
                            DatePicker(selection: $newEntryEnd, in: self.newEntryStart...) {
                                Text("End Time:")
                            }
                        }
                        
                        Section("Description:") {
                            TextEditor(text: $newEntryDesc)
                        }
                    }
                }
                .animation(.bouncy, value: self.showingNewEntryForm)
            }

            
            
        }
        .animation(.bouncy(), value: self.showingDatesForm)
        
    }
    
    
    
    
    private func resetNewJob() {
        self.newEntryJobID = ""
        self.newEntryStart = roundTime(time: Date())
        self.newEntryEnd = roundTime(time: Date())
        self.newEntryDesc = ""
        
        self.showingNewEntryForm = false;
    }
    
    private func addJob() {
        CoreDataManager.shared.createJobEntry(
            desc: self.newEntryDesc,
            jobID: self.newEntryJobID,
            startTime: roundTime(time: self.newEntryStart),
            endTime: roundTime(time: self.newEntryEnd)
        )
        self.resetNewJob()
        self.refresh.toggle()
   }

   private func deleteJob(at offsets: IndexSet) {
       
       for index in offsets {

           let job = self.jobEntries[index]
           
           CoreDataManager.shared.deleteJobEntry(jobEntry: job)
           self.refresh.toggle()
       }
           
   }
    
    
    func shiftPayPeriod(forwards: Bool) {
        if (forwards) {
            
            self.payPeriod.startDate = self.payPeriod.startDate.addDays(days: 14)
            self.payPeriod.endDate = self.payPeriod.endDate.addDays(days: 14)
            
        } else {
            
            self.payPeriod.startDate = self.payPeriod.startDate.addDays(days: -14)
            self.payPeriod.endDate = self.payPeriod.endDate.addDays(days: -14)
            
        }
    
    }
}




struct JobView : View {

    var jobID : String
    var startTime : Date
    var endTime : Date
    
    var body: some View {
        
        
        HStack() {
            
            VStack(alignment: .leading) {
                let color = getJobColor(running: true, jobID: getJobFromID(id: self.jobID).rawValue)
                
                Text(getJobFromID(id: self.jobID).rawValue)
                    .fontWeight(.black)
                    .foregroundColor(color)
                    .font(.title2)
                
                Text(self.startTime, style: .date)
                    .foregroundColor(.white)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("\(self.startTime, formatter: itemFormatter) - \(self.endTime, formatter: itemFormatter)")
                    .foregroundColor(.white)
                    .font(.title3)
                    .fontWeight(.bold)
                
            }
            
            Spacer()
            
            VStack() {
                
                let num = self.startTime.hrsOffset(relativeTo: self.endTime)
                
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
        
        
    }

}







struct ListItem: View {
    
    var job : JobEntry

    @Binding var highlightedJob : ObjectIdentifier?
    @Binding var editingJob : JobEntry?
    
    var isHighlighted : Bool { self.highlightedJob == self.job.id }
    var isEditing : Bool { self.editingJob != nil }
    
    
    @State private var editEntryJobID : String
    @State private var editEntryStart : Date
    @State private var editEntryEnd : Date
    @State private var editEntryDesc : String
    
    init(job: JobEntry, highlightedJob: Binding<ObjectIdentifier?>, editingJob: Binding<JobEntry?>) {
        self.job = job
        
        self._highlightedJob = highlightedJob
        self._editingJob = editingJob
        
        self.editEntryJobID = job.jobID ?? ""
        self.editEntryStart = job.startTime ?? Date()
        self.editEntryEnd = job.endTime ?? Date()
        self.editEntryDesc = job.desc ?? ""
    }
    
    var body: some View {
        HStack() {
            
            Button(action: {
                
                if (self.isEditing) { return }
                
                if (self.isHighlighted) {
                    self.highlightedJob = nil
                } else {
                    self.highlightedJob = self.job.id
                }
            }) {
                
                VStack(alignment: .leading) {
                    
                    JobView(
                        jobID: job.jobID ?? "",
                        startTime: job.startTime ?? Date(),
                        endTime: job.endTime ?? Date()
                    )
                    
                    if (self.isHighlighted) {
                        VStack(alignment: .leading) {
                            Divider()
                            
                            HStack() {
                                Text("Job Description:")
                                    .font(.title2)
                                    .fontWeight(.black)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                if (self.isEditing) {
                                    
                                    Button("X") {
                                        self.highlightedJob = self.job.id
                                        self.editingJob = nil
                                    }
                                    .foregroundColor(.red)
                                    .fontWeight(.black)
                                    .font(.title2)
                                    .padding(.trailing, 10)
                                    
                                    Button("", systemImage: "checkmark") {
                                        
                                        // Save
                                        self.highlightedJob = self.job.id
                                        self.editingJob = nil
                                        
                                    }
                                    .foregroundColor(.green)
                                    .fontWeight(.black)
                                    .font(.title2)
                                    
                                } else {
                                    Button("", systemImage: "pencil") {
                                        self.editingJob = self.job
                                    }
                                    .fontWeight(.black)
                                    .font(.title2)
                                }
                            }
                            
                            
                            HStack() {
                                Text(job.desc ?? "")
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .monospaced()
                                    .disabled(!isEditing)
                            }
                        }
                    }
                } // VStack
                
            } // Button
            .padding()
            
        } // HStack
        .background(Color.init(red: 0.1, green: 0.1, blue: 0.1))
        .padding([.leading, .trailing])
        .padding(.bottom, 5)
        .opacity(
            !self.isEditing ? 1 : ( self.isHighlighted ? 1 : 0.4 )
        )
        .blur(
            radius: !self.isEditing ? 0 : ( self.isHighlighted ? 0 : 5 )
        )
        .animation(.easeInOut, value: self.isEditing)
    }
}







#Preview {
    let context = CoreDataManager.shared.context
//    CoreDataManager.shared.populateSampleData()
    return PayPeriodView(
        period: getCurrentPayperiod()
    ).environment(\.managedObjectContext, context)
}
