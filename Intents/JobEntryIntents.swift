//
//  JobEntryIntents.swift
//  WorkTracker
//
//  Created by Hayden Steele on 6/23/24.
//

import Foundation
import AppIntents


// Job History Related Items
struct JobEntryEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Job Entry")

    @Property(title: "Job Type")
    var jobID : String
    
    @Property(title: "Start Time")
    var startTime : Date
    
    @Property(title: "End Time")
    var endTime : Date
    
    @Property(title: "Description")
    var desc : String
    
    static var defaultQuery = JobEntryEntityQuery()

    // Provide an identifier for the entity
    var id: UUID

    // Define display representation for the entity
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: LocalizedStringResource(
                stringLiteral: getJobFromID(id: jobID).rawValue
                + " - "
                + startTime.toHeaderText()
            ),
            subtitle: LocalizedStringResource(
                stringLiteral: startTime.getTimeText()
                + " - "
                + endTime.getTimeText()
                + " > "
                + startTime.hrsOffset(relativeTo: endTime)
                + "\n" + desc
            ),
            image: DisplayRepresentation.Image(
                systemName: "deskclock"
            )
        )
    }
}



extension [JobEntry] {
    func toIntentEntities() -> [JobEntryEntity] {
        var entities : [JobEntryEntity] = []
        for entry in self {
            let entity = JobEntryEntity(id: entry.entryID)
            
            entity.jobID = entry.jobTypeID
            entity.startTime = entry.startTime
            entity.endTime = entry.endTime
            entity.desc = entry.desc
            
            entities.append(entity)
        }
        
        return entities
    }
}


struct JobEntryEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [JobEntryEntity] {
        print("Query for Job Entries: \(identifiers)")
    
        var entities: [JobEntry] = []
        for identifier in identifiers {
            entities.append(
                try DataStorageSystem.shared.fetchJobEntry(uuid: identifier)
            )
        }
        
        return entities.toIntentEntities()
    }

    func suggestedEntities() async throws -> [JobEntryEntity] {
      
        return DataStorageSystem.shared.fetchSuggestedEntries().toIntentEntities()
    }
    
    func allEntities() async throws -> [JobEntryEntity] {
        
        return DataStorageSystem.shared.fetchAllJobEntries().toIntentEntities()
    }
}


struct GetJobEntriesInPayPeriodIntent : AppIntent {
    static var title: LocalizedStringResource = "Get Job Entries in Pay Period"
    static var description = IntentDescription("Fetches all job entries in a pay period")
    static var openAppWhenRun: Bool = false
    static var parameterSummary: some ParameterSummary {
        Summary("Get all job entries in the \(\.$payPeriod) pay period.")
    }
    
    @Parameter(title: "Pay Period", description: "The Pay Period to be exported")
    var payPeriod: PayPeriod

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[JobEntryEntity]> {
    
        return .result(
            value: DataStorageSystem.shared.fetchJobEntries(dateRange: payPeriod.range).toIntentEntities()
        )
        
    }
}










// Export Pay Period Intent
extension PayPeriod : AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Pay Period")
    static var defaultQuery = PayPeriodQuery()
    var id: String { self.toString(full: true, fileSafe: true) }
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: LocalizedStringResource(
                stringLiteral: self.isCurrent ? "Current" : self.toString()
            ),
            subtitle: LocalizedStringResource(
                stringLiteral: self.isCurrent ? self.toString() : ""
            ),
            image: DisplayRepresentation.Image(
                systemName: "calendar"
            )
        )
    }
    
    
}
struct PayPeriodQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [PayPeriod] {
        print("Query for Pay Periods: \(identifiers)")
        
        var periods : [PayPeriod] = []
        for identifier in identifiers {
            periods.append(PayPeriod(entityID: identifier))
        }
        return periods
    }

    func suggestedEntities() async throws -> [PayPeriod] {
        return DataStorageSystem.shared.fetchPayPeriods()
    }

}


struct GetCurrentPayPeriodIntent : AppIntent {
    static var title: LocalizedStringResource = "Get Current Pay Period"
    static var description = IntentDescription("Returns the current pay period")
    static var openAppWhenRun: Bool = false
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<PayPeriod> {
        return .result(value: getCurrentPayperiod())
        
    }
}

struct ExportPayPeriodIntent : AppIntent {
    static var title: LocalizedStringResource = "Export Pay Period"
    static var description = IntentDescription("Exports the pay period to a .pdf")
    static var openAppWhenRun: Bool = false
    static var parameterSummary: some ParameterSummary {
        Summary("Export \(\.$payPeriod) pay period.")
    }
    
    @Parameter(title: "Pay Period", description: "The Pay Period to be exported")
    var payPeriod: PayPeriod
    
    @Parameter(title: "Include Descriptions", description: "Include job descriptions in the exporded file.")
    var includeDescs : Bool
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        
        let entries = DataStorageSystem.shared.fetchJobEntries(dateRange: payPeriod.range)
        
        let url = createTimeCardPDF(
            entries: entries,
            payperiod: payPeriod,
            showingDesc: includeDescs
        )
        
        return .result(value: IntentFile(fileURL: url))
        
    }
}



