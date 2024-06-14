//
//  ContentView.swift
//  WorkTracker
//
//  Created by Hayden Steele on 5/28/24.
//

import SwiftUI

extension AnyTransition {
    static func moveOrFade(edge: Edge) -> AnyTransition {
        AnyTransition.asymmetric(
            insertion: .move(edge: edge),
            removal: .move(edge: edge)
        )
    }
}

struct MainView: View {
    
    @State private var running : Bool
    @State private var jobState : JobTypes
    
    @State private var startTime : Date
    @State private var jobDescription : String
    
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
    
    var liveActivitySystem = LiveActivitySystem()
    
    init() {
        if let storedTime = UserDefaults.standard.object(forKey: "startTime") as? Date {
            self.startTime = storedTime
    
        } else {
            
            print("Could not read")
            
            self.startTime = roundTime(time: Date())
        }
        
        self.running = UserDefaults.standard.bool(forKey: "running")
        self.jobState = JobTypes(rawValue: UserDefaults.standard.string(forKey: "jobType") ?? JobTypes.Manager.rawValue)!

        self.showingSaveAlert = false;
        
        self.jobDescription = UserDefaults.standard.string(forKey: "desc") ?? ""
        
        self.enableDisableLiveAcitivty()

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
            .opacity(self.running ? 1 : 0)
            
            
            VStack() { // Job Type List
                
                Spacer()
                
                ForEach(JobTypes.allCases.filter { e in
                    return (e != JobTypes.undef) && (e != JobTypes.IT)
                }, id: \.self) { jobType in
                    
                    Button(action: {
                        self.jobState = jobType
                        UserDefaults.standard.set(jobType.rawValue, forKey: "jobType")
                    }) {
                        Text(jobType.rawValue)
                            .foregroundColor(.white)
                            .font(.title)
                            .fontWeight(.black)
                            .frame(
                                maxWidth: self.running ? 0 
                                : (self.jobState == jobType ? .infinity : 330),
                                maxHeight: self.jobState == jobType ? 80 : 70
                            )
                            .background(
                                self.jobState == jobType ?
                                getJobColor(jobID: self.jobState.rawValue) :
                                    Color.init(red: 0.3, green: 0.3, blue: 0.3))
                            .opacity(self.jobState == jobType ? 1 : 0.5)
                            .cornerRadius(15)
                            .shadow(
                                color: self.jobState == jobType ? getJobColor(jobID: self.jobState.rawValue) : .clear,
                                radius: 10,
                                x: 0,
                                y: 0
                            )
                        
                    }
                }
                        
            }
            .padding([.leading, .trailing])
            .padding(.bottom, 300)
            .animation(.spring(duration: 0.3), value: self.running)
            .animation(.bouncy(), value: self.jobState)
            

            VStack() {
                Spacer()
                NavView(activePage: Pages.Main)
            }
            .padding(.bottom, self.running ? 300 : 200)
            
            
            VStack() { // Start / Stop Times
                Spacer()
                HStack() {
                    Spacer()
                    
                    Text("Start:\n" + self.startTimeString)
                        .foregroundColor(self.running ? Color.cyan : .white)
                        .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                        .fontWeight(.black)
                        .multilineTextAlignment(.center)
                        .monospacedDigit()
                    
                    Spacer()
                    
                    if (self.running) {
                        Text("End:\n" + self.endTimeString)
                            .foregroundColor(self.running ? .gray : .white)
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
                (self.running ? Color.red : Color.green)
                    .ignoresSafeArea()
                    .frame(maxHeight: 60)
            }
            // Start / Stop Button
            VStack(spacing: 0) {
                Spacer()
                
                Button(action: {
                    self.StartStopBtn()
                }) {
                    HStack() {
//                        Image(systemName: self.running ? "stop" : "play")
                        Text(self.running ? "Stop" : "Start")
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
                getJobColor(jobID: self.jobState.rawValue)
                
                    .ignoresSafeArea()
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: self.running ? 360 : 0
                    )
                    .padding(.top, self.running ? 0 : -100)
                    .animation(.snappy, value: self.running)
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
                    
                    Button(self.jobState.rawValue) {
                        if (!self.running) {return}
                        self.showingDesc.toggle()
                    }
                    .font(
                        self.running ? .system(size: 60) : .title
                    )
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight:
                            self.running ? 290 : 120
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
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.bold)
                }
                
                Section("Job Description") {
                    TextEditor(text: $jobDescription)
                        .font(.title3)
                        .fontWeight(.regular)
                        .onChange(of: jobDescription) {
                            self.saveDescString(str: self.jobDescription)
                        }
                }
            }
            .opacity(self.showingDesc ? 1 : 0)
        }
        
    
        .alert("What do you want to do?", isPresented: $showingSaveAlert) {
            Button("Save and Stop Timer", role: .none) {
                save()
                self.setRunning(run: false);
            }
            Button("Stop Timer (Don't Save)", role: .destructive) {
                self.setRunning(run: false);
            }
            Button("Cancel", role: .cancel) { }
        }
    
        // Main updater
        .onReceive(timer) { (_) in
            self.updateTexts()
        }
        .animation(.bouncy, value: self.running)
        .animation(.spring, value: self.jobState)
        .animation(.easeInOut, value: self.showingDesc)
        .contentTransition(.numericText())
    }
        
    
    
    
    func updateTexts() {
        self.timerString = String(self.startTime.hrsOffset(relativeTo: roundTime(time: Date()))) + " hrs"
       
        if (self.running) {
            
            self.startTimeString = dateToTime(date: roundTime(time: self.startTime))
            
            self.endTimeString = dateToTime(date: roundTime(time: Date()))
        } else {
            self.startTimeString = dateToTime(date: roundTime(time: Date()))
        }
    }

    func StartStopBtn() {

        if (!self.running) {
        
            let newStart = roundTime(time: Date())
            self.setStartTime(time: newStart)
            
            self.setRunning(run: true);
            
        } else {
            // Done
            let endTime = roundTime(time: Date())
            if (self.startTime == endTime) {
                
                self.setRunning(run: false);
                
                return; // Not enough time has passed
            }
            
            // Save time
            showingSaveAlert = true;
            return
            
        }
        
    
    }
    
    func setRunning(run : Bool) {
        self.running = run;
        UserDefaults.standard.set(self.running, forKey: "running")
        self.enableDisableLiveAcitivty()
        if (run == false) {
            self.showingDesc = false
            self.jobDescription = ""
            self.saveDescString(str: "")
        }
    }
    func setStartTime(time: Date) {
        self.startTime = time
        UserDefaults.standard.set(time, forKey: "startTime")
    }
    
    func saveDescString(str : String) {
        UserDefaults.standard.set(str, forKey: "desc")
    }
    
    func enableDisableLiveAcitivty() {
        
        if (self.running) {
            liveActivitySystem.stopLiveActivity()
            
            liveActivitySystem.startLiveActivity(
                startTime: self.startTime,
                jobState: self.jobState.rawValue,
                jobColor: getJobColor(jobID: self.jobState.rawValue)
            )
        } else {
            liveActivitySystem.stopLiveActivity()
        }
    }
    
    func save() {
        let start = self.startTime
        let stop = roundTime(time: Date())
//        print(start.formatted())
//        print(stop.formatted())
        
        CoreDataManager.shared.createJobEntry(
            desc: self.jobDescription,
            jobID: getIDFromJob(type: self.jobState),
            startTime: start,
            endTime: stop
        )
        
        
    }
    
}


#Preview {
    MainView()
}
