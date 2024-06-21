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
    @State private var showingExportAlert = false;
    
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
                        
                        Color.black.frame(height: 140)
                        
                        ForEach(
                            self.jobEntries
                        ) { i in
                            
                            ListItemView(
                                job: i,
                                highlightedJob: $highlightedJob,
                                editJob: $editJob,
                                preview: false
                            )
                            .padding([.leading, .trailing], 10)
                            .id(i.id)
                            
                        } // For Each
                        
                        
                        Color.black.frame(height: 80)
                        
                        
                    } // Scroll View
                    .scrollContentBackground(.hidden)
                    .onAppear {
                        scrollProxyHolder.proxy = proxy
                    }
                }
            }
            .animation(.bouncy, value: self.highlightedJob)
            .contentTransition(.opacity)
            
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
                    self.payPeriod = getCurrentPayperiod()
                    self.highlightedJob = nil
                }
                .foregroundColor(
                    self.currentPayPeriod == self.payPeriod ? self.titleColor : .gray
                )
                .font(.largeTitle)
                .fontWeight(.black)
            
                    
                HStack() {
                    Button("", systemImage: "arrow.left") {
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
                    .monospaced()
                    
                    Spacer()
                    
                    Button("", systemImage: "arrow.right") {
                        self.shiftPayPeriod(forwards: true)
                        self.highlightedJob = nil
                    }
                    .foregroundColor(.yellow)
                    .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                    .fontWeight(.black)
                }
                .padding([.leading, .trailing], 25)
                
                Button(self.totalHoursString + " hrs") {
                    self.showingExportAlert = true;
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
        .contentTransition(.numericText())
        
        .alert(isPresented: $showingInfoAlert) {
            Alert(
                title: Text(self.payPeriod.toString() + " Info"),
                message: Text(self.getInfoTxt()),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert("Export Timecard:", isPresented: $showingExportAlert) {
            Button("With Descriptions", role: .none) {
                createAndSharePDF(
                    entries: self.jobEntries,
                    payperiod: self.payPeriod,
                    showingDesc: true
                )
            }
            Button("Without Descriptions", role: .none) {
                createAndSharePDF(
                    entries: self.jobEntries,
                    payperiod: self.payPeriod,
                    showingDesc: false
                )
            }
            Button("Cancel", role: .cancel) { }
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
            let hrs = entry.startTime?.hrsOffset(relativeTo: entry.endTime ?? Date()) ?? 0.0

            totalHours += hrs
            totalPay += getPayFromJob(
                id: entry.jobID ?? "",
                hrs: hrs
            )
        }
        
        var infoTXT = String(totalHours) + " hrs\n$" + String(floor(totalPay * 0.88)) + "\n"
        
        infoTXT += entries.getHoursTotals().toText()
        
        return infoTXT
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
                
                ListItemView(
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











#Preview {
    let context = CoreDataManager.shared.context
//    CoreDataManager.shared.populateSampleData()
    return PayPeriodView(
        period: getCurrentPayperiod()
    ).environment(\.managedObjectContext, context)
}
