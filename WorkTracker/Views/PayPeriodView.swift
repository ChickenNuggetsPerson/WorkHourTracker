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


enum PayPeriodViewMode : String {
    case PayPeriod = "Pay Period"
    case Week = "Week"
}

struct SurroundingEntries {
    var prevJob: UUID?
    var nextJob: UUID?
}
extension [JobEntry] {
    func getSurroundingEntries(id : UUID?) -> SurroundingEntries {
        print(id ?? "")
        
        var surrounding = SurroundingEntries(prevJob: id, nextJob: id)
        
        guard let id = id else { return surrounding }
        
        let index = self.firstIndex { $0.entryID == id }
        guard let index = index else { return surrounding }
        
        
        if (self.indices.contains(index - 1)) {
            surrounding.prevJob = self[index - 1].entryID
        }

        
        if (self.indices.contains(index + 1)) {
            surrounding.nextJob = self[index + 1].entryID
        }
       
        
        return surrounding
    }
}


class JobEntryCacher {
    static var shared : JobEntryCacher = JobEntryCacher()
    
    var cachedData : [JobEntry] = []
    var pprdHash : Int = 0
    
    func data(range: PayPeriod) -> [JobEntry] {
        if (pprdHash != range.hashValue) {
            print("Refresh Cache: " + UUID().uuidString)
            cachedData = DataStorageSystem.shared.fetchJobEntries(dateRange: range.range)
            pprdHash = range.hashValue
        }
        
        return cachedData
    }
}


struct PayPeriodView: View {
    
    @Environment(\.modelContext) var modelContext
    
    @ObservedObject var storageSystemInstance = DataStorageSystem.shared
    
    @State var refresh: Bool = false
    
    @State var viewMode: PayPeriodViewMode = .PayPeriod
    @State var viewRange : PayPeriod = getCurrentPayperiod()
    
    var defaultViewRange: PayPeriod {
        switch self.viewMode {
        case .PayPeriod:
            return getCurrentPayperiod()
        case .Week:
            return getCurrentWeek()
        }
    }
    
    var titleColor: Color {
        switch self.viewMode {
            case .PayPeriod:
                return Color.green
            case .Week:
                return Color.init(hex: "#FF6463")
        }
    }
    
    
    var jobEntries: [JobEntry] { JobEntryCacher.shared.data(range: viewRange) }

