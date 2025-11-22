//
//  SeniorityList+CoreDataProperties.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 15/11/25.
//
//

public import Foundation
public import CoreData


public typealias SeniorityListCoreDataPropertiesSet = NSSet

extension SeniorityList {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SeniorityList> {
        return NSFetchRequest<SeniorityList>(entityName: "SeniorityList")
    }

    @NSManaged public var base: String?
    @NSManaged public var baseSeniority: NSNumber?
    @NSManaged public var companySeniority: NSNumber?
    @NSManaged public var department: String?
    @NSManaged public var employeeId: String?
    @NSManaged public var legalName: String?
    @NSManaged public var lodoQualification: String?
    @NSManaged public var vacation: String?
    @NSManaged public var bidPeriod: BIBidPeriod?

}

extension SeniorityList : Identifiable {
    var vacationString: String {
        guard let vacation = self.vacation, !vacation.isEmpty else {
            return "N/A"
        }
        
        guard let jsonData = vacation.data(using: .utf8) else {
            return "Invalid"
        }
        
        let jsonObject: Any
        do {
            jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
        } catch {
            return "Invalid"
        }
        
        var formattedString = ""
        
        if let vacations = jsonObject as? [[String: Any]] {
            if let first = vacations.first {
                let fromStr = first["from"] as? String ?? ""
                let toStr = first["to"] as? String ?? ""

                let inputFormatter = DateFormatter()
                inputFormatter.dateFormat = "yyyy-MM-dd"

                let outputFormatter = DateFormatter()
                outputFormatter.dateFormat = "M/dd"

                let fromDate = inputFormatter.date(from: fromStr)
                let toDate = inputFormatter.date(from: toStr)

                let separator = formattedString.isEmpty ? "" : "; "

                if let fromDate = fromDate, let toDate = toDate {
                    let formattedFrom = outputFormatter.string(from: fromDate)
                    let formattedTo = outputFormatter.string(from: toDate)
                    formattedString = "VAC\(formattedFrom)-\(formattedTo)\(separator)"
                } else {
                    formattedString = "Invalid Dates\(separator)"
                }
            } else {
                formattedString = "Empty"
            }
        } else {
            formattedString = "Unknown Format"
        }

        return formattedString
    }
}
