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
    
    private init() {}  // Prevents outside instantiation
}
