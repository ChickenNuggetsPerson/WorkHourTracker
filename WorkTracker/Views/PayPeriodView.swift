//
//  PayPeriodView.swift
//  WorkTracker
//
//  Created by Hayden Steele on 5/31/24.
//

import Foundation
import SwiftUI
import UIKit





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

    var totalHoursString : String {
        var total = 0.0
        for job in self.jobEntries {
            total += job.startTime?.hrsOffset(relativeTo: job.endTime ?? Date()) ?? 0
        }
        return String(total)
    }
    
    
    @State var highlightedJob : ObjectIdentifier? = nil
    
    @State private var showingDatesForm = false;
    @State private var showingNewEntryForm = false;
    @State private var showingInfoAlert = false;
    
    @State private var editJob : ObjectIdentifier? = nil
    @State private var showingEditEntryFrom = false;
   
    
    
    class ScrollProxyHolder: ObservableObject {
        @Published var proxy: ScrollViewProxy?
    }
    @StateObject private var scrollProxyHolder = ScrollProxyHolder()
    
    
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
            
            VStack() { // List
                ScrollViewReader { proxy in

                    ScrollView() {
                        
                        Color.black
                            .frame(height: 140)
                        
                        ForEach(
                            self.jobEntries
                        ) { i in
                            
                            ListItem(
                                job: i,
                                highlightedJob: $highlightedJob,
                                editJob: $editJob,
                                preview: false
                            )
                            .padding([.leading, .trailing], 10)
                            .id(i.id)
                            
                            
                        } // For Each
                        
                        
                        Color.black
                            .frame(height: 80)
                        
                        
                    } // Scroll View
                    .scrollContentBackground(.hidden)
                    
                    .onAppear {
                        scrollProxyHolder.proxy = proxy
                    }
                    
                    
                }
            }
            .animation(.bouncy, value: self.highlightedJob)
            
            VStack() { // Blurs
                
                Color.black
                    .opacity(self.refresh ? 0.5 : 0.500001)
                    .ignoresSafeArea(.all)
                    .background(.ultraThinMaterial)
                    .frame(
                        maxHeight: self.showingDatesForm ? 235 : 130
                    )
                    .overlay(
                        Rectangle()
                        .frame(width: nil, height: 5, alignment: .leading)
                        .foregroundColor(Color.init(red: 0.2, green: 0.2, blue: 0.2))
                        
                        , alignment: .bottom
                    )
                
                Spacer()
                
                Color.black
                    .opacity(0.5)
                    .ignoresSafeArea(.all)
                    .background(.ultraThinMaterial)
                    .frame(maxHeight: 80)
                    .overlay(
                        Rectangle()
                        .frame(width: nil, height: 5, alignment: .leading)
                        .foregroundColor(Color.init(red: 0.2, green: 0.2, blue: 0.2))
                        
                        , alignment: .top
                    )
                
            }
            
            VStack() { // Menus
                Button(self.titleText) {
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
                        self.shiftPayPeriod(forwards: false)
                        self.highlightedJob = nil
                    }
                    .foregroundColor(.yellow)
                    .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                    .fontWeight(.black)
                    
                    Spacer()
                    
                    Button(self.payPeriod.toString()) {
                        self.showingDatesForm.toggle()
                    }
                    .foregroundColor(self.showingDatesForm ? .cyan : .white)
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.01)
                        
                    
                    Spacer()
                    
                    Button(" ", systemImage: "arrow.right") {
                        self.shiftPayPeriod(forwards: true)
                        self.highlightedJob = nil
                    }
                    .foregroundColor(.yellow)
                    .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                    .fontWeight(.black)
                }
                .padding([.leading, .trailing], 30)
                
                Button(self.totalHoursString + " hrs") {
                    createAndSharePDF(
                        entries: self.jobEntries,
                        payperiod: self.payPeriod
                    )
                    
                }
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.orange)
            
                
                if (self.showingDatesForm) {
                    Divider()
                    VStack() {
                        DatePicker(selection: $payPeriod.startDate) {
                            Text("Start Time:")
                        }
                        
                        DatePicker(selection: $payPeriod.endDate, in: self.payPeriod.startDate...) {
                            Text("End Time:")
                        }
                    }
                    .padding([.trailing, .leading], 25)
                }
                
                
                Spacer()
                
                
                
                NavView(activePage: .PayPeriod)
                    .padding(.bottom, 0)

            }
            
            
            
            VStack() { // Add Button
                Spacer()
                HStack() {
                    Button("", systemImage: "info.circle") {
                        self.showingInfoAlert = true
                    }
                    .padding(20)
                    .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                    .fontWeight(.black)
                    Spacer()
                    Button("", systemImage: "plus") {
                        self.showingNewEntryForm = true
                    }
                    .padding(20)
                    .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                    .fontWeight(.black)
                }
            }
            
            
            
            if (self.showingNewEntryForm) { // add form
                JobEntryForm(
                    showingForm: $showingNewEntryForm
                )
            }
            if (self.editJob != nil) { // edit form
                JobEntryForm(
                    showingForm: $showingEditEntryFrom,
                    job: jobEntries.first { $0.id == self.editJob }!,
                    editJobId: $editJob
                )
            }
            

        }
        .animation(.bouncy(), value: self.showingDatesForm)
        .animation(.bouncy(extraBounce: 0.1), value: self.payPeriod)
        .animation(.bouncy(), value: self.editJob)
        .animation(.bouncy(), value: self.showingNewEntryForm)
        
        .alert(isPresented: $showingInfoAlert) {
            Alert(
                title: Text(self.payPeriod.toString() + " Info"),
                message: Text(self.getInfoTxt()),
                dismissButton: .default(Text("OK"))
            )
        }
        
        .onChange(of: self.highlightedJob) {
            scrollTo(id: self.highlightedJob)
        }
        
    }
    

    func scrollTo(id: ObjectIdentifier?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
            withAnimation(.easeInOut) {
                scrollProxyHolder.proxy!.scrollTo(id, anchor: .init(x: 0.5, y: 0.5))
            }
        }
    }
    
    func shiftPayPeriod(forwards: Bool) {
        if (forwards) {
            
            self.payPeriod.endDate = self.payPeriod.endDate.addDays(days: 14)
            self.payPeriod.startDate = self.payPeriod.startDate.addDays(days: 14)
            
        } else {
            
            self.payPeriod.startDate = self.payPeriod.startDate.addDays(days: -14)
            self.payPeriod.endDate = self.payPeriod.endDate.addDays(days: -14)
        }
    
    }
    
    private func getInfoTxt() -> String {
        var totalPay = 0.0
        var totalHours = 0.0
        
        let entries = self.jobEntries
        for entry in entries {
            let hrs = entry.startTime?.hrsOffset(relativeTo: entry.endTime ?? Date()) ?? 0
            
            totalHours += hrs
            totalPay += getPayFromJob(
                id: entry.jobID ?? "",
                hrs: hrs
            )
        }
        
        
        return String(totalHours) + " hrs\n$" + String(floor(totalPay * 0.88))
    }

}







