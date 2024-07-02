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
    
    @ObservedObject var storageSystemInstance = DataStorageSystem.shared
    
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
    
    
    var canGoBack : Bool { payPeriod.startDate > DataStorageSystem.shared.dataBounds.startDate }
    var canGoForwards : Bool { payPeriod.endDate < DataStorageSystem.shared.dataBounds.endDate }
    
    
    @State var highlightedJob : UUID? = nil
    @State var highlightedDate : Date? = nil
    
    @State private var showingDatesForm = false;
    @State private var showingInfoAlert = false;
    @State private var showingExportAlert = false;
    
    @State private var editJob : UUID? = nil;
    @State private var showingNewEntryForm = false;
   
    @State private var isShowingPicker = false
    
    
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
                        
                        Color.clear.frame(height: 140)
                        
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
                            .transition(
                                .push(from: .bottom)
                                .combined(with: .opacity)
                                .combined(with: .scale)
                            )
                            
                        } // For Each
                        .onDelete(perform: { indexSet in
                            
                        })
                        
                        Color.clear.frame(height: 80)
                        
                        
                    } // Scroll View
                    .scrollContentBackground(.hidden)
                    .onAppear {
                        scrollProxyHolder.proxy = proxy
                    }
                }
            }
            
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
                
                Color.black // Bottom Blur
                    .opacity(0.5)
                    .ignoresSafeArea(.all)
                    .background(.ultraThinMaterial)
                    .frame(
                        maxHeight: (DataStorageSystem.shared.showUndo) ? 130 : 80
                    )
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
                    .foregroundColor(self.canGoBack ? Color.yellow.darkened(by: 0.1) : .gray)
                    .font(.title)
                    .fontWeight(.black)
                    .disabled(!self.canGoBack)
                    
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
                    .foregroundColor(self.canGoForwards ? Color.yellow.darkened(by: 0.1) : .gray)
                    .font(.title)
                    .fontWeight(.black)
                    .disabled(!self.canGoForwards)
                }
                .padding([.leading, .trailing], 25)
                
                
                Button(self.totalHoursString + " hrs") {
                    self.showingExportAlert = true;
                    RumbleSystem.shared.rumble()
                }
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.blue)
            
                
                if (self.showingDatesForm) {
                    Divider()
                    VStack() {
                        DatePicker(
                            selection: $payPeriod.startDate,
                            in: DataStorageSystem.shared.dataBounds.startDate...DataStorageSystem.shared.dataBounds.endDate
                        ) {
                            Text("Start Time:")
                        }
                        
                        DatePicker(
                            selection: $payPeriod.endDate,
                            in: self.payPeriod.startDate...DataStorageSystem.shared.dataBounds.endDate
                        ) {
                            Text("End Time:")
                        }
                    }
                    .padding([.trailing, .leading], 25)
                }
                
                
                Spacer()

            }
            
            
            
            VStack() { // Undo Menus
                
                
                Spacer()
                
                
                
                HStack() {
                    if (DataStorageSystem.shared.showUndo) {
                        
                        Button("Undo", systemImage: "arrow.uturn.backward") {
                            DataStorageSystem.shared.undo()
                            self.refresh.toggle()
                        }
                        .foregroundColor(
                            DataStorageSystem.shared.canUndo ? .blue : .gray
                        )
                        .font(.title3)
                        .fontWeight(.black)
                        .padding(.leading, 10)
                        .disabled(!DataStorageSystem.shared.canUndo)
                        
                        Spacer()
                        
                        Button("Redo", systemImage: "arrow.uturn.forward") {
                            DataStorageSystem.shared.redo()
                            self.refresh.toggle()
                        }
                        .foregroundColor(
                            DataStorageSystem.shared.canRedo ? .blue : .gray
                        )
                        .font(.title3)
                        .fontWeight(.black)
                        .padding(.trailing, 10)
                        .disabled(!DataStorageSystem.shared.canRedo)
                        
                    }
                }
                
                HStack() {
                    Button("", systemImage: "info.circle") {
                        self.showingInfoAlert = true
                        RumbleSystem.shared.rumble()
                    }
                    .padding(20)
                    .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                    .fontWeight(.black)
                    
                    Spacer()
                    
                    
                    NavView(gotoPage: .Main)
                        .padding(.bottom, 0)
                    
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
                        hightlightJob: $highlightedJob,
                        showDate: $highlightedDate
                    )
                }
                if (self.editJob != nil) { // edit form
                    JobEntryForm(
                        showingForm: .constant(true),
                        job: jobEntries.first{ $0.entryID == self.editJob } ?? JobEntry(),
                        editJobId: $editJob,
                        hightlightJob: $highlightedJob,
                        showDate: $highlightedDate
                    )
                }
            }

        }
        .animation(.bouncy(), value: self.showingDatesForm)
        .animation(.bouncy(), value: self.payPeriod)
        .animation(.snappy, value: self.editJob)
        .animation(.snappy, value: self.showingNewEntryForm)
        .animation(.bouncy(), value: self.highlightedJob)
        .animation(.bouncy(), value: DataStorageSystem.shared.canUndo)
        .animation(.bouncy(), value: DataStorageSystem.shared.canRedo)
        .animation(.bouncy(), value: DataStorageSystem.shared.showUndo)
        .contentTransition(.numericText())
        
        .alert(
            self.payPeriod.toString() + " Info",
            isPresented: $showingInfoAlert
        ) {
            
            
//            Button("Fix Database") {
//                CoreDataManager.shared.fixDatabase()
//            }
            
            Button("Export Database") {
                do {
                    let url = try DataStorageSystem.shared.exportToJSON()
                    self.shareURL(url: url)
                } catch {}
            }
            
            Button("Import Database") {
                self.isShowingPicker = true
            }
            
            Button("Close") {
                
            }
            
    
        } message: {
            Text(self.getInfoTxt())
        }
        
        .fileImporter(isPresented: $isShowingPicker, allowedContentTypes: [ .text ], allowsMultipleSelection: true) { result in
            
            switch result {
               case .success(let files):
                   files.forEach { file in
                       // gain access to the directory
                       let gotAccess = file.startAccessingSecurityScopedResource()
                       if !gotAccess { return }
                       
                       
                       do {
                
                           try DataStorageSystem.shared.importDatabase(url: file)
                           
                           
                       } catch {
                           print("Error selecting file: \(error.localizedDescription)")
                           
                       }
                       
                       
                       // release access
                       file.stopAccessingSecurityScopedResource()
                   }
               case .failure(let error):
                   // handle error
                   print(error)
               }

            
            
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
        .onChange(of: highlightedDate) {
            if (highlightedDate == nil) { return; }
            
            print("Calc Show Date")
            
            if (!self.payPeriod.range.contains(self.highlightedDate!)) {
                self.payPeriod = getPayPeriod(refDay: highlightedDate!)
            }
        }
        
    }
    

    func scrollTo(id: UUID?) {
        DispatchQueue.main.async() {
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





#Preview {
    return PayPeriodView(
        period: getCurrentPayperiod()
    )
    .modelContainer(DataStorageSystem.shared.container)
    .modelContext(DataStorageSystem.shared.context)
}
