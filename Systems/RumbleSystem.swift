//
//  RumbleSystem.swift
//  WorkTracker
//
//  Created by Hayden Steele on 6/20/24.
//

import Foundation
import UIKit

class RumbleSystem {
    static let shared = RumbleSystem()
    let generator = UIImpactFeedbackGenerator(style: .medium)
    
    func rumble() {
        generator.impactOccurred()
    }
    
}
