//
//  AppDelegate.swift
//  WorkTracker
//
//  Created by Hayden Steele on 5/31/24.
//

import Foundation
import SwiftData


@Model
final class JobEntry {
    
    @Attribute var jobTypeID: String
    @Attribute var startTime: Date
    @Attribute var endTime: Date
    @Attribute var desc: String
    @Attribute var entryID: UUID
    
    init(jobTypeID: String, startTime: Date, endTime: Date, desc: String) {
        self.jobTypeID = jobTypeID
        self.startTime = startTime
        self.endTime = endTime
        self.desc = desc
        self.entryID = UUID()
    }
    init() {
        self.jobTypeID = ""
        self.startTime = Date()
        self.endTime = Date()
        self.desc = ""
        self.entryID = UUID()
    }
}


class DataStorageSystem {
    static let shared = DataStorageSystem()
    
    let container : ModelContainer
    let context : ModelContext
    
    init() {

        do {
            self.container = try ModelContainer(for: JobEntry.self)
            self.context = ModelContext(self.container)
        } catch {
            print("CANNOT CREATE CONTAINER")
            fatalError()
        }
    }
    
    
    
    func createEntry(
        jobTypeID: String,
        startTime: Date,
        endTime: Date,
        desc: String
    ) {
        let newEntry = JobEntry(
            jobTypeID: jobTypeID,
            startTime: startTime,
            endTime: endTime,
            desc: desc
        )
        
        self.context.insert(newEntry)
        print("Created Entry: \(newEntry)")
    }
    func deleteEntry(
        entry: JobEntry
    ) {
        self.context.delete(entry)
        print("Deleted Entry: \(entry)")
    }
    func updateEntry(
        entry: JobEntry,
        jobTypeID: String,
        startTime: Date,
        endTime: Date,
        desc: String
    ) {
        
        do {
            
            let job = try fetchJobEntry(uuid: entry.entryID)
            
            job.jobTypeID = jobTypeID
            job.startTime = startTime
            job.endTime = endTime
            job.desc = desc
            
            print("Updated Entry: \(job)")
            
        } catch {
            print("Error Updated Entry")
        }
        
    }
    
    
    func fetchAllJobEntries() -> [JobEntry] {
        let descriptor = FetchDescriptor<JobEntry>(sortBy: [
            .init(\.startTime)
        ])
        
        do {
            return try context.fetch(descriptor)
        } catch {
            return []
        }
    }
    func fetchJobEntries(dateRange: ClosedRange<Date>) -> [JobEntry] {
        let predicate = #Predicate<JobEntry> {
            $0.startTime > dateRange.lowerBound && $0.startTime < dateRange.upperBound
        }
        let descriptor = FetchDescriptor<JobEntry>(
            predicate: predicate,
            sortBy: [ .init(\.startTime)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            return []
        }
    }
    func fetchJobEntry(uuid: UUID) throws -> JobEntry {
        let predicate = #Predicate<JobEntry> {
            $0.entryID == uuid
        }
        let descriptor = FetchDescriptor<JobEntry>(
            predicate: predicate,
            sortBy: [ .init(\.startTime)]
        )
        
        return try context.fetch(descriptor).first!
    }
    func fetchSuggestedEntries() -> [JobEntry] {
        var descriptor = FetchDescriptor<JobEntry>(
            sortBy: [ .init(\.startTime)]
        )
        descriptor.fetchLimit = 5
        
        do {
            return try context.fetch(descriptor)
        } catch {
            return []
        }
    }
    func fetchPayPeriods() -> [PayPeriod] {

        let furthestEntry : JobEntry?

        var descriptor = FetchDescriptor<JobEntry>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        
        do {
            furthestEntry = try context.fetch(descriptor).first
        } catch {
            return []
        }
        

        if (furthestEntry == nil) { return [] }

        var periods : [PayPeriod] = []

        var refDate = furthestEntry!.startTime
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
}
