//
//  CBSync.swift
//  CrewBid iPad_Swift
//
//  Created by Rishad on 02/11/25.
//

import UIKit

import Foundation

class CBSync: NSObject, NSSecureCoding {
    // MARK: - Secure Coding
    static var supportsSecureCoding: Bool { true }

    // MARK: - Properties
    var lineSorts: NSMutableArray = []
    var filterRules: NSMutableArray = []
    var lines: NSMutableArray = []
    var linesFA: NSMutableArray = []
    var overnightBulkCities: NSMutableArray = []
    var vacationDetails: NSMutableDictionary = [:]
    var commutabilityFilterDetails: NSMutableDictionary = [:]
    var commutabilitySortDetails: NSMutableDictionary = [:]
    var commuteTimeDetails: NSMutableArray = []
    var insertionPoint: NSMutableDictionary = [:]
    var bidPeriod: BIBidPeriod?

    // MARK: - Initializers
    override init() {
        super.init()
    }

    init(
        filterRules rules: [BIFilterRule],
        sorts: [BILineSort],
        lineValues values: [BILine],
        vacationDetails details: [String: Any],
        overnightBulkDetails bulkDetails: [Any],
        insertion points: [String: Any]
    ) {
        super.init()

        // Convert filter rules → CBSyncFilter
        self.filterRules = NSMutableArray(capacity: rules.count)
        for rule in rules {
            let syncRule = CBSyncFilter(filterRule: rule)
            self.filterRules.add(syncRule)
        }

        // Convert sorts → CBSyncSort
        self.lineSorts = NSMutableArray(capacity: sorts.count)
        for sort in sorts {
            let syncSort = CBSyncSort(sort: sort)
            self.lineSorts.add(syncSort)
        }

        // Convert lines → CBSyncLines
        self.lines = NSMutableArray(capacity: values.count)
        for line in values {
            let syncLine = CBSyncLines(lines: line)
            self.lines.add(syncLine)
        }

        // Copy other structures
        self.insertionPoint = NSMutableDictionary(dictionary: points)
        self.overnightBulkCities = NSMutableArray(array: bulkDetails)
        self.vacationDetails = NSMutableDictionary(dictionary: details)
    }

    // MARK: - NSSecureCoding
    required init?(coder aDecoder: NSCoder) {
        super.init()
        lineSorts = aDecoder.decodeObject(of: [NSMutableArray.self, CBSyncSort.self], forKey: "lineSorts") as? NSMutableArray ?? []
        filterRules = aDecoder.decodeObject(of: [NSMutableArray.self, CBSyncFilter.self], forKey: "filterRules") as? NSMutableArray ?? []
        lines = aDecoder.decodeObject(of: [NSMutableArray.self, CBSyncLines.self], forKey: "lines") as? NSMutableArray ?? []
        vacationDetails = aDecoder.decodeObject(of: NSMutableDictionary.self, forKey: "VacationDetails") ?? [:]
        overnightBulkCities = aDecoder.decodeObject(of: NSMutableArray.self, forKey: "OvernightBulkCities") ?? []
        commutabilityFilterDetails = aDecoder.decodeObject(of: NSMutableDictionary.self, forKey: "commutabilityFilterDetails") ?? [:]
        commutabilitySortDetails = aDecoder.decodeObject(of: NSMutableDictionary.self, forKey: "commutabilitySortDetails") ?? [:]
        commuteTimeDetails = aDecoder.decodeObject(of: NSMutableArray.self, forKey: "commuteTimeDetails") ?? []
        insertionPoint = aDecoder.decodeObject(of: NSMutableDictionary.self, forKey: "insertionPoint") ?? [:]
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(lineSorts, forKey: "lineSorts")
        aCoder.encode(filterRules, forKey: "filterRules")
        aCoder.encode(lines, forKey: "lines")
        aCoder.encode(vacationDetails, forKey: "VacationDetails")
        aCoder.encode(overnightBulkCities, forKey: "OvernightBulkCities")
        aCoder.encode(commutabilityFilterDetails, forKey: "commutabilityFilterDetails")
        aCoder.encode(commutabilitySortDetails, forKey: "commutabilitySortDetails")
        aCoder.encode(commuteTimeDetails, forKey: "commuteTimeDetails")
        aCoder.encode(insertionPoint, forKey: "insertionPoint")
    }
}