    var totalHours : Double {
        var total = 0.0
        for job in self.jobEntries {
            total += job.totalHours()
        }
        return total
    }
    
    
    var canGoBack : Bool { viewRange.startDate > DataStorageSystem.shared.dataBounds.startDate }
    var canGoForwards : Bool { viewRange.endDate < DataStorageSystem.shared.dataBounds.endDate }
    
    
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

    
    init() {
       
    }
    
    
    var body: some View {
        
        ZStack() {
        
            Color.black.ignoresSafeArea(.all)
            
            VStack() { // List
                ScrollViewReader { proxy in

                    ScrollView() {
                        
                        Color.clear.frame(height: 0)
                            .id("top")
                        
                        ForEach(self.jobEntries.indices, id: \.self) { i in
                            
                            if (i == 0 || !Calendar.current.isDate(self.jobEntries[i].startTime, inSameDayAs: self.jobEntries[i-1].startTime)) {
                                
                                DayDivider(
                                    day: self.jobEntries[i].startTime,
                                    blur: self.highlightedJob != nil
                                )
                            }
                            
                            ListItemView(
                                job: self.jobEntries[i],
                                highlightedJob: $highlightedJob,
                                editJob: $editJob,
                                preview: false
                            )
                            .padding([.leading, .trailing], 10)
                            .id(self.jobEntries[i].entryID)
                            
                            .modifier(ConditionalScrollTransition(
                                condition: true
                            ))
                        
                            
                        } // For Each
                        .transition(.opacity.combined(with: .scale(scale: 0.2, anchor: .center)))
                        
                        Color.clear.frame(height: 20)
                        
                        
                    } // Scroll View
                    .scrollContentBackground(.hidden)
                    .onAppear {
                        scrollProxyHolder.proxy = proxy
                    }
                    .scrollDisabled(self.highlightedJob != nil)
                } // Scroll View Reader
                .gesture(DragGesture(minimumDistance: 10, coordinateSpace: .local)
                    .onEnded({value in
                        
                        
                        if (abs(value.translation.height) > abs(value.translation.width)) {
                            // Vertical Swipe
                            
                            if (self.highlightedJob == nil) { return }
                            if (value.translation.height > 0) {
                                
                                self.highlightedJob = self.jobEntries.getSurroundingEntries(id: self.highlightedJob).prevJob
                                
                            } else {
                                
                                self.highlightedJob = self.jobEntries.getSurroundingEntries(id: self.highlightedJob).nextJob
                                
                            }
                            
                            
                        } else {
                            // Horizontal Swipe
                            if (value.translation.width > 0) {
                                self.shiftPayPeriod(forwards: false)
                            } else {
                                self.shiftPayPeriod(forwards: true)
                            }
                        }
                        
                       
                        
                        RumbleSystem.shared.rumble()
                    })
                )
    
            }
            .padding(.top, 115)
            .padding(.bottom, 70)
            
            
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
                
                
                Button(self.viewMode.rawValue) {
                    
                    if (self.viewRange == self.defaultViewRange) {
                        
                        // Switch Mode
                        switch self.viewMode {
                            case .PayPeriod:
                                self.viewMode = .Week
                            case .Week:
                                self.viewMode = .PayPeriod
                        }
                        
                    }
                    
                    self.viewRange = self.defaultViewRange
                    
                    self.highlightedJob = nil
                    RumbleSystem.shared.rumble()
                }
                .foregroundColor(
                    (self.viewRange == self.defaultViewRange) ? self.titleColor : .gray
                )
                .font(.largeTitle)
                .fontWeight(.black)
                .contentTransition(.interpolate)
            
                    
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
                    
                    Button(self.viewRange.toString()) {
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
                
                
                Button(self.totalHours.toHrsString()) {
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
                            selection: $viewRange.startDate,
                            in: DataStorageSystem.shared.dataBounds.range
                        ) {
                            Text("Start Time:")
                        }
                        
                        DatePicker(
                            selection: $viewRange.endDate,
                            in: self.viewRange.startDate...DataStorageSystem.shared.dataBounds.endDate
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
        .animation(.bouncy(duration: 0.5), value: self.viewRange)
        .animation(.snappy, value: self.editJob)
        .animation(.snappy, value: self.showingNewEntryForm)
        .animation(.bouncy(duration: 1.5), value: self.highlightedJob)
        .animation(.bouncy(), value: DataStorageSystem.shared.canUndo)
        .animation(.bouncy(), value: DataStorageSystem.shared.canRedo)
        .animation(.bouncy(), value: DataStorageSystem.shared.showUndo)
        .contentTransition(.numericText())
        
        .alert(
            self.viewRange.toString() + " Info",
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
                    payperiod: self.viewRange,
                    showingDesc: true
                )
                
                self.shareURL(url: url)
            }
            
            Button("Without Descriptions", role: .none) {
                let url = createTimeCardPDF(
                    entries: self.jobEntries,
                    payperiod: self.viewRange,
                    showingDesc: false
                )
                
                self.shareURL(url: url)
            }
            Button("Cancel", role: .cancel) { }
        }
        
        .onChange(of: self.highlightedJob) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                scrollTo(id: self.highlightedJob)
            }
        }
        .onChange(of: highlightedDate) {
            if (highlightedDate == nil) { return; }
            
            print("Calc Show Date")
            
            if (!self.viewRange.range.contains(self.highlightedDate!)) {
                self.viewMode = .PayPeriod
                self.viewRange = getPayPeriod(refDay: highlightedDate!)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    scrollTo(id: self.highlightedJob)
                }
            }
        }
        
    }
    

    func scrollTo(id: UUID?) {
        withAnimation(.bouncy) {
            scrollProxyHolder.proxy!.scrollTo(id, anchor: .init(x: 0.5, y: 0.5))
        }
    }
    func scrollTo(id: String) {
        withAnimation(.bouncy(duration: 10)) {
            scrollProxyHolder.proxy!.scrollTo(id, anchor: .init(x: 0.5, y: 0.5))
        }
    }
    
    func shiftPayPeriod(forwards: Bool) {
        self.highlightedJob = nil
        
        var moveAmt = 0
        switch self.viewMode {
            case .PayPeriod:
                moveAmt = 14
            case .Week:
                moveAmt = 7
        }
        
        if (forwards) {
            if (!self.canGoForwards) { return }
            
            self.viewRange.endDate = self.viewRange.endDate.addDays(days: moveAmt)
            self.viewRange.startDate = self.viewRange.startDate.addDays(days: moveAmt)
            
            
        } else {
            if (!self.canGoBack) { return }
            
            self.viewRange.startDate = self.viewRange.startDate.addDays(days: -moveAmt)
            self.viewRange.endDate = self.viewRange.endDate.addDays(days: -moveAmt)
        }
    
    }
    
    private func getInfoTxt() -> String {
        var totalPay = 0.0
        var totalHours = 0.0
        
        let entries = self.jobEntries
        for entry in entries {
            let hrs : Double = entry.startTime.hrsOffset(relativeTo: entry.endTime)

            totalHours += hrs
            totalPay += getPayFromJob(
                id: entry.jobTypeID,
                hrs: hrs
            )
        }
        
        var infoTXT = entries.getHoursTotals().toText()
        
        infoTXT += "\n"
        if (entries.count != 0) {
            infoTXT += "\n"
        }
        infoTXT += totalHours.toHrsString() + " -> " + totalPay.toMoneyString()

        return infoTXT
    }
    
    func shareURL(url: URL) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)
    }

}




struct DayDivider: View {
    var day: Date
    var blur: Bool
    
    var body: some View {
        HStack() {
            
            Button(self.day.toDate()) {
                RumbleSystem.shared.rumble()
            }
            .foregroundColor(
                self.blur ? .gray : Color(hex: "#9f9f9f")
            )
            .font(.title3)
            .fontWeight(.black)
            .monospaced()
            .blur(radius: self.blur ? 5 : 0)
            
            Spacer()
            
        }
        .padding([.leading, .trailing], 20)
        .padding(.top, 15)
        .transition(.move(edge: .leading))
        .id(self.day.toDate())
        
        .modifier(ConditionalScrollTransition(condition: true))
    }
}




struct ConditionalScrollTransition: ViewModifier {
    let condition: Bool

    func body(content: Content) -> some View {
        Group {
            if condition {
                content
                    .scrollTransition { content, phase in
                        content
                            .scaleEffect(phase.isIdentity ? 1 : 0.93, anchor: .center)
                            .blur(radius: phase.isIdentity ? 0 : 3)
                            .opacity(phase.isIdentity ? 1 : 0.9)
                            .offset(y: phase.value * 10)
                    }
            } else {
                content
            }
        }
    }
}








#Preview {
    return PayPeriodView()
    .modelContainer(DataStorageSystem.shared.container)
    .modelContext(DataStorageSystem.shared.context)
}

