//
//  ContentView.swift
//  WorkTracker
//
//  Created by Hayden Steele on 5/28/24.
//

import SwiftUI

struct MainView: View {
    
    @ObservedObject var timerSystem = TimerSystem.shared
    
    var payPeriod : PayPeriod = getCurrentPayperiod()

    let timer = Timer.publish(
        every: 1, // second
        on: .main,
        in: .common
    ).autoconnect()
    
    @State private var timerString: String = " "
    @State private var startTimeString: String = " "
    @State private var endTimeString: String = " "
    
    @State private var showingSaveAlert = false;
    @State private var showingDesc = false;
    @State private var showingEditSheet = false {
        didSet {
            if (showingEditSheet == false) {
                timerSystem.startTime = roundTime(time: timerSystem.startTime)
                timerSystem.updateLiveActivity()
            }
        }
    }
    
    init() {
        self.showingSaveAlert = false;
    }
    
    var body: some View {
        
        ZStack() {
            
            Color.black.ignoresSafeArea()
            
            VStack() {
                Spacer()
            
                Text("Time:")
                    .foregroundColor(Color.mint)
                    .font(.largeTitle)
                    .fontWeight(.black)
                Text(self.timerString)
                    .foregroundColor(Color.white)
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .monospaced()
                
            }
            .padding(.bottom, 180)
            .opacity(timerSystem.running ? 1 : 0)
            
            
            VStack() { // Job Type List
                
                Spacer()
                
                ForEach(JobTypes.allCases.filter { e in
                    return (e != JobTypes.undef) && (e != JobTypes.IT)
                }, id: \.self) { jobType in
                    
                    Button(action: {
                        self.timerSystem.jobState = jobType
                        RumbleSystem.shared.rumble()
                    }) {
                        Text(jobType.rawValue)
                            .foregroundColor(.white)
                            .font(.title)
                            .fontWeight(.black)
                            .frame(
                                maxWidth: self.timerSystem.running ? 0
                                : (self.timerSystem.jobState == jobType ? .infinity : 330),
                                maxHeight: self.timerSystem.jobState == jobType ? 80 : 70
                            )
                            .background(
                                self.timerSystem.jobState == jobType ?
                                getJobColor(jobID: self.timerSystem.jobState.rawValue) :
                                    Color.init(red: 0.3, green: 0.3, blue: 0.3))
                            .opacity(self.timerSystem.jobState == jobType ? 1 : 0.5)
                            .cornerRadius(15)
                            .shadow(
                                color: self.timerSystem.jobState == jobType ? getJobColor(jobID: self.timerSystem.jobState.rawValue) : .clear,
                                radius: 10,
                                x: 0,
                                y: 0
                            )
                        
                    }
                }
                        
            }
            .padding([.leading, .trailing])
            .padding(.bottom, 300)
            .animation(.spring(duration: 0.3), value: self.timerSystem.running)
            .animation(.bouncy(), value: self.timerSystem.jobState)
            

            VStack() {
                Spacer()
                NavView(activePage: Pages.Main)
            }
            .padding(.bottom, self.timerSystem.running ? 300 : 200)
            
            
            VStack() { // Start / Stop Times
                Spacer()
                HStack() {
                    Spacer()
                    
                    Button(action: {
                        self.showingEditSheet.toggle()
                    }) {
                        Text("Start:\n" + self.startTimeString)
                            .foregroundColor(self.timerSystem.running ? Color.cyan : .white)
                            .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                            .fontWeight(.black)
                            .multilineTextAlignment(.center)
                            .monospacedDigit()
                    }
                    .disabled(!self.timerSystem.running)
                    
                    Spacer()
                    
                    if (self.timerSystem.running) {
                        Text("End:\n" + self.endTimeString)
                            .foregroundColor(self.timerSystem.running ? .gray : .white)
                            .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                            .fontWeight(.black)
                            .multilineTextAlignment(.center)
                            .monospacedDigit()
                        
                        Spacer()
                    }
                }
                .padding(.bottom, 90)
            }
    
            
            VStack() { // Start / Stop Button Colors
                Spacer()
                (self.timerSystem.running ? Color.red : Color.green)
                    .ignoresSafeArea()
                    .frame(maxHeight: 60)
            }
            // Start / Stop Button
            VStack(spacing: 0) {
                Spacer()
                
                Button(action: {
                    self.startStopButtonPress()
                }) {
                    HStack() {
                        Text(self.timerSystem.running ? "Stop" : "Start")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundStyle(.white)
                    .fontWeight(.black)
                    .font(.title)
                    .monospaced()
                }
                .background(.ultraThinMaterial)
            }

            
            
            VStack() { // Top Bar background color
                getJobColor(jobID: self.timerSystem.jobState.rawValue)
                
                    .ignoresSafeArea()
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: self.timerSystem.running ? 360 : 0
                    )
                    .padding(.top, self.timerSystem.running ? 0 : -100)
                    .animation(.snappy, value: self.timerSystem.running)
                Spacer()
            }
                
            VStack() { // Top Bar
                
                VStack() {
                    Text(payPeriod.toString())
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                    
                    Button(self.timerSystem.jobState.rawValue) {
                        if (!self.timerSystem.running) {return}
                        self.showingDesc.toggle()
                    }
                    .font(
                        self.timerSystem.running ? .system(size: 60) : .title
                    )
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight:
                            self.timerSystem.running ? 290 : 120
                    )
                    .multilineTextAlignment(.center)
                    
                    
                    
                } // End of Inner VStack
                .background(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                    .frame(width: nil, height: 5, alignment: .leading)
                    .foregroundColor(Color.init(red: 0.2, green: 0.2, blue: 0.2))
                    
                    , alignment: .bottom
                )
                
                
                Spacer()

            }
            
        
            Form() {
                Section() {
                    Button("Close") {
                        self.showingDesc = false
                        self.hideKeyboard()
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.bold)
                }
                
                Section("Job Description") {
                    TextEditor(text: $timerSystem.jobDescription)
                        .font(.title3)
                        .fontWeight(.regular)
                }
            }
            .opacity(self.showingDesc ? 1 : 0)
            
            VStack() {
                Spacer()
                
                ListItemView(
                    jobTypeID: getIDFromJob(type: timerSystem.jobState),
                    startTime: roundTime(time: timerSystem.startTime),
                    endTime: roundTime(time: Date()),
                    jobDesc: "",
                    highlightedJob: .constant(nil),
                    preview: true
                )
                .padding(10)
                
                VStack {
                    DatePicker("Select Start Time", selection: $timerSystem.startTime, in: Date().clearTime()...roundTime(time: Date()), displayedComponents: .hourAndMinute)
                        .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    
                    Button("Done") {
                        self.showingEditSheet.toggle()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.black)
                    .font(.body)
                    .padding()
                }
                .background(
                    GeometryReader { geometry in
                        Rectangle()
                        .cornerRadius(25)
                        .foregroundColor(Color.init(hex: "1c1c1e"))
                    }
                )
                .frame(maxWidth: .infinity)
                .padding(10)
                
                Spacer()
            }
            .background(.black)
            .opacity(self.showingEditSheet ? 1 : 0)
        }
        
    
        .alert("What do you want to do?", isPresented: $showingSaveAlert) {
            Button("Save and Stop Timer", role: .none) {
                self.timerSystem.save()
                self.timerSystem.stopTimer()
            }
            Button("Stop Timer (Don't Save)", role: .destructive) {
                self.timerSystem.stopTimer()
            }
            Button("Cancel", role: .cancel) { }
        }
    
