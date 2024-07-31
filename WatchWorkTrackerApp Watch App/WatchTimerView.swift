//
//  WatchTimerView.swift
//  WatchWorkTrackerApp Watch App
//
//  Created by Hayden Steele on 7/30/24.
//

import SwiftUI

struct WatchTimerView: View {
    
    @State var dataFetcher = WatchDataFetcher.shared
    @State var showEditView : Bool = false
    
    let timer = Timer.publish(
        every: 60, // second
        on: .main,
        in: .common
    ).autoconnect()
    
    var body: some View {
        ZStack() {
            
            VStack() {
                VStack() {
                    
                    Spacer()
                    
                    HStack() {
                        Spacer()
                        
                        Text(dataFetcher.currentTimerStatus.jobState == .undef
                             ? "Fetching Data"
                             : dataFetcher.currentTimerStatus.jobState.rawValue
                        )
                            .font(dataFetcher.currentTimerStatus.running ? .title2 : .title3)
                        .fontWeight(.black)
                        .multilineTextAlignment(.center)
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
                .ignoresSafeArea()
                .frame(maxWidth: .infinity)
                .background(
                    dataFetcher.currentTimerStatus.running ?
                    getJobColor(jobID: dataFetcher.currentTimerStatus.jobState.rawValue)
                    : .gray.darkened(by: 0.4)
                )
                .frame(height: dataFetcher.currentTimerStatus.running ? 110 : 30)
                
                
                Spacer()
            }
            .onTapGesture {
                dataFetcher.fetchTimerStatus()
            }
            
                        
            VStack() {
                Spacer()
                
                if (!dataFetcher.currentTimerStatus.running) {
                    Button("Edit") {
                        self.showEditView.toggle()
                    }
//                    .disabled(dataFetcher.currentTimerStatus.jobState == .undef)
                    .padding(.bottom, 15)
                }
                
                Button(dataFetcher.currentTimerStatus.running ? "Stop" : "Start") {
                    dataFetcher.currentTimerStatus.running.toggle()
                    dataFetcher.sendTimerStatus()
                }
                .disabled(dataFetcher.currentTimerStatus.jobState == .undef)
                .padding(.bottom, 5)
            }
            .ignoresSafeArea()
            
            
            VStack() {
                if (showEditView) {
                    Form {
                        Picker("", selection: $dataFetcher.currentTimerStatus.jobState) {
                            ForEach(JobTypes.allCases.filter { e in
                                return (e != JobTypes.undef && e != JobTypes.IT)
                            }, id: \.self) { jobType in
                                
                                Text(jobType.rawValue)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .tag(getIDFromJob(type: jobType))

                            }
                        }
                        .pickerStyle(.inline)
                        
                        Button("Close") {
                            self.showEditView.toggle()
                            dataFetcher.sendTimerStatus()
                        }
                    }
                    .ignoresSafeArea()
                    .background(.black)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    
                    
                }
            }
            
        }
        .animation(.bouncy, value: dataFetcher.currentTimerStatus)
        .contentTransition(.numericText())
        
        
        
        .onAppear() {

        }
        .onReceive(timer) { (_) in
            withAnimation {
                dataFetcher.fetchTimerStatus()
            }
        }
    }
}

#Preview {
    WatchTimerView()
}
