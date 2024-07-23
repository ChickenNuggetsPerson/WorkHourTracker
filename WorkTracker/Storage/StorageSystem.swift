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
    
    
    func totalHours() -> Double { self.startTime.hrsOffset(relativeTo: self.endTime) }
}

class DataStorageSystem : ObservableObject {
    static let shared = DataStorageSystem()
    
    let container : ModelContainer
    let context : ModelContext

    var dataBounds : PayPeriod = PayPeriod(startDate: Date(), endDate: Date())
    
    init() {
        self.showUndo = false
        
        do {
            self.container = try ModelContainer(for: JobEntry.self)
            self.context = ModelContext(self.container)
            
            self.context.undoManager = UndoManager()
            self.context.undoManager?.setActionName("Entry Edit")
        } catch {
            print("ERROR INITIALIZING")
            fatalError(error.localizedDescription)
        }
        
        self.genDataBounds()
        
    }
    
    
    
    
    
    
    // Entry Functions
    func createEntry(
        jobTypeID: String,
        startTime: Date,
        endTime: Date,
        desc: String,
        undoable: Bool = true
    ) -> UUID {
        let newEntry = JobEntry(
            jobTypeID: jobTypeID,
            startTime: startTime,
            endTime: endTime,
            desc: desc
        )
        
        self.context.insert(newEntry)
        
        if (undoable) {
            self.showUndo = true
        }
        
        self.genDataBounds()
        self.invalidateCache()
        print("Created Entry: \(newEntry)")
        
        return newEntry.entryID
    }
    func deleteEntry(
        entry: JobEntry
    ) {
        self.context.delete(entry)
        self.showUndo = true
        
        self.invalidateCache()
        self.genDataBounds()
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
            
            if (
                job.jobTypeID == jobTypeID
                && job.startTime == startTime
                && job.endTime == endTime
                && job.desc == desc
            ) {
                print("Same Entry, not updating")
                return
            }
            
            
            job.jobTypeID = jobTypeID
            job.startTime = startTime
            job.endTime = endTime
            job.desc = desc
            
            self.showUndo = true
            print("Updated Entry: \(job)")
            
            self.genDataBounds()
            self.invalidateCache()
            
        } catch {
            print("Error Updated Entry")
        }
        
    }
    
    
    
    // Fetching Functions
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
    
    // Fetch all job entries in the specified daterange
    private var cachedData : [JobEntry] = []
    private var pprdHash : Int = 0
    func invalidateCache() {
        pprdHash = 0
    }
 
    func fetchJobEntries(dateRange: ClosedRange<Date>) -> [JobEntry] {
        
        if (pprdHash == dateRange.hashValue) { // Check if the data is cached
            return cachedData
        }
        
        
        let predicate = #Predicate<JobEntry> {
            $0.startTime > dateRange.lowerBound && $0.startTime < dateRange.upperBound
        }
        let descriptor = FetchDescriptor<JobEntry>(
            predicate: predicate,
            sortBy: [ .init(\.startTime)]
        )
        
        do {
            cachedData = try context.fetch(descriptor)
        } catch {
            cachedData = []
        }
        
        print("Refresh Cache: " + String(dateRange.hashValue))
        pprdHash = dateRange.hashValue
        return cachedData
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
        return self.fetchLatestEntries(limit: 5)
    }
    func fetchLatestEntries(limit: Int) -> [JobEntry] {
        var descriptor = FetchDescriptor<JobEntry>(
            sortBy: [ .init(\.startTime)]
        )
        descriptor.fetchLimit = limit
        
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
    
    func genDataBounds() {
        var pprd = PayPeriod(startDate: Date(), endDate: Date())
        
    
        do { // Farthest Date
            var farthestDesc = FetchDescriptor<JobEntry>(
                sortBy: [SortDescriptor(\.startTime, order: .forward)]
            )
            farthestDesc.fetchLimit = 1
            
            let date = try context.fetch(farthestDesc).first!.startTime
            
            pprd.startDate = getPayPeriod(refDay: date).startDate
        } catch {}
        
        do { // Recent Date
            var latestDesc = FetchDescriptor<JobEntry>(
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
            latestDesc.fetchLimit = 1
            
            let date = try context.fetch(latestDesc).first!.startTime
            pprd.endDate = getPayPeriod(refDay: date).endDate
        } catch {}
        
        let currentPPRD = getCurrentPayperiod()
        if (pprd.startDate > currentPPRD.startDate) { pprd.startDate = currentPPRD.startDate }
        if (pprd.endDate < currentPPRD.endDate) { pprd.endDate = currentPPRD.endDate }
        
        print("Bounds: \(pprd.startDate) - \(pprd.endDate)")
        
        self.dataBounds = pprd
    }
    
    
    
    // Undo System Functions
    var lastEdit : Date = Date().addDays(days: -10) // Far away date
    
    let showUndoTime : Int = 5
    @Published var showUndo : Bool {
        didSet {
//            print("Set ShowUNDO to \(self.showUndo)")
            
            if (self.showUndo) {
                
                self.lastEdit = Date()
    
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(self.showUndoTime) + 0.1) {
                    
//                    print("Check ShowUNDO")
                    
                    if (Date() > self.lastEdit.addSeconds(seconds: self.showUndoTime)) {
                        self.showUndo = false;
                    }
                    
                }
                                
            }
            
        }
    }
    
    
    var canUndo : Bool {
        if ((self.context.undoManager) != nil) {
            return self.context.undoManager!.canUndo
        } else {
            return false
        }
    }
    var canRedo : Bool {
        if ((self.context.undoManager) != nil) {
            return self.context.undoManager!.canRedo
        } else {
            return false
        }
    }

    
    func undo() {
        self.context.undoManager?.undo()
        self.showUndo = true
        self.genDataBounds()
        self.invalidateCache()
    }
    func redo() {
        self.context.undoManager?.redo()
        self.showUndo = true
        self.genDataBounds()
        self.invalidateCache()
    }

    
    
    func exportToJSON() throws -> URL {
        let entities = self.fetchAllJobEntries()
        let jsonArray = entities.map { $0.toDict() }

        let jsonData = try JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted)
        
        let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            "database.json"
        )
        
        try jsonData.write(to: temporaryURL)
        
        return temporaryURL
    }
    
    func importDatabase(url : URL) throws {
        let jsonData = try Data(contentsOf: url)
        let jsonArray = try JSONSerialization.jsonObject(with: jsonData, options: []) as! [[String: String]]

        for jsonDict in jsonArray {
            let entity = JobEntry()
            entity.fromDictionary(dictionary: jsonDict)
            context.insert(entity)
        }

    }
}