        // Main updater
        .onReceive(timer) { (_) in
            self.updateTexts()
        }
        .animation(.bouncy, value: self.timerSystem.running)
        .animation(.spring, value: self.timerSystem.jobState)
        .animation(.easeInOut, value: self.showingDesc)
        .animation(.bouncy, value: self.showingEditSheet)
        .animation(.bouncy, value: self.timerSystem.startTime)
        .contentTransition(.numericText())
    }
        
    
    
    
    func updateTexts() {
        self.timerString = String(
            self.timerSystem.startTime.hrsOffset(relativeTo: roundTime(time: Date()))
        ) + " hrs"
       
        if (self.timerSystem.running) {
            
            self.startTimeString = dateToTime(date: roundTime(time: self.timerSystem.startTime))
            
            self.endTimeString = dateToTime(date: roundTime(time: Date()))
        } else {
            self.startTimeString = dateToTime(date: roundTime(time: Date()))
        }
    }
    
    func startStopButtonPress() {
        
        if (self.timerSystem.running) {
            if (self.timerSystem.startTime != roundTime(time: Date())) {
                self.showingSaveAlert = true
                return
            }
        }
    
        self.timerSystem.toggleTimer()
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
}


#Preview {
    MainView()
        .modelContainer(DataStorageSystem.shared.container)
        .modelContext(DataStorageSystem.shared.context)
}
