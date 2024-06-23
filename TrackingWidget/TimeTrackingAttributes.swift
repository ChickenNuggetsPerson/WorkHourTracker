//
//  TimeTrackingAttributes.swift
//  WorkTracker
//
//  Created by Hayden Steele on 5/29/24.
//

import Foundation
import ActivityKit
import SwiftUI

struct TimeTrackingAttributes: ActivityAttributes {
    public typealias TimeTrackingStatus = ContentState
    
    public struct ContentState: Codable, Hashable {
        var startTime: Date
        var jobType: String
        var jobColor: Color
        var saveState: Bool
    }
}
