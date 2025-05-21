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

enum BILineType : Int {
    case HardLineType              // 0
    case LineTypeHardConus         // 1
    case LineTypeHardNonConus      // 2
    case ReserveLineType           // 3
    case BlankLineType             // 4
    case MixedLineType             // 5
    case LineTypeNonEtopsReserve   // 6
    case LineTypeNonEtopsNonConUs  // 7
    case LineTypeNonEtopsConUs     // 8
    case LineTypeNonReserveEtops   // 9
    case LineTypeNonEtopsHard      // 10
    case LineTypeNonEtopsMixed     // 11
    case LineTypeEtopsReserve      // 12
    case LineTypeEtopsFAFirstRound // 13
    
    func name () -> Int {
        switch self {
        case .HardLineType: return 0
        case .LineTypeHardConus: return 1
        case .LineTypeHardNonConus: return 2
        case .ReserveLineType: return 3
        case .BlankLineType: return 4
        case .MixedLineType: return 5
        case .LineTypeNonEtopsReserve: return 6
        case .LineTypeNonEtopsNonConUs: return 7
        case .LineTypeNonEtopsConUs: return 8
        case .LineTypeNonReserveEtops: return 9
        case .LineTypeNonEtopsHard: return 10
        case .LineTypeNonEtopsMixed: return 11
        case .LineTypeEtopsReserve: return 12
        case .LineTypeEtopsFAFirstRound: return 13
        }
    }
}
// Enumeration for FA Reserve Line Types

enum BIFaReserveLineType : Int {
    case NoType
    case SnrAMres
    case SnrPMres
    case JnrAMres
    case JnrPMres
    case JnrLateRes
    
    func name () -> Int {
        switch self
        {
        case .NoType: return 0
        case .SnrAMres: return 1
        case .SnrPMres: return 2
        case .JnrAMres: return 3
        case .JnrPMres: return 4
        case .JnrLateRes: return 5
            
        }
    }
}

// Enumeration for Trip Length Types

enum BITripLengthType : Int {
    case NoType
    case TurnsButtonType
    case TwoDaysButtonType
    case ThreeDaysButtonType
    case FourDaysButtonType
    
    func name () -> Int {
        switch self {
        case .NoType: return 0
        case .TurnsButtonType: return 1
        case .TwoDaysButtonType: return 2
        case .ThreeDaysButtonType: return 3
        case .FourDaysButtonType: return 4
        }
    }
}
// Enumeration for AM/PM Line Types

enum BILineAMPM : Int {
    case AMLine
    case MixedAMPMLine
    case PMLine
    case BlankAMPMLine
    case RedEyeAMPMLine
    func name () -> Int {
        switch self {
        case .AMLine: return 0
        case .MixedAMPMLine: return 1
        case .PMLine: return 2
        case .BlankAMPMLine: return 3
        case .RedEyeAMPMLine : return 4
        }
    }
}
// Enumeration for FA Positions

enum BIFaPosition : Int {
    case FaPositionA = 1
    case FaPositionB
    case FaPositionC
    case FaPositionD
    case FaPositionMultiple
    case FaPositionNA
    
    func name() -> Int {
        switch self {
        case .FaPositionA: return 1
        case .FaPositionB: return 2
        case .FaPositionC: return 3
        case .FaPositionD: return 4
        case .FaPositionMultiple: return 5
        case .FaPositionNA: return 6
        }
    }
}
// Enumeration for FA Bid Line Types

 enum BIFaBidLineType : Int {
    case Normal
    case Reserve
    case Mrt
    
    func name() -> Int {
        switch self {
        case .Normal: return 0
        case .Reserve: return 1
        case .Mrt: return 2
        }
    }
}