struct JobEntryForm: View {
    
    @Binding var showingForm : Bool
    @Binding var editJobID : ObjectIdentifier?
    
    @State var highlightedJob : ObjectIdentifier? = nil
    
    @State private var newEntryJobID : String
    @State private var newEntryStart : Date
    @State private var newEntryEnd : Date
    @State private var newEntryDesc : String
    
    private var newForm : Bool
    private var job : JobEntry?
    
    var validEntry : Bool {
        (self.newEntryStart != self.newEntryEnd) && (self.newEntryJobID != "")
    }
    
    
    init (
        showingForm : Binding<Bool>
    ) {
        self.newForm = true
        self.job = nil
        self._showingForm = showingForm
        self._editJobID = Binding<ObjectIdentifier?>(get: { nil }, set: { _ in })
        
        self.newEntryJobID = ""
        self.newEntryStart = roundTime(time: Date())
        self.newEntryEnd = roundTime(time: Date())
        self.newEntryDesc = ""
    }
    init (
        showingForm : Binding<Bool>,
        job : JobEntry,
        editJobId : Binding<ObjectIdentifier?>
    ) {
        self.newForm = false
        self.job = job
        self._showingForm = showingForm
        self._editJobID = editJobId
        
        self.newEntryJobID = job.jobID ?? ""
        self.newEntryStart = job.startTime ?? Date()
        self.newEntryEnd = job.endTime ?? Date()
        self.newEntryDesc = job.desc ?? ""
    }
    
    
    var body: some View {
        VStack() {
            Form {
                
                ListItem(
                    jobTypeID: self.newEntryJobID,
                    startTime: self.newEntryStart,
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
                        return (e != JobTypes.undef) && (e != JobTypes.IT)
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
                    .onChange(of: newEntryStart) {
                        self.newEntryEnd = self.newEntryStart
                    }
                    
                    DatePicker(selection: $newEntryEnd, in: self.newEntryStart...) {
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
       
    }
    
    private func addJob() {
        CoreDataManager.shared.createJobEntry(
            desc: self.newEntryDesc,
            jobID: self.newEntryJobID,
            startTime: roundTime(time: self.newEntryStart),
            endTime: roundTime(time: self.newEntryEnd)
        )
        self.closeForm()
    }
    private func updateJob() {
        CoreDataManager.shared.updateJobEntry(
            jobEntry: self.job!,
            desc: self.newEntryDesc,
            jobID: self.newEntryJobID,
            startTime: self.newEntryStart,
            endTime: self.newEntryEnd
        )
        self.closeForm()
    }
    private func deleteJob() {
        CoreDataManager.shared.deleteJobEntry(jobEntry: self.job!)
        highlightedJob = nil
        self.closeForm()
    }

   
}




struct ListItem: View {
    
    @Binding var highlightedJob : ObjectIdentifier?
    @Binding var editJobBinding : ObjectIdentifier?
    
    var somethingIsHighlighted : Bool { self.highlightedJob != nil }
    var isHighlighted : Bool { self.highlightedJob == self.entryID }
    
    @State private var entryID : ObjectIdentifier?
    
    private var entryJobID : String
    private var entryStart : Date
    private var entryEnd : Date
    private var entryDesc : String
    
    private var previewMode : Bool

    init( // Main List
        job: JobEntry,
        highlightedJob: Binding<ObjectIdentifier?>,
        editJob: Binding<ObjectIdentifier?>,
        preview: Bool
    ) {
    
        self._highlightedJob = highlightedJob
        self._editJobBinding = editJob
        
        self.entryID = job.id
        self.entryJobID = job.jobID ?? ""
        self.entryStart = job.startTime ?? Date()
        self.entryEnd = job.endTime ?? Date()
        self.entryDesc = job.desc ?? ""

        self.previewMode = preview
    }
    
    init( // Preview
        jobTypeID : String,
        startTime : Date,
        endTime : Date,
        jobDesc : String,
        highlightedJob: Binding<ObjectIdentifier?>,
        preview: Bool
    ) {
        self._highlightedJob = highlightedJob
        self._editJobBinding = highlightedJob
        
        self.entryID = ObjectIdentifier(EmptyClass())
        
        self.entryJobID = jobTypeID
        self.entryStart = startTime
        self.entryEnd = endTime
        self.entryDesc = jobDesc
    
        self.previewMode = preview
    }
    
    
    var body: some View {
        HStack() {
            
            Button(action: {
                if (self.previewMode) { return; }
                
                if (self.isHighlighted) {
                    self.highlightedJob = nil
                } else {
                    self.highlightedJob = self.entryID
                }
            }) {
                
                VStack(alignment: .leading) {
                    
                    
                    HStack() {
                        
                        VStack(alignment: .leading) {
                            let color = getJobColor(running: true, jobID: getJobFromID(id: self.entryJobID).rawValue)
                            
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
    }
}







#Preview {
    let context = CoreDataManager.shared.context
//    CoreDataManager.shared.populateSampleData()
    return PayPeriodView(
        period: getCurrentPayperiod()
    ).environment(\.managedObjectContext, context)
}
