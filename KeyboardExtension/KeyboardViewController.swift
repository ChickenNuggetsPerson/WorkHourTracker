//
//  KeyboardViewController.swift
//  KeyboardExtension
//
//  Created by Hayden Steele on 7/25/24.
//

import UIKit
import SwiftUI

class KeyboardViewController: UIInputViewController {

    @IBOutlet var nextKeyboardButton: UIButton!
    private var hostingController: UIHostingController<CustomKeyboardView>?
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        // Add custom view sizing constraints here
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        // Initialize the SwiftUI view with a closure to handle key taps
        let customKeyboardView = CustomKeyboardView { [weak self] key in
            self?.textDocumentProxy.insertText(key)
        }
        
        let hostingController = UIHostingController(rootView: customKeyboardView)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(hostingController.view)
        self.addChild(hostingController)
        hostingController.didMove(toParent: self)
        
        // Constraints for the hostingController's view
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        self.hostingController = hostingController
        
        // Setup the next keyboard button
        self.nextKeyboardButton = UIButton(type: .system)
        self.nextKeyboardButton.setTitle(NSLocalizedString("Next Keyboard", comment: "Title for 'Next Keyboard' button"), for: [])
        self.nextKeyboardButton.sizeToFit()
        self.nextKeyboardButton.translatesAutoresizingMaskIntoConstraints = false
        self.nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        
        self.view.addSubview(self.nextKeyboardButton)
        
        NSLayoutConstraint.activate([
            self.nextKeyboardButton.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.nextKeyboardButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])

    }
    
    override func viewWillLayoutSubviews() {
        self.nextKeyboardButton.isHidden = !self.needsInputModeSwitchKey
        super.viewWillLayoutSubviews()
    }
    
    override func textWillChange(_ textInput: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        // The app has just changed the document's contents, the document context has been updated.
        
        var textColor: UIColor
        let proxy = self.textDocumentProxy
        if proxy.keyboardAppearance == UIKeyboardAppearance.dark {
            textColor = UIColor.white
        } else {
            textColor = UIColor.black
        }
        self.nextKeyboardButton.setTitleColor(textColor, for: [])
    }

}







struct CustomKeyboardView: View {
    var keyTapped: (String) -> Void
    var storage: DataStorageSystem = DataStorageSystem()
    
    
    @State var range: PayPeriod = getCurrentPayperiod()
    @State var entries: [JobEntry] = []
    @State var selectedPPRD: Int = 1
    
    @State var showingForm = false
    
    init(keyTapped: @escaping (String) -> Void) {
        self.keyTapped = keyTapped
        
    }
    
