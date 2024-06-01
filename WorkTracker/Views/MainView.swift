//
//  ContentView.swift
//  WorkTracker
//
//  Created by Hayden Steele on 5/28/24.
//

import SwiftUI

struct MainView: View {
    
    @State private var running : Bool
    @State private var jobState : JobTypes
    
    @State private var startTime : Date
    @State var jobDescription : String
    
    var payPeriod : PayPeriod = getCurrentPayperiod()

    let timer = Timer.publish(
        every: 1, // second
        on: .main,
        in: .common
    ).autoconnect()
    
    @State var timerString: String = " "
    @State var startTimeString: String = " "
    @State var endTimeString: String = " "
    
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
        
        VStack(spacing: 0) {
            
            VStack(spacing: 0){
                Text(payPeriod.toString())
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                
                
                
                if (self.showingDesc) {
                    
                    Text("Enter Task Descriptions Here")
                    .foregroundColor(.white)
                    .font(.title3)
                    .fontWeight(.bold)
                        
                    ZStack() {
                        
                        TextEditor(text: $jobDescription)
                            .frame(minHeight: 300)
                            .foregroundColor(.black)
                            .font(.title3)
                            .fontWeight(.bold)
                            .scrollContentBackground(.hidden)
                            .background(.thinMaterial)
                            .cornerRadius(10)
                            .padding()
                            .onChange(of: jobDescription) {
                                self.saveDescString(str: self.jobDescription)
                            }
                    }
                    
                    Spacer()
                    
                }
  
                Button(self.jobState.rawValue) {
                    if (!self.running) {return}
                    
                    self.showingDesc.toggle()
                }
                .font(
                        self.running ? .system(size: 60) : .title
                )
                .fontWeight(.black)
                .foregroundColor(.white)
                .padding(.bottom)
                .frame(maxWidth: .infinity, minHeight:
                        self.running ? 250 : 100
                )
                .multilineTextAlignment(.center)
                

            }
            .background(getJobColor(running: self.running, jobID: self.jobState.rawValue))
            .overlay(Rectangle().frame(width: nil, height: 10, alignment: .leading).foregroundColor(Color.white), alignment: .bottom)
            .padding(.bottom)
            .shadow(
                color: getJobColor(running: true, jobID: self.jobState.rawValue),
                radius: self.running ? 20 : 0,
                x: 0,
                y: 0
            )
            .animation(.bouncy, value: self.running)
            
            
            
            
            if (!self.showingDesc) {
                
                Spacer()
                
                if (self.running) {
                    VStack() {
                        Text("Time:")
                            .foregroundColor(Color.yellow)
                            .font(.largeTitle)
                            .fontWeight(.black)
                        
                        Text(self.startTime, style: .timer)
                            .foregroundColor(Color.white)
                            .font(.largeTitle)
                            .fontWeight(.black)
                            .padding(.bottom)
                            .monospaced()
                        
                        Text("Official Time:")
                            .foregroundColor(Color.mint)
                            .font(.largeTitle)
                            .fontWeight(.black)
                        Text(self.timerString)
                            .foregroundColor(Color.white)
                            .font(.largeTitle)
                            .fontWeight(.black)
                            .monospaced()
                        
                    }
                    .padding(.bottom)
                    .opacity(self.running ? 1 : 0)
                } else {
                    VStack() {
                        ForEach(JobTypes.allCases.filter { e in
                            return e != JobTypes.undef
                        }, id: \.self) { jobType in
                            
                            Button(action: {
                                self.jobState = jobType
                                UserDefaults.standard.set(jobType.rawValue, forKey: "jobType")
                            }) {
                                Text(jobType.rawValue)
                                    .foregroundColor(.white)
                                    .font(.title)
                                    .fontWeight(.black)
                                    .padding()
                                    .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
                                    .background(self.jobState == jobType ? getJobColor(running: true, jobID: self.jobState.rawValue) : Color.init(red: 0.3, green: 0.3, blue: 0.3))
                                    .opacity(self.jobState == jobType ? 1 : 0.5)
                                    .cornerRadius(15)
                                    .shadow(
                                        color: self.jobState == jobType ? getJobColor(running: true, jobID: self.jobState.rawValue) : .clear,
                                        radius: 10,
                                        x: 0,
                                        y: 0
                                    )
                               
                            }
                        }
                    }
                    .padding([.leading, .trailing])
                    
                    
                    Spacer()
                    
                    NavView(activePage: Pages.Main)

                }
            } // End of massive IF statement for self.showingDesc
            
            Spacer()
            
            if (!self.showingDesc) {
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
                .padding(.bottom)
                .padding(10)
            }
            
    
            // Start / Stop Button
            VStack(spacing: 0) {
                
                Button(action: {
                    self.StartStopBtn()
                }) {
                    HStack() {
                        Image(systemName: self.running ? "stop" : "play")
                        Text(self.running ? "Stop" : "Start")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(self.running ? Color.red : Color.green)
                    .foregroundStyle(.white)
                    .fontWeight(.black)
                    .font(.title)
                }
            }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            
        
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
            .animation(.bouncy(extraBounce: 0.1), value: self.running)
            .animation(.bouncy(), value: self.jobState)
            .animation(.bouncy(extraBounce: 0.1), value: self.showingDesc)
        
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
            self.startTime = newStart
            UserDefaults.standard.set(newStart, forKey: "startTime")
            
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
    
    func saveDescString(str : String) {
        UserDefaults.standard.set(str, forKey: "desc")
    }
    
    func enableDisableLiveAcitivty() {
        
        if (self.running) {
            liveActivitySystem.startLiveActivity(
                startTime: self.startTime,
                jobState: self.jobState.rawValue,
                jobColor: getJobColor(running: true, jobID: self.jobState.rawValue)
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
