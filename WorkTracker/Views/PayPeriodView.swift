//
//  PayPeriodView.swift
//  WorkTracker
//
//  Created by Hayden Steele on 5/31/24.
//

import Foundation
import SwiftUI
import UIKit
import SwiftData


struct PayPeriodView: View {
    
    @Environment(\.modelContext) var modelContext

    @State var refresh: Bool = false
    
    @State var payPeriod : PayPeriod
    @State var titleText: String
    @State var titleColor: Color
    
    var jobEntries: [JobEntry] {
        DataStorageSystem.shared.fetchJobEntries(dateRange: payPeriod.range)
    }

    var totalHoursString : String {
        var total = 0.0
        for job in self.jobEntries {
            total += job.startTime.hrsOffset(relativeTo: job.endTime)
        }
        return String(total)
    }
    
    
    @State var highlightedJob : UUID? = nil
    
    @State private var showingDatesForm = false;
    @State private var showingNewEntryForm = false;
    @State private var showingInfoAlert = false;
    @State private var showingExportAlert = false;
    
    @State private var editJob : UUID? = nil
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
                        ) { entry in
                            
                            ListItemView(
                                job: entry,
                                highlightedJob: $highlightedJob,
                                editJob: $editJob,
                                preview: false
                            )
                            .padding([.leading, .trailing], 10)
                            .id(entry.entryID)
                            
                        } // For Each
                        .onDelete(perform: { indexSet in
                            
                        })
                        
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
                    RumbleSystem.shared.rumble()
                }
                .foregroundColor(
                    self.payPeriod.isCurrent ? self.titleColor : .gray
                )
                .font(.largeTitle)
                .fontWeight(.black)
            
                    
                HStack() {
                    Button("", systemImage: "arrow.left") {
                        self.shiftPayPeriod(forwards: false)
                        self.highlightedJob = nil
                        RumbleSystem.shared.rumble()
                    }
                    .foregroundColor(.yellow)
                    .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                    .fontWeight(.black)
                    
                    Spacer()
                    
                    Button(self.payPeriod.toString()) {
                        self.showingDatesForm.toggle()
                        RumbleSystem.shared.rumble()
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
                        RumbleSystem.shared.rumble()
                    }
                    .foregroundColor(.yellow)
                    .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                    .fontWeight(.black)
                }
                .padding([.leading, .trailing], 25)
                
                Button(self.totalHoursString + " hrs") {
                    self.showingExportAlert = true;
                    RumbleSystem.shared.rumble()
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
                        RumbleSystem.shared.rumble()
                    }
                    .padding(20)
                    .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                    .fontWeight(.black)
                    Spacer()
                    Button("", systemImage: "plus") {
                        self.showingNewEntryForm = true
                        RumbleSystem.shared.rumble()
                    }
                    .padding(20)
                    .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                    .fontWeight(.black)
                }
            }
            
            
            
            VStack() {
                if (self.showingNewEntryForm) { // add form
                    JobEntryForm(
                        showingForm: $showingNewEntryForm,
                        hightlightJob: $highlightedJob
                    )
                }
                if (self.editJob != nil) { // edit form
                    JobEntryForm(
                        showingForm: $showingEditEntryFrom,
                        job: jobEntries.first{ $0.entryID == self.editJob } ?? JobEntry(),
                        editJobId: $editJob,
                        hightlightJob: $highlightedJob
                    )
                }
            }

        }
        .animation(.bouncy(), value: self.showingDatesForm)
        .animation(.bouncy(extraBounce: 0.1), value: self.payPeriod)
        .animation(.bouncy(), value: self.editJob)
        .animation(.bouncy(), value: self.showingNewEntryForm)
        .contentTransition(.numericText())
        
        .alert(
            isPresented: $showingInfoAlert
        ) {
            Alert(
                title: Text(verbatim: self.payPeriod.toString() + " Info"),
                message: Text(verbatim: self.getInfoTxt()),
                primaryButton:
                    Alert.Button.default(Text(verbatim: "Close")),
                secondaryButton:Alert.Button.default(Text(verbatim: "Fix Database"), action: {
//                    CoreDataManager.shared.fixDatabase()
                })
            )
        }
        .alert("Export Timecard:", isPresented: $showingExportAlert) {
            Button("With Descriptions", role: .none) {
                let url = createTimeCardPDF(
                    entries: self.jobEntries,
                    payperiod: self.payPeriod,
                    showingDesc: true
                )
                
                self.shareURL(url: url)
            }
            
            Button("Without Descriptions", role: .none) {
                let url = createTimeCardPDF(
                    entries: self.jobEntries,
                    payperiod: self.payPeriod,
                    showingDesc: false
                )
                
                self.shareURL(url: url)
            }
            Button("Cancel", role: .cancel) { }
        }
        
        .onChange(of: self.highlightedJob) {
            scrollTo(id: self.highlightedJob)
        }
        
        
    }
    

    func scrollTo(id: UUID?) {
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
            let hrs = entry.startTime.hrsOffset(relativeTo: entry.endTime)

            totalHours += hrs
            totalPay += getPayFromJob(
                id: entry.jobTypeID,
                hrs: hrs
            )
        }
        
        var infoTXT = String(totalHours) + " hrs\n$" + String(floor(totalPay * 0.88)) + "\n"
        
        infoTXT += entries.getHoursTotals().toText()
        
        return infoTXT
    }
    
    func shareURL(url: URL) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)
    }

}







