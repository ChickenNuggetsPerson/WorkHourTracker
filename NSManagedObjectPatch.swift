//
//  NSManagedObjectPatch.swift
//  WorkTracker
//
//  Created by Hayden Steele on 5/31/24.
//

import Foundation
import CoreData


extension NSManagedObject {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        let dateFormatter = ISO8601DateFormatter()

        for attribute in self.entity.attributesByName {
            let key = attribute.key
            let value = self.value(forKey: key)

            if let dateValue = value as? Date {
                // Convert Date to ISO8601 string
                dict[key] = dateFormatter.string(from: dateValue)
            } else if let dataValue = value as? Data {
                // Optionally, handle Data (e.g., binary data, images)
                dict[key] = dataValue.base64EncodedString()
            } else {
                dict[key] = value
            }
        }
        return dict
    }
}

