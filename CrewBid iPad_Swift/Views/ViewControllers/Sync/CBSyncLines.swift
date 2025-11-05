//
//  CBSyncLines.swift
//  CrewBid iPad_Swift
//
//  Created by Rishad on 02/11/25.
//

import UIKit

import Foundation

class CBSyncLines: NSObject, NSSecureCoding {
    
    static var supportsSecureCoding: Bool { return true }
    
    var bidOrder: NSNumber?
    var isFrozen: NSNumber?
    var number: NSNumber?
    var markerTitle: String?
    var faBidLineReserve: NSNumber?
    var faBidLineMrt: NSNumber?
    var faPosition: NSNumber?
    var faPositionString: String?
    var userFlagType: NSNumber?
    var isTrashed: NSNumber?
    
    // MARK: - Initializer from BILine
    init(lines: BILine) {
        self.bidOrder = lines.bidOrder
        self.isFrozen = lines.isFrozen
        self.number = lines.number
        self.markerTitle = lines.markerTitle
        self.faBidLineReserve = lines.faBidLineReserve
        self.faBidLineMrt = lines.faBidLineMrt
        self.faPosition = lines.faPosition
        self.faPositionString = lines.faPositionString
        self.userFlagType = lines.userFlagType
        self.isTrashed = lines.isTrashed
    }
    
    // MARK: - NSSecureCoding
    
    func encode(with coder: NSCoder) {
        coder.encode(bidOrder, forKey: "bidOrder")
        coder.encode(isFrozen, forKey: "isFrozen")
        coder.encode(number, forKey: "number")
        coder.encode(markerTitle, forKey: "markerTitle")
        coder.encode(faBidLineReserve, forKey: "faBidLineReserve")
        coder.encode(faBidLineMrt, forKey: "faBidLineMrt")
        coder.encode(faPosition, forKey: "faPosition")
        coder.encode(faPositionString, forKey: "faPositionString")
        coder.encode(userFlagType, forKey: "userFlagType")
        coder.encode(isTrashed, forKey: "isTrashed")
    }
    
    required init?(coder: NSCoder) {
        self.bidOrder = coder.decodeObject(of: NSNumber.self, forKey: "bidOrder")
        self.isFrozen = coder.decodeObject(of: NSNumber.self, forKey: "isFrozen")
        self.number = coder.decodeObject(of: NSNumber.self, forKey: "number")
        self.markerTitle = coder.decodeObject(of: NSString.self, forKey: "markerTitle") as String?
        self.faBidLineReserve = coder.decodeObject(of: NSNumber.self, forKey: "faBidLineReserve")
        self.faBidLineMrt = coder.decodeObject(of: NSNumber.self, forKey: "faBidLineMrt")
        self.faPosition = coder.decodeObject(of: NSNumber.self, forKey: "faPosition")
        self.faPositionString = coder.decodeObject(of: NSString.self, forKey: "faPositionString") as String?
        self.userFlagType = coder.decodeObject(of: NSNumber.self, forKey: "userFlagType")
        self.isTrashed = coder.decodeObject(of: NSNumber.self, forKey: "isTrashed")
    }
}
