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





#Preview {
    return PayPeriodView(
        period: getCurrentPayperiod()
    )
    .modelContainer(DataStorageSystem.shared.container)
    .modelContext(DataStorageSystem.shared.context)
}
