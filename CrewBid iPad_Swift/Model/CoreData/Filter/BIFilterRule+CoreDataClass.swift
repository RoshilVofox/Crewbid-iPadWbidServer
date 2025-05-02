//
//  BIFilterRule+CoreDataClass.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 25/03/25.
//
//

import Foundation
import CoreData

@objc(BIFilterRule)
public class BIFilterRule: NSManagedObject {

}
enum PopoverViewType: Int {
    case Refresh
    case MockMonth
    case MockYear
    case MoveToBidlist
    case warning
    case MoveFAPositions
    case MoreButton
    case comparisonButton
    case valuesButton
    case cityPopUp
    case CommutabilityFirstCell
    case CommutabilitySecondCell
    case CommutabilityThirdCell
    case CommutabilityFourthCell
    case CommutingManualValueCell
    case CommutingManualNoMidInfo
    case CommutingManualNoMidInfoSort
    case RuleValue
}

@objc enum BITypeFilterRuleType : Int {
    case BITypeCompoundType
    case BITypeFilterRuleTypeGeographic
    func name () -> Int {
        switch self {
            case .BITypeCompoundType: return 0
            case .BITypeFilterRuleTypeGeographic: return 1
        }
    }
    
}

@objc enum BIAmPmFilterRuleType : Int {
     case BIAmPmCompoundType
    
    func name () -> Int {
        switch self
        {
        case  .BIAmPmCompoundType: return 0
        }
    }

}

@objc enum BIPositionFilterRuleType : Int {
    case BIPositionCompoundType
    
    func name () -> Int {
        switch self
        {
        case  .BIPositionCompoundType: return 0
        }
    }
}
