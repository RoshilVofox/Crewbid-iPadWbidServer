//
//  CBPresetLineSort.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/07/25.
//

import Foundation

let CBPresetLineSortEntityName = "PresetLineSort"

class CBPresetLineSort: NSObject, NSCoding {
    
    var category: NSNumber?
    var type: NSNumber?
    var name: String?
    var keyPath: String?
    var ascending: NSNumber?
    var isMutable: NSNumber?
    var city: String?
    var expression: String?
    var order: NSNumber?
    var abbreviation: String?
    var variables: [String: Any]?
    var lineSortKeyMap: BILineSortKeyMap?
    var isBidListSort: NSNumber?
    var arrayVariables: NSMutableArray?

    override init() {
        super.init()
    }

    init(sort: BILineSort) {
        self.category = sort.category
        self.type = sort.type
        self.name = sort.name
        self.keyPath = sort.keyPath
        self.ascending = sort.ascending
        self.isMutable = sort.isMutable
        self.city = sort.city
        self.expression = sort.expression
        self.order = sort.order
        self.abbreviation = sort.abbreviation
        self.isBidListSort = sort.isBidListSort
        self.variables = sort.variables as? [String : Any]
        self.arrayVariables = sort.arrayVariables as? NSMutableArray
        self.lineSortKeyMap = sort.lineSortKeyMap

        if let cat = sort.category?.intValue,
           let typ = sort.type?.intValue,
           cat == BILineSortCategory.BICommutingLineSortCategory.rawValue ||
            cat == BILineSortCategory.BIDaysOffLineSortCategory.rawValue ||
            cat == BILineSortCategory.BIDaysWorkLineSortCategory.rawValue ||
            cat == BILineSortCategory.BIDaysTripStartSortCategory.rawValue ||
            (cat == BILineSortCategory.BICitiesLineSortCategory.rawValue &&
             (typ == BICityLineSortType.BICitiesLineSortTypeEastCoast.rawValue ||
              typ == BICityLineSortType.BICitiesLineSortTypeWestCoast.rawValue ||
              typ == BICityLineSortType.BICitiesLineSortTypeNonConus.rawValue ||
              typ == BICityLineSortType.BICitiesLineSortTypeIntl.rawValue ||
              typ == BICityLineSortType.BICitiesLineSortTypeAll.rawValue ||
              typ == BICityLineSortType.BICitiesLineSortTypeHawaii.rawValue)) {
            self.variables = sort.variables as? [String : Any]
        }
    }

    // MARK: - NSCoding

    func encode(with coder: NSCoder) {
        coder.encode(category, forKey: "category")
        coder.encode(type, forKey: "type")
        coder.encode(name, forKey: "name")
        coder.encode(keyPath, forKey: "keyPath")
        coder.encode(ascending, forKey: "ascending")
        coder.encode(isMutable, forKey: "isMutable")
        coder.encode(city, forKey: "city")
        coder.encode(expression, forKey: "expression")
        coder.encode(order, forKey: "order")
        coder.encode(abbreviation, forKey: "abbreviation")
        coder.encode(isBidListSort, forKey: "isBidListSort")
        if let vars = variables {
            coder.encode(vars, forKey: "variables")
        }
    }

    required init?(coder decoder: NSCoder) {
        category = decoder.decodeObject(forKey: "category") as? NSNumber
        type = decoder.decodeObject(forKey: "type") as? NSNumber
        name = decoder.decodeObject(forKey: "name") as? String
        keyPath = decoder.decodeObject(forKey: "keyPath") as? String
        ascending = decoder.decodeObject(forKey: "ascending") as? NSNumber
        isMutable = decoder.decodeObject(forKey: "isMutable") as? NSNumber
        city = decoder.decodeObject(forKey: "city") as? String
        expression = decoder.decodeObject(forKey: "expression") as? String
        order = decoder.decodeObject(forKey: "order") as? NSNumber
        abbreviation = decoder.decodeObject(forKey: "abbreviation") as? String
        isBidListSort = decoder.decodeObject(forKey: "isBidListSort") as? NSNumber
        variables = decoder.decodeObject(forKey: "variables") as? [String: Any]
    }
}
