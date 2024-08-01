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
        every: 15, // second
        on: .main,
        in: .common
    ).autoconnect()
    
    @State private var startTimeString: String = " "
    @State private var endTimeString: String = " "
    
    @State private var showingSaveAlert = false;
    @State private var showingDesc = false;
    @State private var showingEditSheet = false {
        didSet {
            if (showingEditSheet == false) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                    withAnimation {
                        self.updateTexts()
                        timerSystem.startTime = roundTime(time: timerSystem.startTime)
                        timerSystem.updateLiveActivity()
                    }
                }
            }
        }
    }
    @State private var listItemSwipeToggle : Bool = true;
    
    init() {
        self.showingSaveAlert = false;
    }
    
    var body: some View {
        
        ZStack() {
            
            Color.black.ignoresSafeArea()
            
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
                            .font(
                                self.timerSystem.jobState == jobType ? .largeTitle : .title
                            )
                            .fontWeight(.black)
                            .frame(
                                maxWidth: self.timerSystem.running ? 0
                                : (self.timerSystem.jobState == jobType ? .infinity : 330),
                                maxHeight: self.timerSystem.jobState == jobType ? 80 : 70
                            )
                            .background(
                                self.timerSystem.jobState == jobType ?
                                    getJobColor(jobID: self.timerSystem.jobState.rawValue)
                                    : Color.init(red: 0.3, green: 0.3, blue: 0.3))
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
            .padding(.bottom, 295)
            .animation(.spring(duration: 0.3), value: self.timerSystem.running)
            
            
            
            ZStack() {
                if (self.showingEditSheet) {
                    
                    VStack() {
                    
                        VStack {
                            DatePicker("Select Start Time", selection: $timerSystem.startTime, in: Date().clearTime()...roundTime(time: Date()), displayedComponents: .hourAndMinute)
                                .datePickerStyle(WheelDatePickerStyle())
                                .labelsHidden()
                                .frame(maxWidth: .infinity)
                            
                            Button("Done") {
                                self.showingEditSheet.toggle()
                                RumbleSystem.shared.rumble()
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
                                    .foregroundColor(Color.init(hex: "0f0f0f"))
                                    .transformEffect(.init(translationX: 8, y: 5))
                                
                                Rectangle()
                                    .cornerRadius(25)
                                    .foregroundColor(Color.init(hex: "1c1c1e"))
                            }
                        )
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .padding(.top, 175)
                        
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity).combined(with: .scale))
                }
            }
            
            
            
            
            VStack() {
                Spacer()
                
                if (self.listItemSwipeToggle) {
                    JobEntryView(
                        jobTypeID: getIDFromJob(type: self.timerSystem.jobState),
                        startTime: self.timerSystem.running ? self.timerSystem.startTime : roundTime(time: Date()),
                        endTime: roundTime(time: Date()),
                        jobDesc: "",
                        highlightedJob: .constant(nil),
                        preview: true
                    )
                    .padding([.leading, .trailing], 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    JobEntryView(
                        jobTypeID: getIDFromJob(type: self.timerSystem.jobState),
                        startTime: self.timerSystem.running ? self.timerSystem.startTime : roundTime(time: Date()),
                        endTime: roundTime(time: Date()),
                        jobDesc: "",
                        highlightedJob: .constant(nil),
                        preview: true
                    )
                    .padding([.leading, .trailing], 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
            }
            .padding(.bottom, 80)
            .animation(.bouncy(extraBounce: 0.1), value: self.listItemSwipeToggle)
            
            VStack() { // Nav Button
                Spacer()
                NavView(gotoPage: Pages.PayPeriod)
            }
            .padding(.bottom, 210)
            
            VStack() { // Start / Stop Times
                Spacer()
                HStack() {
                    Spacer()
                    
                    if (self.timerSystem.running && !self.showingEditSheet) {
                        Button(action: {
                            self.showingEditSheet.toggle()
                            RumbleSystem.shared.rumble()
                        }) {
                            Text(
                                "Start:\n" + self.startTimeString
                            )
                            .padding()
                            .foregroundColor(getJobColor(jobID: self.timerSystem.jobState.rawValue).darkened(by: -0.3))
                            .font(.title)
                            .fontWeight(.black)
                            .multilineTextAlignment(.center)
                            .monospaced()
                        }
                        .disabled(!self.timerSystem.running)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                        
                        Spacer()
                        
                        
                        Button(action: {
                            RumbleSystem.shared.rumble()
                        }) {
                            Text(
                                "End:\n" + self.endTimeString
                            )
                            .padding()
                            .foregroundColor(.gray)
                            .font(.title)
                            .fontWeight(.black)
                            .multilineTextAlignment(.center)
                            .monospaced()
                        }
                        .disabled(true)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                    
            
                    
                    Spacer()
                    
                }
                .padding(.bottom, 285)
            }
            
            
            VStack() { // Start / Stop Button Colors
                Spacer()
                RunningBackgroundView(
                    mainColor: self.timerSystem.running ?
                        getJobColor(jobID: self.timerSystem.jobState.rawValue)
                        : .clear,
                    height: 60,
                    running: self.timerSystem.running
                )
            }
            // Start / Stop Button
            VStack(spacing: 0) {
                Spacer()
                
                Button(action: {
                    self.startStopButtonPress()
                }) {
                    VStack() {
                        Text(self.timerSystem.running ? "Stop" : "Start")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    .foregroundStyle(self.showingEditSheet ? .gray : .white)
                    .fontWeight(.black)
                    .font(.title)
                    .monospaced()
                }
                .background(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .frame(width: nil, height: 5, alignment: .leading)
                        .foregroundColor(Color.init(red: 0.2, green: 0.2, blue: 0.2))
                    
                    , alignment: .top
                )
                .disabled(self.showingEditSheet)
            }
            
            
            VStack() { // Top Bar
                
                VStack() {
                    Button(payPeriod.toString()) {
                        self.timerSystem.enableDisableLiveAcitivty()
                        RumbleSystem.shared.rumble()
                    }
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                    
                    Button(self.timerSystem.jobState.rawValue) {
                        self.showingDesc.toggle()
                        RumbleSystem.shared.rumble()
                    }
                    .font(
                        (self.timerSystem.running && !self.showingEditSheet) ? .system(size: 60) : .title
                    )
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(
                        height: self.showingEditSheet ? 90 :
                            (self.timerSystem.running ? 290 : 120)
                    )
                    .multilineTextAlignment(.center)
                    .disabled(!self.timerSystem.running)
                    
                    
                    
                } // End of Inner VStack
                .background(
                    self.timerSystem.running ? 
                    getJobColor(jobID: self.timerSystem.jobState.rawValue).darkened(by: 0.01)
                    : Color.init(hex: "#1f1f1f")
                )
                .overlay(
                    Rectangle()
                        .frame(width: nil, height: 5, alignment: .leading)
                        .foregroundColor(
                            self.timerSystem.running ? 
                            getJobColor(jobID: self.timerSystem.jobState.rawValue).darkened(by: -0.1) :
                                Color.init(red: 0.2, green: 0.2, blue: 0.2)
                        )
                    
                    , alignment: .bottom
                )
                
                
                Spacer()
                
            }
            
            
            ZStack() {
                if (self.showingDesc) {
                    Color.black.ignoresSafeArea()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    
                    Form() {
                        Section() {
                            Button("Close") {
                                self.showingDesc = false
                                self.hideKeyboard()
                                RumbleSystem.shared.rumble()
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
                    .transition(.move(edge: .bottom).combined(with: .opacity))
        
                }
            }
  
        }
        
    
        .alert("What do you want to do?", isPresented: $showingSaveAlert) {
            Button("Save and Stop Timer", role: .none) {
                self.timerSystem.save()
                self.timerSystem.stopTimer()
                self.listItemSwipeToggle.toggle()
                RumbleSystem.shared.rumble()
            }
            Button("Stop Timer (Don't Save)", role: .destructive) {
                self.timerSystem.stopTimer()
                RumbleSystem.shared.rumble()
            }
            Button("Cancel", role: .cancel) { }
        }
    
        // Main updater
        .onReceive(timer) { (_) in
            withAnimation {
                self.updateTexts()
            }
        }
        .onAppear() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation {
                    self.updateTexts()
                }
            }
        
        }
        
        .animation(.snappy(duration: 0.5), value: self.timerSystem.running)
        .animation(.snappy, value: self.timerSystem.jobState)
        .animation(.bouncy, value: self.timerSystem.startTime)
        .animation(.snappy, value: self.showingDesc)
        .animation(.snappy, value: self.showingEditSheet)
        .contentTransition(.numericText())
        
    }
        
    
    
    
    func updateTexts() {
        
        if (self.timerSystem.running) {
            
            self.startTimeString = roundTime(time: self.timerSystem.startTime).getTimeText()
        } else {
            self.startTimeString = roundTime(time: Date()).getTimeText()
        }
        
        self.endTimeString = roundTime(time: Date()).getTimeText()
    }
    
    func startStopButtonPress() {
        
        if (self.timerSystem.running) {
            if (self.timerSystem.startTime != roundTime(time: Date())) {
                self.showingSaveAlert = true
                return
            }
        }
    
        self.timerSystem.toggleTimer()
        RumbleSystem.shared.rumble()
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
}



struct RunningBackgroundView : View {
    var mainColor : Color
    var height: CGFloat
    var running: Bool
    
    var repeatingAnimation: Animation {
            Animation
            .easeInOut(duration: 3)
                .repeatForever()
    }
    
    
    static private var startVal : Double = 0.0
    static private var endVal : Double = 1
    
    @State var animVal : Double = startVal
    
    var body: some View {
        VStack() {
            mainColor
                .ignoresSafeArea()
        }
        .frame(maxHeight: height)
        .opacity(animVal)
        .scaleEffect(x: 1, y: animVal, anchor: .bottom)
        
        .onAppear() {
            self.animTrigger()
        }
        .onChange(of: running) {
            self.animTrigger()
        }
    }
    
    
    func animTrigger() {
        
        if (!self.running) {
            
            if (self.animVal == RunningBackgroundView.startVal) {return}
            self.animVal = RunningBackgroundView.startVal
            return
        }
        
        withAnimation(self.repeatingAnimation) {
            if (self.animVal == RunningBackgroundView.startVal) {
                self.animVal = RunningBackgroundView.endVal
            } else {
                self.animVal = RunningBackgroundView.startVal
            }
        }
    }
    
}




#Preview {
    MainView()
        .modelContainer(DataStorageSystem.shared.container)
        .modelContext(DataStorageSystem.shared.context)
}
