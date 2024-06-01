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

    
    @State var payPeriod : PayPeriod
    @State var titleText: String
    @State var titleColor: Color
    
    var jobEntries: [JobEntry] {
        CoreDataManager.shared.fetchJobEntries(
            dateRange: self.payPeriod.getRange())
    }
    var totalHoursString : String {
        var total = 0.0
        for job in self.jobEntries {
            total += job.startTime?.hrsOffset(relativeTo: job.endTime ?? Date()) ?? 0
        }
        return String(total)
    }
    @State var highlightedJob : ObjectIdentifier? = nil


    @State var isShowingShareSheet : Bool = false;
    @State private var jsonData: String = ""
    
    
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
                List() {
                    
                    Color.black
                        .frame(height: 120)
                        .padding(-20)

                    
                    ForEach(
                        self.jobEntries
                    ) { job in

                        HStack() {
                            
                            Button(action: {
                                if (highlightedJob == job.id) {
                                    highlightedJob = nil
                                } else {
                                    highlightedJob = job.id
                                }
                            }) {
                            
                                VStack(alignment: .leading) {
                                    
                                    JobView(job: job)
                                        .animation(.bouncy(), value: self.highlightedJob)
                                    
                                    if (highlightedJob == job.id) {
                                        
                                        DescriptionView(job: job)
                                        .animation(.bouncy(), value: self.highlightedJob)
                                    }
                                } // VStack
                                
                            } // Button
                            
                            
                        } // HStack
                        .listRowBackground(Color.init(red: 0.1, green: 0.1, blue: 0.1))
                        

                    } // For Each
                    .onDelete(perform: deleteJob)
                    
                } // List
                .scrollContentBackground(.hidden)
                .listRowSpacing(10)
                .padding(.bottom, 70)
                
                Spacer()
            }
            
            
            VStack() { // Blurs
                
                Color.black
                    .opacity(0.5)
                    .ignoresSafeArea(.all)
                    .background(.ultraThinMaterial)
                    .frame(maxHeight: 130)
                
                Spacer()
                
                Color.black
                    .opacity(0.5)
                    .ignoresSafeArea(.all)
                    .background(.ultraThinMaterial)
                    .frame(maxHeight: 80)
                
            }
            
            
            VStack() {
                Button(self.titleText) {
                    self.payPeriod = getCurrentPayperiod()
                }
                .foregroundColor(self.titleColor)
                .font(.largeTitle)
                .fontWeight(.black)
            
                    
                HStack() {
                    Button(" ", systemImage: "arrow.left") {
                        self.shiftPayPeriod(forwards: false)
                    }
                    .foregroundColor(.yellow)
                    .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                    .fontWeight(.black)
                    
                    Spacer()
                    
                    Button(self.payPeriod.toString()) {
                        
                    }
                    .foregroundColor(.white)
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.01)
                        
                    
                    Spacer()
                    
                    Button(" ", systemImage: "arrow.right") {
                        self.shiftPayPeriod(forwards: true)
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
            
                
                Spacer()
                
                NavView(activePage: .PayPeriod)
                    .padding(.bottom, 0)

            }
            
            
            
        }
        .animation(.bouncy(), value: self.highlightedJob)
        
    }
    
    
    
    
    
    
    private func addJob() {
       CoreDataManager.shared.createJobEntry(desc: "New Job", jobID: UUID().uuidString, startTime: Date(), endTime: Date())
   }

   private func deleteJob(at offsets: IndexSet) {
       
       for index in offsets {

           let job = self.jobEntries[index]
           
           CoreDataManager.shared.deleteJobEntry(jobEntry: job)
           
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
    
    var job : JobEntry
    
    var body: some View {
        
        
        HStack() {
            
            VStack(alignment: .leading) {
                let color = getJobColor(running: true, jobID: getJobFromID(id: self.job.jobID ?? "undef").rawValue)
                
                Text(getJobFromID(id: job.jobID ?? "undef").rawValue)
                    .fontWeight(.black)
                    .foregroundColor(color)
                    .font(.title2)
                
                Text(job.startTime ?? Date(), style: .date)
                    .foregroundColor(.white)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("\(job.startTime ?? Date(), formatter: itemFormatter) - \(job.endTime ?? Date(), formatter: itemFormatter)")
                    .foregroundColor(.white)
                    .font(.title3)
                    .fontWeight(.bold)
                
            }
            
            Spacer()
            
            VStack() {
                
                var num = job.startTime?.hrsOffset(relativeTo: job.endTime ?? Date()) ?? 0.00
                
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
struct DescriptionView : View {
    
    var job : JobEntry

    var body: some View {
        VStack(alignment: .leading) {
            Divider()
            Text("Job Description:")
                .font(.title2)
                .fontWeight(.black)
                .foregroundColor(.white)
            
            
            Text(self.job.desc ?? "Error Reading Description")
                .font(.body)
                .foregroundColor(.white)
                .monospaced()
        }
    }

}





#Preview {
    let context = CoreDataManager.shared.context
//    CoreDataManager.shared.populateSampleData()
    return PayPeriodView(
        period: getCurrentPayperiod()
    ).environment(\.managedObjectContext, context)
}
