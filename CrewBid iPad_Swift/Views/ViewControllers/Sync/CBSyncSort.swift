//
//  CBSyncSort.swift
//  CrewBid iPad_Swift
//
//  Created by Rishad on 02/11/25.
//
import UIKit
import Foundation

class CBSyncSort: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool = true
    
    var category: NSNumber?
    var type: NSNumber?
    var name: String?
    var keyPath: String?
    var abbreviation: String?
    var ascending: NSNumber?
    var isMutable: NSNumber?
    var city: String?
    var expression: String?
    var order: NSNumber?
    var variables: [String: Any]?
    var arrayVariables: [Any]?

    init(sort: BILineSort) {
        self.category = sort.category
        self.type = sort.type
        self.name = sort.name
        self.keyPath = sort.keyPath
        self.abbreviation = sort.abbreviation
        self.ascending = sort.ascending
        self.isMutable = sort.isMutable
        self.city = sort.city
        self.expression = sort.expression
        self.order = sort.order
        self.arrayVariables = sort.arrayVariables as? [Any]
        if let cat = sort.category?.intValue, let t = sort.type?.intValue {
            if cat == BILineSortCategory.BIFlagLineSortCategory.rawValue ||
                cat == BILineSortCategory.BICommutingLineSortCategory.rawValue ||
                cat == BILineSortCategory.BIDaysOffLineSortCategory.rawValue ||
                cat == BILineSortCategory.BIDaysWorkLineSortCategory.rawValue ||
                cat == BILineSortCategory.BIDaysTripStartSortCategory.rawValue ||
                (cat == BILineSortCategory.BICitiesLineSortCategory.rawValue &&
                 [BICityLineSortType.BICitiesLineSortTypeEastCoast.rawValue,
                  BICityLineSortType.BICitiesLineSortTypeWestCoast.rawValue,
                  BICityLineSortType.BICitiesLineSortTypeNonConus.rawValue,
                  BICityLineSortType.BICitiesLineSortTypeIntl.rawValue,
                  BICityLineSortType.BICitiesLineSortTypeAll.rawValue,
                  BICityLineSortType.BICitiesLineSortTypeHawaii.rawValue].contains(t))
            {
                self.variables = sort.variables as? [String : Any]
            }
        }
    }

    func encode(with coder: NSCoder) {
        coder.encode(category, forKey: "category")
        coder.encode(type, forKey: "type")
        coder.encode(name, forKey: "name")
        coder.encode(keyPath, forKey: "keyPath")
        coder.encode(abbreviation, forKey: "abbreviation")
        coder.encode(ascending, forKey: "ascending")
        coder.encode(isMutable, forKey: "isMutable")
        coder.encode(city, forKey: "city")
        coder.encode(expression, forKey: "expression")
        coder.encode(order, forKey: "order")
        coder.encode(arrayVariables, forKey: "arrayVariables")
        coder.encode(variables, forKey: "variables")
    }

    required init?(coder: NSCoder) {
        category = coder.decodeObject(forKey: "category") as? NSNumber
        type = coder.decodeObject(forKey: "type") as? NSNumber
        name = coder.decodeObject(forKey: "name") as? String
        keyPath = coder.decodeObject(forKey: "keyPath") as? String
        abbreviation = coder.decodeObject(forKey: "abbreviation") as? String
        ascending = coder.decodeObject(forKey: "ascending") as? NSNumber
        isMutable = coder.decodeObject(forKey: "isMutable") as? NSNumber
        city = coder.decodeObject(forKey: "city") as? String
        expression = coder.decodeObject(forKey: "expression") as? String
        order = coder.decodeObject(forKey: "order") as? NSNumber
        arrayVariables = coder.decodeObject(forKey: "arrayVariables") as? [Any]
        variables = coder.decodeObject(forKey: "variables") as? [String: Any]
    }
}

