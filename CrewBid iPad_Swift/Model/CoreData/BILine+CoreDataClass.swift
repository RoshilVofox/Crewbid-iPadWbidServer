//
//  BILine+CoreDataClass.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/03/25.
//
//

import Foundation
import CoreData

@objc(BILine)
public class BILine: NSManagedObject {

}

@objc enum BILineType : Int {
    case BIHardLineType              // 0
    case BILineTypeHardConus         // 1
    case BILineTypeHardNonConus      // 2
    case BIReserveLineType           // 3
    case BIBlankLineType             // 4
    case BIMixedLineType             // 5
    case BILineTypeNonEtopsReserve   // 6
    case BILineTypeNonEtopsNonConUs  // 7
    case BILineTypeNonEtopsConUs     // 8
    case BILineTypeNonReserveEtops   // 9
    case BILineTypeNonEtopsHard      // 10
    case BILineTypeNonEtopsMixed     // 11
    case BILineTypeEtopsReserve      // 12
    case BILineTypeEtopsFAFirstRound // 13
    
    func name () -> Int {
        switch self {
        case .BIHardLineType: return 0
        case .BILineTypeHardConus: return 1
        case .BILineTypeHardNonConus: return 2
        case .BIReserveLineType: return 3
        case .BIBlankLineType: return 4
        case .BIMixedLineType: return 5
        case .BILineTypeNonEtopsReserve: return 6
        case .BILineTypeNonEtopsNonConUs: return 7
        case .BILineTypeNonEtopsConUs: return 8
        case .BILineTypeNonReserveEtops: return 9
        case .BILineTypeNonEtopsHard: return 10
        case .BILineTypeNonEtopsMixed: return 11
        case .BILineTypeEtopsReserve: return 12
        case .BILineTypeEtopsFAFirstRound: return 13
        }
    }
}
// Enumeration for FA Reserve Line Types

@objc enum BIFaReserveLineType : Int {
    case BIFaReserveLineTypeNoType
    case BIFaReserveLineTypeSnrAMres
    case BIFaReserveLineTypeSnrPMres
    case BIFaReserveLineTypeJnrAMres
    case BIFaReserveLineTypeJnrPMres
    case BIFaReserveLineTypeJnrLateRes
    
    func name () -> Int {
        switch self
        {
        case .BIFaReserveLineTypeNoType: return 0
        case .BIFaReserveLineTypeSnrAMres: return 1
        case .BIFaReserveLineTypeSnrPMres: return 2
        case .BIFaReserveLineTypeJnrAMres: return 3
        case .BIFaReserveLineTypeJnrPMres: return 4
        case .BIFaReserveLineTypeJnrLateRes: return 5
            
        }
    }
}

// Enumeration for Trip Length Types

@objc enum BITripLengthType : Int {
    case BITripLengthTypeNoType
    case BITurnsButtonType
    case BITwoDaysButtonType
    case BIThreeDaysButtonType
    case BIFourDaysButtonType
    
    func name () -> Int {
        switch self {
        case .BITripLengthTypeNoType: return 0
        case .BITurnsButtonType: return 1
        case .BITwoDaysButtonType: return 2
        case .BIThreeDaysButtonType: return 3
        case .BIFourDaysButtonType: return 4
        }
    }
}
// Enumeration for AM/PM Line Types

@objc enum BILineAmPm : Int {
    case BIAmLine
    case BIMixedAmPmLine
    case BIPmLine
    case BIBlankAmPmLine
    case BIRedEyeAmPmLine
    func name () -> Int {
        switch self {
        case .BIAmLine: return 0
        case .BIMixedAmPmLine: return 1
        case .BIPmLine: return 2
        case .BIBlankAmPmLine: return 3
        case .BIRedEyeAmPmLine : return 4
        }
    }
}
// Enumeration for FA Positions

@objc enum BIFaPosition : Int {
    case BIFaPositionA = 1
    case BIFaPositionB
    case BIFaPositionC
    case BIFaPositionD
    case BIFaPositionMultiple
    case BIFaPositionNA
    
    func name() -> Int {
        switch self {
        case .BIFaPositionA: return 1
        case .BIFaPositionB: return 2
        case .BIFaPositionC: return 3
        case .BIFaPositionD: return 4
        case .BIFaPositionMultiple: return 5
        case .BIFaPositionNA: return 6
        }
    }
}
// Enumeration for FA Bid Line Types

@objc enum BIFaBidLineType : Int {
    case BIFaBidLineTypeNormal
    case BIFaBidLineTypeReserve
    case BIFaBidLineTypeMrt
    
    func name() -> Int {
        switch self {
        case .BIFaBidLineTypeNormal: return 0
        case .BIFaBidLineTypeReserve: return 1
        case .BIFaBidLineTypeMrt: return 2
        }
    }
}
