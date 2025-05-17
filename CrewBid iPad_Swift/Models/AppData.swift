//
//  AppData.swift
//  CrewBid iPad_Swift
//
//  Created by Developer on 04/05/25.
//

import Foundation



class AppData {
    static let shared = AppData()  // Shared instance

    var isBidListSort: Bool = false
    var isSyncOn: Bool = false
    
    var filtersToBeAddedInTable = [
        ["category": 0, "type": 0, "title": ""],
        ["category": 1, "type": 0, "title": ""],
        ["category": 4, "type": 0, "title": ""],
        ["category": 5, "type": 0, "title": ""],
//        ["category": 6, "type": 0]
    ]
    
    var sortsToBeAddedInTable: [[String: Any]] = []
    
    var postion = "FA"
    var Round = 1

    
    private init() {}  // Prevents outside instantiation
}
