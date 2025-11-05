//
//  CBSyncFilter.swift
//  CrewBid iPad_Swift
//
//  Created by Rishad on 02/11/25.
//

import UIKit

import Foundation

class CBSyncFilter: NSObject, NSSecureCoding {
    // MARK: - Secure Coding
    static var supportsSecureCoding: Bool { true }

    // MARK: - Properties
    var category: NSNumber?
    var type: NSNumber?
    var name: String?
    var keyPath: String?
    var abbreviation: String?
    var comparison: NSNumber?
    var variables: NSDictionary?

    // MARK: - Initializers
    override init() {
        super.init()
    }

    init(filterRule: BIFilterRule) {
        super.init()
        self.abbreviation = filterRule.abbreviation
        self.category = filterRule.category
        self.type = filterRule.type
        self.name = filterRule.name
        self.keyPath = filterRule.keyPath
        self.comparison = filterRule.comparison

        // Copy variables to ensure immutability like NSDictionary
        let filterVars = NSMutableDictionary(dictionary: filterRule.variables ?? [:])
        self.variables = NSDictionary(dictionary: filterVars)
    }

    // MARK: - NSSecureCoding
    required init?(coder aDecoder: NSCoder) {
        abbreviation = aDecoder.decodeObject(of: NSString.self, forKey: "abbreviation") as String?
        category = aDecoder.decodeObject(of: NSNumber.self, forKey: "category")
        type = aDecoder.decodeObject(of: NSNumber.self, forKey: "type")
        name = aDecoder.decodeObject(of: NSString.self, forKey: "name") as String?
        keyPath = aDecoder.decodeObject(of: NSString.self, forKey: "keyPath") as String?
        comparison = aDecoder.decodeObject(of: NSNumber.self, forKey: "comparison")
        variables = aDecoder.decodeObject(of: NSDictionary.self, forKey: "variables")
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(abbreviation, forKey: "abbreviation")
        aCoder.encode(category, forKey: "category")
        aCoder.encode(type, forKey: "type")
        aCoder.encode(name, forKey: "name")
        aCoder.encode(keyPath, forKey: "keyPath")
        aCoder.encode(comparison, forKey: "comparison")
        aCoder.encode(variables, forKey: "variables")
    }
}
