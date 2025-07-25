//
//  CBPresetFilterRule.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/07/25.
//

import Foundation

let CBPresetFilterRuleEntityName = "PresetFilterRule"

class CBPresetFilterRule: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool { true }

    var abbreviation: String?
    var category: NSNumber?
    var type: NSNumber?
    var name: String?
    var keyPath: String?
    var comparison: NSNumber?
    var variables: [String: Any]?

    init(filterRule: BIFilterRule) {
        self.abbreviation = filterRule.abbreviation
        self.category = filterRule.category
        self.type = filterRule.type
        self.name = filterRule.name
        self.keyPath = filterRule.keyPath
        self.comparison = filterRule.comparison

        var filterVars = filterRule.variables ?? [:]
        // If needed, remove specific keys like:
        // filterVars.removeValue(forKey: "SET")
        self.variables = filterVars as? [String : Any]
    }

    required override init() {
        super.init()
    }

    required init?(coder: NSCoder) {
        self.abbreviation = coder.decodeObject(forKey: "abbreviation") as? String
        self.category = coder.decodeObject(forKey: "category") as? NSNumber
        self.type = coder.decodeObject(forKey: "type") as? NSNumber
        self.name = coder.decodeObject(forKey: "name") as? String
        self.keyPath = coder.decodeObject(forKey: "keyPath") as? String
        self.comparison = coder.decodeObject(forKey: "comparison") as? NSNumber
        self.variables = coder.decodeObject(forKey: "variables") as? [String: Any]
    }

    func encode(with coder: NSCoder) {
        coder.encode(abbreviation, forKey: "abbreviation")
        coder.encode(category, forKey: "category")
        coder.encode(type, forKey: "type")
        coder.encode(name, forKey: "name")
        coder.encode(keyPath, forKey: "keyPath")
        coder.encode(comparison, forKey: "comparison")
        coder.encode(variables, forKey: "variables")
    }
}
