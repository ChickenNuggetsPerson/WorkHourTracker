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
            ShortcutsProvider.updateAppShortcutParameters()
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
        jobEntry.intentEntityID = UUID()
        
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
    func fetchJobEntries(withUUIDs uuids: [UUID]) -> [JobEntry] {
        let fetchRequest: NSFetchRequest<JobEntry> = JobEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "intentEntityID IN %@", uuids.map { $0 as CVarArg })

        // Perform the fetch
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching job entries: \(error.localizedDescription)")
            return []
        }
    }
    func fetchSuggestedEntries() -> [JobEntry] {
        let fetchRequest: NSFetchRequest<JobEntry> = JobEntry.fetchRequest()
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        fetchRequest.fetchLimit = 5
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching suggestions: \(error.localizedDescription)")
            return []
        }
    }
    func fetchPayPeriods() -> [PayPeriod] {
        
        let fetchRequest: NSFetchRequest<JobEntry> = JobEntry.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: true)]
        fetchRequest.fetchLimit = 1
        
        let furthestEntry : JobEntry?
        
        do {
            furthestEntry = try context.fetch(fetchRequest).first ?? nil
        } catch {
            print("Error fetching suggestions: \(error.localizedDescription)")
            return []
        }
        
        if (furthestEntry == nil) { return [] }
        
        var periods : [PayPeriod] = []
        
        var refDate = furthestEntry!.startTime!
        refDate = getPayPeriod(refDay: refDate).endDate // set ref date to end of period
        
        if (refDate < Date()) {
            while refDate < Date() {
                periods.append(getPayPeriod(refDay: refDate))
                refDate = refDate.addDays(days: 14)
            }
        }
        
        periods.append(getCurrentPayperiod())
        
        return periods
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
    
 
    
    func fixDatabase() { // Adds uuids to the entries
        let fetchRequest: NSFetchRequest<JobEntry> = JobEntry.fetchRequest()
        
        do {
            let jobEntries = try context.fetch(fetchRequest)
            
            for jobEntry in jobEntries {
                if jobEntry.intentEntityID == nil {
                    jobEntry.intentEntityID = UUID()
                }
            }
            
            saveContext()
            
        } catch {
            print("Error fetching job entries: \(error.localizedDescription)")
        }
    }

    
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
