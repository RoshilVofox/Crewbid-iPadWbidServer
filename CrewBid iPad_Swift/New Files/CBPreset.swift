//
//  CBPreset.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/07/25.
//

import Foundation

let CBPresetEntityName = "Preset"

class CBPreset: NSObject, NSCoding {
    
    var lineSorts: [CBPresetLineSort] = []
    var filterRules: [CBPresetFilterRule] = []
    var lineValues: [Any] = []
    
    var month: NSNumber?
    var year: NSNumber?
    var position: NSNumber?
    
    var name: String?
    var presetIdentifier: String?
    var appVersion: String?
    
    var selected: NSNumber?
    var commutabilityFilterDetails: NSMutableDictionary?
    var commutabilitySortDetails: NSMutableDictionary?
    var commuteTimeDetails: NSMutableArray?
    var overnight: NSMutableArray?
    
    var isRedEyeFilterAdded: NSNumber?
    
    init(rules: [BIFilterRule], sorts: [BILineSort], lineValues: [Any], name pname: String) {
        super.init()
        self.filterRules = rules.enumerated().map { index, rule in
            CBPresetFilterRule(filterRule: rule)
        }
        self.lineSorts = sorts.map { CBPresetLineSort(sort: $0) }
        self.lineValues = lineValues
        self.name = pname
        self.presetIdentifier = CBUtils.generateUniqueIdentifier()
    }
    
    required override init() {
        super.init()
    }
    
    // MARK: - NSCoding
    
    func encode(with coder: NSCoder) {
        coder.encode(lineSorts, forKey: "lineSorts")
        coder.encode(filterRules, forKey: "filterRules")
        coder.encode(lineValues, forKey: "lineValues")
        coder.encode(month, forKey: "month")
        coder.encode(year, forKey: "year")
        coder.encode(position, forKey: "position")
        coder.encode(name, forKey: "name")
        coder.encode(selected, forKey: "selected")
        coder.encode(presetIdentifier, forKey: "presetIdentifier")
        coder.encode(appVersion, forKey: "appVersion")
        coder.encode(commutabilityFilterDetails, forKey: "commutabilityFilterDetails")
        coder.encode(commutabilitySortDetails, forKey: "commutabilitySortDetails")
        coder.encode(commuteTimeDetails, forKey: "commuteTimeDetails")
        coder.encode(overnight, forKey: "overnight")
    }
    
    required init?(coder decoder: NSCoder) {
        self.lineSorts = decoder.decodeObject(forKey: "lineSorts") as? [CBPresetLineSort] ?? []
        self.filterRules = decoder.decodeObject(forKey: "filterRules") as? [CBPresetFilterRule] ?? []
        self.lineValues = decoder.decodeObject(forKey: "lineValues") as? [Any] ?? []
        self.month = decoder.decodeObject(forKey: "month") as? NSNumber
        self.year = decoder.decodeObject(forKey: "year") as? NSNumber
        self.position = decoder.decodeObject(forKey: "position") as? NSNumber
        self.name = decoder.decodeObject(forKey: "name") as? String
        self.selected = decoder.decodeObject(forKey: "selected") as? NSNumber
        self.presetIdentifier = decoder.decodeObject(forKey: "presetIdentifier") as? String
        self.appVersion = decoder.decodeObject(forKey: "appVersion") as? String
        self.commutabilityFilterDetails = decoder.decodeObject(forKey: "commutabilityFilterDetails") as? NSMutableDictionary
        self.commutabilitySortDetails = decoder.decodeObject(forKey: "commutabilitySortDetails") as? NSMutableDictionary
        self.commuteTimeDetails = decoder.decodeObject(forKey: "commuteTimeDetails") as? NSMutableArray
        self.overnight = decoder.decodeObject(forKey: "overnight") as? NSMutableArray
    }
}