extension JobEntry {
    func toDict() -> [String: String] {
        return [
            "jobTypeID": self.jobTypeID,
            "startTime": self.startTime.description,
            "endTime": self.endTime.description,
            "desc": self.desc,
            "entryID": self.entryID.description
       ]
    }
    
    func fromDictionary(dictionary: [String: String]) {
        self.jobTypeID = dictionary["jobTypeID"] ?? ""
        self.startTime = convertStringToDate(dictionary["startTime"] ?? "")
        self.endTime = convertStringToDate(dictionary["endTime"] ?? "")
        self.desc = dictionary["desc"] ?? ""
        self.entryID = UUID(uuidString: dictionary["entryID"] ?? "") ?? UUID()
    }
}

extension [String: String] {
    func toJSONString() -> String {
        do {
            let data = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            return String(data: data, encoding: .utf8)!
        } catch {
            return ""
        }
    }
}

func convertStringToDate(_ dateString: String) -> Date {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
    dateFormatter.locale = Locale(identifier: "en_US_POSIX") // Ensure consistent date parsing
    return dateFormatter.date(from: dateString) ?? Date()
}





struct SurroundingEntries {
    var prevJob: UUID?
    var nextJob: UUID?
}
extension [JobEntry] {
    func getSurroundingEntries(id : UUID?) -> SurroundingEntries {
        
        var surrounding = SurroundingEntries(prevJob: id, nextJob: id)
        
        guard let id = id else { return surrounding }
        
        let index = self.firstIndex { $0.entryID == id }
        guard let index = index else { return surrounding }
        
        
        if (self.indices.contains(index - 1)) {
            surrounding.prevJob = self[index - 1].entryID
        }

        
        if (self.indices.contains(index + 1)) {
            surrounding.nextJob = self[index + 1].entryID
        }
       
        
        return surrounding
    }
}





