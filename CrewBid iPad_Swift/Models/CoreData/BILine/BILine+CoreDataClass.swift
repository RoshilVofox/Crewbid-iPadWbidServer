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
    case HardLine           // 0
    case HardConUS          // 1
    case HardNonConUS       // 2
    case ReserveLine        // 3
    case BlankLine          // 4
    case MixedLine          // 5
    case NonEtopsReserve    // 6
    case NonEtopsNonConUS   // 7
    case NonEtopsConUS      // 8
    case NonReserveEtops    // 9
    case NonEtopsHard       // 10
    case NonEtopsMixed      // 11
    case EtopsReserve       // 12
    case EtopsFAFirstRound  // 13
    case BILineTypeLoDo     // 14
    
    func name () -> Int {
        switch self {
        case .HardLine: return 0
        case .HardConUS: return 1
        case .HardNonConUS: return 2
        case .ReserveLine: return 3
        case .BlankLine: return 4
        case .MixedLine: return 5
        case .NonEtopsReserve: return 6
        case .NonEtopsNonConUS: return 7
        case .NonEtopsConUS: return 8
        case .NonReserveEtops: return 9
        case .NonEtopsHard: return 10
        case .NonEtopsMixed: return 11
        case .EtopsReserve: return 12
        case .EtopsFAFirstRound: return 13
        case .BILineTypeLoDo: return 14
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
    case RedEyeAMPMLine
    case BlankAMPMLine
    func name () -> Int {
        switch self {
        case .AMLine: return 0
        case .MixedAMPMLine: return 1
        case .PMLine: return 2
        case .RedEyeAMPMLine: return 3
        case .BlankAMPMLine : return 4
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