struct JobEntryForm: View {
    
    @Environment(\.modelContext) var modelContext
    
    @Binding var showingForm : Bool
    @Binding var editJobID : UUID?
    @Binding var actualHighlightID : UUID?
    
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
        hightlightJob : Binding<UUID?>
    ) {
        self.newForm = true
        self.job = nil
        self._showingForm = showingForm
        self._editJobID = Binding<UUID?>(get: { nil }, set: { _ in })
        self._actualHighlightID = hightlightJob
        
        self.newEntryJobID = ""
        self.newEntryStart = roundTime(time: Date())
        self.newEntryEnd = roundTime(time: Date())
        self.newEntryDesc = ""
    }
    init (
        showingForm : Binding<Bool>,
        job : JobEntry,
        editJobId : Binding<UUID?>,
        hightlightJob : Binding<UUID?>
    ) {
        self.newForm = false
        self.job = job
        self._showingForm = showingForm
        self._editJobID = editJobId
        self._actualHighlightID = hightlightJob
        
        self.newEntryJobID = job.jobTypeID
        self.newEntryStart = job.startTime
        self.newEntryEnd = job.endTime
        self.newEntryDesc = job.desc
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
        
        // Hide Keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
       
    }
    
    private func addJob() {
        let newEntry = JobEntry(
            jobTypeID: self.newEntryJobID,
            startTime: roundTime(time: self.newEntryStart),
            endTime: roundTime(time: self.newEntryEnd),
            desc: self.newEntryDesc
        )
        withAnimation {
            modelContext.insert(newEntry)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            actualHighlightID = newEntry.entryID
        }
        
        self.closeForm()
    }
    private func updateJob() {

        withAnimation {
            DataStorageSystem.shared.updateEntry(
                entry: self.job!,
                jobTypeID: self.newEntryJobID,
                startTime: self.newEntryStart,
                endTime: self.newEntryEnd,
                desc: self.newEntryDesc
            )
        }
        
        self.closeForm()
    }
    private func deleteJob() {
        DataStorageSystem.shared.deleteEntry(entry: self.job!)
        
        highlightedJob = nil
        editJobID = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            actualHighlightID = nil
        }
        
        self.closeForm()
    }

   
}











#Preview {
    return PayPeriodView(
        period: getCurrentPayperiod()
    )
    .modelContainer(DataStorageSystem.shared.container)
    .modelContext(DataStorageSystem.shared.context)
}