    var body: some View {
        ZStack() {
            Color.black.darkened(by: -0.1)
            
            VStack() { // List
                
            
                ScrollView() {
                    
                    Color.clear.frame(height: 50)
                        .id("top")
                    
                    ForEach(self.entries.indices, id: \.self) { i in
                        
                        if (i == 0 || !Calendar.current.isDate(self.entries[i].startTime, inSameDayAs: self.entries[i-1].startTime)) {
                            
                            HStack() {
                                
                                Button(self.entries[i].startTime.toDate()) {
                                    
                                }
                                .foregroundColor(
                                    Color(hex: "#9f9f9f")
                                )
                                .font(.title3)
                                .fontWeight(.black)
                                .monospaced()
                                
                                Spacer()
                                
                            }
                            .padding([.leading, .trailing], 20)
                            .padding(.top, 15)
                            .transition(.move(edge: .leading))
                            
                            .modifier(KayboardConditionalScrollTransition(condition: true))
                        }
                        
                        KeyboardJobEntryView(
                            job: self.entries[i],
                            closureFunc: {
                                
                                self.keyTapped(self.entries[i].toDict().toJSONString())
                                
                            }
                        )
                        .padding([.leading, .trailing], 10)
                        
                        .modifier(KayboardConditionalScrollTransition(
                            condition: true
                        ))
                    
                        
                    } // For Each
                    .transition(.opacity.combined(with: .scale(scale: 0.2, anchor: .center)))
                    
                    Color.clear.frame(height: 20)
                    
                    
                } // Scroll View
                .scrollContentBackground(.hidden)
                
            } // VStack
            .padding(.top, 0)
            .padding(.bottom, 0)
         
            
            VStack() {
                Color.clear
                    .ignoresSafeArea()
                    .background(.ultraThinMaterial)
                    .frame(height: 50)
                
                Spacer()
            }
            
            
            VStack() {
                Button("Select an entry to share:") {
                    withAnimation {
                        self.showingForm.toggle()
                    }
                }
                    .foregroundColor(.white)
                    .font(.title2)
                    .fontWeight(.black)
                    .padding(.top, 10)
                
                Spacer()
            }
            
            
            
            
            VStack() {
                if (self.showingForm) {
                    Form {
                        Section("Date Range: ") {
                            
                            DatePicker("Start:", selection: self.$range.startDate)
                            DatePicker("End:", selection: self.$range.endDate, in: self.range.startDate...)
                        }
                       
                        Button("Select Payperiod") {
                            self.range = getCurrentPayperiod()
                        }
                        .foregroundColor(.green)
                        .fontWeight(.bold)
                        
                        Button("Close") {
                            withAnimation {
                                self.showingForm.toggle()
                            }
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .frame(minHeight: 300, maxHeight: 300)
        .onAppear() {
            self.entries = self.storage.fetchJobEntries(dateRange: self.range.range)
        }
        .onChange(of: self.range) {
            if (self.range.startDate > self.range.endDate) {
                self.range.endDate = self.range.startDate
            }
            self.entries = self.storage.fetchJobEntries(dateRange: self.range.range)
        }
        .environment(\.colorScheme, .dark)
    }
}








struct KeyboardJobEntryView: View {
    
    var entryJobID : String
    var entryStart : Date
    var entryEnd : Date
    var entryDesc : String
 
    var clickClosure : () -> Void

    init( // Main List
        job: JobEntry,
        closureFunc: @escaping () -> Void
    ) {
    
        self.entryJobID = job.jobTypeID
        self.entryStart = job.startTime
        self.entryEnd = job.endTime
        self.entryDesc = job.desc
        
        self.clickClosure = closureFunc
    }

    
    var body: some View {
        VStack() {
            
            Button(action: {
                
                self.clickClosure()
                
            }) {
                
                ZStack() {
                    
                    HStack() {
                        VStack(alignment: .leading) {
                                              
                            Text(getJobFromID(id: self.entryJobID).rawValue)
                                .fontWeight(.black)
                                .foregroundColor(
                                    getJobColor(jobID: getJobFromID(id: self.entryJobID).rawValue)
                                )
                                .font(.title2)
                            
                            Text(self.entryStart.toDate())
                                .foregroundColor(.white)
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Text(
                                self.entryStart.getTimeText()
                                + " - "
                                + self.entryEnd.getTimeText()
                            )
                                .foregroundColor(.white)
                                .font(.title3)
                                .fontWeight(.bold)
                            
                        }
                        
                        Spacer()
                    }
                    
                    
                    
                    VStack {
                        
                        HStack() {
                            
                            Spacer()
                            
                            Text(self.entryStart.hrsOffset(relativeTo: self.entryEnd).toHrsString())
                            .foregroundColor(.white)
                            .font(.title2)
                            .fontWeight(.black)
                            .monospaced()
                            
                        }
                        
                    }
                        
            
                }
//                .padding(.bottom, self.isHighlighted ? 0 : -7)
                
            } // Button
            .padding()
            
        } // VStack
        .padding([.leading, .trailing])
        .padding([.top, .bottom], 5)
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

    }
    
}





struct KayboardConditionalScrollTransition: ViewModifier {
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
    CustomKeyboardView(keyTapped: {_ in })
}
