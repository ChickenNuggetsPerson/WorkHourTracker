//
//  AppDelegate.swift
//  WorkTracker
//
//  Created by Hayden Steele on 5/31/24.
//

import Foundation




import Foundation
import CoreData
import UIKit
import CoreData




class CoreDataManager {
    static let shared = CoreDataManager()

    var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Storage")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        print("Loaded Storage")
        
        return container
    }()

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    // Create a new JobEntry
    func createJobEntry(desc: String?, jobID: String?, startTime: Date?, endTime: Date?) {
        let jobEntry = JobEntry(context: context)
        jobEntry.desc = desc
        jobEntry.jobID = jobID
        jobEntry.startTime = startTime
        jobEntry.endTime = endTime
        
        print("Saving JOB: " + (startTime?.formatted() ?? ""))
        
        saveContext()
    }

    // Update an existing JobEntry
    func updateJobEntry(jobEntry: JobEntry, desc: String?, jobID: String?, startTime: Date?, endTime: Date?) {
        jobEntry.desc = desc
        jobEntry.jobID = jobID
        jobEntry.startTime = startTime
        jobEntry.endTime = endTime
        
        print("Updating JOB: " + (startTime?.formatted() ?? ""))
        
        saveContext()
    }

    // Delete a JobEntry
    func deleteJobEntry(jobEntry: JobEntry) {
        context.delete(jobEntry)
        
        print("Deleting JOB: " + (jobEntry.startTime?.formatted() ?? ""))
    
        saveContext()
    }
    
    func fetchJobEntries(dateRange: ClosedRange<Date>) -> [JobEntry] {
        let fetchRequest: NSFetchRequest<JobEntry> = JobEntry.fetchRequest()
           fetchRequest.predicate = NSPredicate(format: "(startTime >= %@) AND (startTime <= %@)", dateRange.lowerBound as NSDate, dateRange.upperBound as NSDate)

           do {
               let jobEntries = try context.fetch(fetchRequest)
               return jobEntries
           } catch {
               print("Error fetching job entries: \(error.localizedDescription)")
               return []
           }
    }
    
    func fetchAllJobEntries() -> [JobEntry] {
        let fetchRequest: NSFetchRequest<JobEntry> = JobEntry.fetchRequest()
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching objects of type \(JobEntry.Type.self): \(error.localizedDescription)")
            return []
        }
    }
    
    
    func fetchMinMaxStartTimes() -> (minDate: Date?, maxDate: Date?) {
        let fetchRequest: NSFetchRequest<NSDictionary> = NSFetchRequest(entityName: "JobEntry")
        fetchRequest.resultType = .dictionaryResultType

        // Expression description for minimum start time
        let minExpressionDesc = NSExpressionDescription()
        minExpressionDesc.name = "minStartTime"
        minExpressionDesc.expression = NSExpression(forFunction: "min:", arguments:[NSExpression(forKeyPath: "startTime")])
        minExpressionDesc.expressionResultType = .dateAttributeType

        // Expression description for maximum start time
        let maxExpressionDesc = NSExpressionDescription()
        maxExpressionDesc.name = "maxStartTime"
        maxExpressionDesc.expression = NSExpression(forFunction: "max:", arguments:[NSExpression(forKeyPath: "startTime")])
        maxExpressionDesc.expressionResultType = .dateAttributeType

        // Set expressions for fetch request
        fetchRequest.propertiesToFetch = [minExpressionDesc, maxExpressionDesc]

        do {
            let results = try context.fetch(fetchRequest)
            if let resultDict = results.first {
                let minDate = resultDict["minStartTime"] as? Date
                let maxDate = resultDict["maxStartTime"] as? Date
                return (minDate, maxDate)
            } else {
                return (nil, nil)
            }
        } catch {
            print("Error fetching min and max start times: \(error.localizedDescription)")
            return (nil, nil)
        }
    }
    
    
//    func exportToJSON() -> String {
//        let jobEntries : [JobEntry] = CoreDataManager.shared.fetchAllJobEntries()
//        let jobEntryDicts = jobEntries.map { $0.toDictionary() }
//        
//        print(jobEntryDicts)
//        
//        do {
//            let jsondata = try JSONSerialization.data(withJSONObject: jobEntryDicts, options: .prettyPrinted)
//            return String(data: jsondata, encoding: .utf8) ?? ""
//        } catch {
//            print("Error Making JSON Data")
//            return ""
//        }
//    }
    

    
}



extension [JobEntry] {
    func sortByDay() -> [[JobEntry]] {
        var newList : [[JobEntry]] = []
        
        var runningDay : [JobEntry] = []
        var previousDate: Int? = nil
        
        var firstRun = true;
        
        for entry in self {
            
            if let entryDate = entry.startTime?.getDateComponents().day {
                if (entryDate != previousDate) {
                    previousDate = entryDate
                    
                    if (firstRun) {
                        firstRun = false;
                    } else {
                        newList.append(runningDay)
                        runningDay.removeAll()
                    }
                }
                
                runningDay.append(entry)
            }
            
        }
        
        print(newList)
        
        return newList
    }
}
