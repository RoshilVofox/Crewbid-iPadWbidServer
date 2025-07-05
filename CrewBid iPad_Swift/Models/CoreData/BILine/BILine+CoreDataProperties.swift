//
//  BILine+CoreDataProperties.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/03/25.
//
//

import Foundation
import CoreData



extension BILine {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BILine> {
        return NSFetchRequest<BILine>(entityName: "Line")
    }

    @NSManaged public var actualBlockMinutes: NSNumber?
    @NSManaged public var actualPay: NSNumber?
    @NSManaged public var acTypeClassicPercent: NSNumber?
    @NSManaged public var acTypeNgPercent: NSNumber?
    @NSManaged public var aircraftType7MaxCount: NSNumber?
    @NSManaged public var aircraftType8MaxCount: NSNumber?
    @NSManaged public var aircraftType300Count: NSNumber?
    @NSManaged public var aircraftType500Count: NSNumber?
    @NSManaged public var aircraftType700Count: NSNumber?
    @NSManaged public var aircraftType800Count: NSNumber?
    @NSManaged public var amPM: NSNumber?
    @NSManaged public var awardSortOrder: NSNumber?
    @NSManaged public var bidOrder: NSNumber?
    @NSManaged public var blockHours: NSNumber?
    @NSManaged public var blockMinutes: NSNumber?
    @NSManaged public var blockOfDaysOff: NSNumber?
    @NSManaged public var carryOutPay: NSNumber?
    @NSManaged public var cfvVacDates: NSObject?
    @NSManaged public var coHoli: NSNumber?
    @NSManaged public var commutabilityBack: NSNumber?
    @NSManaged public var commutabilityFront: NSNumber?
    @NSManaged public var commutabilityOverall: NSNumber?
    @NSManaged public var commutableBacks: NSNumber?
    @NSManaged public var commutableFronts: NSNumber?
    @NSManaged public var commutesRequired: NSNumber?
    @NSManaged public var containsNonConusLeg: NSNumber?
    @NSManaged public var containsPartialTrip: NSNumber?
    @NSManaged public var coPlusHoli: NSNumber?
    @NSManaged public var daysOff: NSNumber?
    @NSManaged public var deadheadsAtEitherCount: NSNumber?
    @NSManaged public var deadheadsAtEndCount: NSNumber?
    @NSManaged public var deadheadsAtStartCount: NSNumber?
    @NSManaged public var deadheadsCount: NSNumber?
    @NSManaged public var dutyHours: NSNumber?
    @NSManaged public var dutyHoursPerDay: NSNumber?
    @NSManaged public var dutyMinutes: NSNumber?
    @NSManaged public var dynamicSortValue0: NSNumber?
    @NSManaged public var dynamicSortValue1: NSNumber?
    @NSManaged public var dynamicSortValue2: NSNumber?
    @NSManaged public var dynamicSortValue3: NSNumber?
    @NSManaged public var dynamicSortValue4: NSNumber?
    @NSManaged public var dynamicSortValue5: NSNumber?
    @NSManaged public var dynamicSortValue6: NSNumber?
    @NSManaged public var dynamicSortValue7: NSNumber?
    @NSManaged public var dynamicSortValue8: NSNumber?
    @NSManaged public var dynamicSortValue9: NSNumber?
    @NSManaged public var dynamicSortValue10: NSNumber?
    @NSManaged public var dynamicSortValue11: NSNumber?
    @NSManaged public var dynamicSortValue12: NSNumber?
    @NSManaged public var dynamicSortValue13: NSNumber?
    @NSManaged public var dynamicSortValue14: NSNumber?
    @NSManaged public var dynamicSortValue15: NSNumber?
    @NSManaged public var dynamicSortValue16: NSNumber?
    @NSManaged public var dynamicSortValue17: NSNumber?
    @NSManaged public var dynamicSortValue18: NSNumber?
    @NSManaged public var dynamicSortValue19: NSNumber?
    @NSManaged public var dynamicSortValue20: NSNumber?
    @NSManaged public var dynamicSortValue21: NSNumber?
    @NSManaged public var dynamicSortValue22: NSNumber?
    @NSManaged public var dynamicSortValue23: NSNumber?
    @NSManaged public var dynamicSortValue24: NSNumber?
    @NSManaged public var dynamicSortValue25: NSNumber?
    @NSManaged public var dynamicSortValue26: NSNumber?
    @NSManaged public var dynamicSortValue27: NSNumber?
    @NSManaged public var dynamicSortValue28: NSNumber?
    @NSManaged public var dynamicSortValue29: NSNumber?
    @NSManaged public var dynamicSortValue30: NSNumber?
    @NSManaged public var earliestDepartureTime: NSNumber?
    @NSManaged public var etopsTripsCount: NSNumber?
    @NSManaged public var etopsType: NSNumber?
    @NSManaged public var faBidLineMrt: NSNumber?
    @NSManaged public var faBidLineReserve: NSNumber?
    @NSManaged public var faLineType: NSNumber?
    @NSManaged public var faNumber: String?
    @NSManaged public var faPosition: NSNumber?
    @NSManaged public var faReserveLineType: NSNumber?
    @NSManaged public var flagOrder: NSNumber?
    @NSManaged public var fourDayTripsCount: NSNumber?
    @NSManaged public var fridaysCount: NSNumber?
    @NSManaged public var frozenOrder: NSNumber?
    @NSManaged public var groupOrder: NSNumber?
    @NSManaged public var gTavg: NSNumber?
    @NSManaged public var gTmax: NSNumber?
    @NSManaged public var holidayPay: NSNumber?
    @NSManaged public var isETOPS: NSNumber?
    @NSManaged public var isETOPSRES: NSNumber?
    @NSManaged public var isFA25thLineVacationCalculated: NSNumber?
    @NSManaged public var isFA31thLineVacationCalculated: NSNumber?
    @NSManaged public var isFrozen: NSNumber?
    @NSManaged public var isOvernightFiltered: NSNumber?
    @NSManaged public var isTrashed: NSNumber?
    @NSManaged public var latestArrivalTime: NSNumber?
    @NSManaged public var lineoverNightCities: NSObject?
    @NSManaged public var lineRig: NSNumber?
    @NSManaged public var markerTitle: String?
    @NSManaged public var maximumOvernightHours: NSNumber?
    @NSManaged public var maxLegsInADay: NSNumber?
    @NSManaged public var midTripPTBs: NSNumber?
    @NSManaged public var minimumOvernightHours: NSNumber?
    @NSManaged public var mondaysCount: NSNumber?
    @NSManaged public var monthBits: NSNumber?
    @NSManaged public var nightsInMid: NSNumber?
    @NSManaged public var nonConusLegsCount: NSNumber?
    @NSManaged public var numAircraftChanges: NSNumber?
    @NSManaged public var number: NSNumber?
    @NSManaged public var numDays: NSNumber?
    @NSManaged public var numLegs: NSNumber?
    @NSManaged public var numTrips: NSNumber?
    @NSManaged public var oneOrTwoDaysCount: NSNumber?
    @NSManaged public var ovAvg: NSNumber?
    @NSManaged public var overlapDaysCount: NSNumber?
    @NSManaged public var overnightsInBase: NSNumber?
    @NSManaged public var passesThruBase: NSNumber?
    @NSManaged public var pay: NSNumber?
    @NSManaged public var payPerBlockHour: NSNumber?
    @NSManaged public var payPerDay: NSNumber?
    @NSManaged public var payPerDutyTime: NSNumber?
    @NSManaged public var payPerLeg: NSNumber?
    @NSManaged public var payPerTAFB: NSNumber?
    @NSManaged public var payPerTrip: NSNumber?
    @NSManaged public var payPlusCo: NSNumber?
    @NSManaged public var previousBidOrder: NSNumber?
    @NSManaged public var redeyes: NSNumber?
    @NSManaged public var redEyeTrips: NSNumber?
    @NSManaged public var reportReleaseType: NSNumber?
    @NSManaged public var reserveDays: NSNumber?
    @NSManaged public var rigADG: NSNumber?
    @NSManaged public var rigDHR: NSNumber?
    @NSManaged public var rigDPM: NSNumber?
    @NSManaged public var rigTHR: NSNumber?
    @NSManaged public var rlsGreaterThanEntered: NSNumber?
    @NSManaged public var rptLessThanentered: NSNumber?
    @NSManaged public var saturdaysCount: NSNumber?
    @NSManaged public var submitSortOrder: NSNumber?
    @NSManaged public var sundaysCount: NSNumber?
    @NSManaged public var tafbHours: NSNumber?
    @NSManaged public var tafbMinutes: NSNumber?
    @NSManaged public var threeDayTripsCount: NSNumber?
    @NSManaged public var thursdaysCount: NSNumber?
    @NSManaged public var totalCommutes: NSNumber?
    @NSManaged public var tripEndMonthBits: NSNumber?
    @NSManaged public var tripStartMonthBits: NSNumber?
    @NSManaged public var tripTfp: NSNumber?
    @NSManaged public var tuesdaysCount: NSNumber?
    @NSManaged public var turnsCount: NSNumber?
    @NSManaged public var twoDayTripsCount: NSNumber?
    @NSManaged public var type: NSNumber?
    @NSManaged public var userFlagType: NSNumber?
    @NSManaged public var vAbo: NSNumber?
    @NSManaged public var vAbp: NSNumber?
    @NSManaged public var vAne: NSNumber?
    @NSManaged public var vAPbo: NSNumber?
    @NSManaged public var vAPbp: NSNumber?
    @NSManaged public var vAPne: NSNumber?
    @NSManaged public var vBackVoPay: NSNumber?
    @NSManaged public var vBlockTime: NSNumber?
    @NSManaged public var vCarryOutPay: NSNumber?
    @NSManaged public var vCarryOutVOPay: NSNumber?
    @NSManaged public var vCBVacPay: NSNumber?
    @NSManaged public var vDaysOff: NSNumber?
    @NSManaged public var vEffectiveVacayLength: NSNumber?
    @NSManaged public var vFlyPay: NSNumber?
    @NSManaged public var vFrontVoPay: NSNumber?
    @NSManaged public var vHolidayPay: NSNumber?
    @NSManaged public var vLongestBlockofDaysOff: NSNumber?
    @NSManaged public var vPayPerBlock: NSNumber?
    @NSManaged public var vPayPerDay: NSNumber?
    @NSManaged public var vTotalPay: NSNumber?
    @NSManaged public var vTpLPay: NSNumber?
    @NSManaged public var vVacationPay: NSNumber?
    @NSManaged public var vVacayCarryOutPay: NSNumber?
    @NSManaged public var vVacayPayBothBP: NSNumber?
    @NSManaged public var vVacayPayNextBP: NSNumber?
    @NSManaged public var vWBVacPay: NSNumber?
    @NSManaged public var wednesdaysCount: NSNumber?
    @NSManaged public var weekdayBits: NSNumber?
    @NSManaged public var weekendsCount: NSNumber?
    @NSManaged public var workBlock1: NSNumber?
    @NSManaged public var workBlock2: NSNumber?
    @NSManaged public var workBlock3: NSNumber?
    @NSManaged public var workBlock4: NSNumber?
    @NSManaged public var workBlockCount: NSNumber?
    @NSManaged public var workDays: NSNumber?
    @NSManaged public var workDaysBP: NSNumber?
    @NSManaged public var bidPeriod: BIBidPeriod?
    @NSManaged public var days: NSSet?
    @NSManaged public var firstTrip: BITrip?
    @NSManaged public var fvvacations: NSSet?
    @NSManaged public var insertionPoint: BIInsertionPoint?
    @NSManaged public var legs: NSSet?
    @NSManaged public var trips: NSSet?
    @NSManaged public var vacationArrayFromServer: VacationArrayFromServer?
    @NSManaged public var workBlocks: NSSet?
    @NSManaged public var clawBack: NSNumber?

    

}

// MARK: Generated accessors for days
extension BILine {

    @objc(addDaysObject:)
    @NSManaged public func addToDays(_ value: BIDay)

    @objc(removeDaysObject:)
    @NSManaged public func removeFromDays(_ value: BIDay)

    @objc(addDays:)
    @NSManaged public func addToDays(_ values: NSSet)

    @objc(removeDays:)
    @NSManaged public func removeFromDays(_ values: NSSet)

}

// MARK: Generated accessors for fvvacations
extension BILine {

    @objc(addFvvacationsObject:)
    @NSManaged public func addToFvvacations(_ value: BIVacation)

    @objc(removeFvvacationsObject:)
    @NSManaged public func removeFromFvvacations(_ value: BIVacation)

    @objc(addFvvacations:)
    @NSManaged public func addToFvvacations(_ values: NSSet)

    @objc(removeFvvacations:)
    @NSManaged public func removeFromFvvacations(_ values: NSSet)

}

// MARK: Generated accessors for legs
extension BILine {

    @objc(addLegsObject:)
    @NSManaged public func addToLegs(_ value: BILeg)

    @objc(removeLegsObject:)
    @NSManaged public func removeFromLegs(_ value: BILeg)

    @objc(addLegs:)
    @NSManaged public func addToLegs(_ values: NSSet)

    @objc(removeLegs:)
    @NSManaged public func removeFromLegs(_ values: NSSet)

}

// MARK: Generated accessors for trips
extension BILine {

    @objc(addTripsObject:)
    @NSManaged public func addToTrips(_ value: BITrip)

    @objc(removeTripsObject:)
    @NSManaged public func removeFromTrips(_ value: BITrip)

    @objc(addTrips:)
    @NSManaged public func addToTrips(_ values: NSSet)

    @objc(removeTrips:)
    @NSManaged public func removeFromTrips(_ values: NSSet)

}

// MARK: Generated accessors for workBlocks
extension BILine {

    @objc(addWorkBlocksObject:)
    @NSManaged public func addToWorkBlocks(_ value: WorkBlockList)

    @objc(removeWorkBlocksObject:)
    @NSManaged public func removeFromWorkBlocks(_ value: WorkBlockList)

    @objc(addWorkBlocks:)
    @NSManaged public func addToWorkBlocks(_ values: NSSet)

    @objc(removeWorkBlocks:)
    @NSManaged public func removeFromWorkBlocks(_ values: NSSet)

}

extension BILine : Identifiable {

    var orderedTrips:[Any] {
        let allTrips = self.trips?.allObjects ?? []
        let orderedDays = allTrips.sorted {
            guard
                let date1 = ($0 as AnyObject).value(forKeyPath: "startDate") as? Date,
                let date2 = ($1 as AnyObject).value(forKeyPath: "startDate") as? Date
            else {
                return false
            }
            return date1 < date2
        }
        return orderedDays
    }
    
    var redEyeCount: NSNumber {
        let allLegs = legs?.allObjects as? [BILeg] ?? []
        let redEyeLegs = allLegs.filter { $0.info?.isRedEyeFlight == true }
        return NSNumber(value: redEyeLegs.count)
    }
    
    var isRedEyeLine: Bool {
        return (self.redEyeCount.intValue) > 0
    }
    
    func t234() -> String {
        return "\(CInt(truncating: turnsCount!) > 9 ? "*" : turnsCount!.stringValue)\(Int(CInt(truncating: twoDayTripsCount!)))\(Int(CInt(truncating: threeDayTripsCount!)))\(Int(CInt(truncating: fourDayTripsCount!)))"
    }
    
    
    var faPositionString: String {
            var faPos = "NA"
            var isFirstTrip = true
     
            for trip in self.trips ?? [] {
                guard let trip = trip as? BITrip,
                      let tripPos = trip.positionString else {
                    continue
                }
     
                if isFirstTrip {
                    faPos = tripPos
                    isFirstTrip = false
                } else if faPos != tripPos {
                    faPos = "M"
                    break
                }
            }
     
            return faPos
        }
    
    func faPositionColor() -> UIColor? {
        if !self.bidPeriod!.isFABid() {
            return nil
        }
        var faPos: String = "NA"
        var tripPos: String
        // if there are no trips or there is no position for a trip,
        // then fa position is NA
        var isFirstTrip: Bool = true
        for case let trip as BITrip in self.trips! {
            if trip.positionString == nil {
                tripPos = ""
            } else {
                tripPos = trip.positionString!
            }
            // trip position
            if tripPos != "" {
                if isFirstTrip {
                    faPos = tripPos
                    isFirstTrip = false
                }
                if !(faPos == tripPos) {
                    faPos = "M"
                    break
                } else {
                    faPos = tripPos
                }
            }
        }
        // Return color based on FA Position

        switch faPos {
        case "A":
            return CBColor.faPosAColor
        case "B":
            return CBColor.faPosBColor
        case "C":
            return CBColor.faPosCColor
        case "D":
            return CBColor.faPosDColor
        case "M":
            return .purple
        default:
            return nil
        }
    }
}

@objc enum BILineSortCategory : Int {
    case BIStandardSortCategory
    // 0
    case BICitiesLineSortCategory
    // 1
    case BIDeadheadsLineSortCategory
    // 2
    case BIPositionsLineSortCategory
    // 3
    case BICommutingLineSortCategory
    // 4
    case BISwaptimizerLineSortCategory
    // 5
    case BIPassesThruBaseLineSortCategory
    // 6
    case BIFaVacationLineSortCategory
    // 7
    case BIDaysOffLineSortCategory
    // 8
    case BICommutabilityLineSortCategory
    // 9
    case BIFlagLineSortCategory
    // 10
    case BIDaysWorkLineSortCategory
    // 11
    case BIDaysTripStartSortCategory
    // 12
    
}

@objc enum BICityLineSortType : Int {
    case BIOvernightCityLineSortType
    // 0
    case BILegCityLineSortType
    // 1
    case BICitiesLineSortTypeEastCoast
    // 2
    case BICitiesLineSortTypeWestCoast
    // 3
    case BICitiesLineSortTypeNonConus
    // 4
    case BICitiesLineSortTypeIntl
    // 5
    case BICitiesLineSortTypeAll
    // 6
    case BICitiesLineSortTypeNonConusLegs
    // 7
    case BICitiesLineSortTypeHawaii
}

@objc enum BIDeadheadLineSortType : Int {
    case BIDeadheadSortType
    case BIDeadheadAtStartSortType
    case BIDeadheadAtEndSortType
    case BIDeadheadAtBothSortType
}

@objc enum BIVacationLineSortType : Int {
   case TotalPay           //0
   case FlyPay            //1
   case VacationPay       //2
   case PayPerBlock        //3
   case PayPerDay         //4
   case CarryOutPay        //5
   case BlockTime          //6
   case DaysOff           //7
   case EffectiveVacationLength //8
   case FrontVoPay            // 9
   case BackVoPay               // 10
   case VacayCarryOutPay        // 11
   case CarryOutVoPay          // 12
   case LongestBlockofDaysOff  //13
   case VacationPayBothBP       //14
   case VacationPayNextBP //15
   case VANe           //16
}
@objc enum BIPassesThruBaseLineSortType : Int {
    case BIPassesThruBaseLineSortTypeMidTrip
    case BIPassesThruBaseLineSortTypeStandard
}

@objc enum BIPositionsLineSortType : Int {
    case BIPositionASortType
    case BIPositionBSortType
    case BIPositionCSortType
    case BIPositionDSortType
    case BIPositionQuickAddABCType
}

var kNameLineSortKey: String = "name"
var kCategoryTitleLineSortKey: String = "title"
var kCategoryTypesLineSortKey: String = "types"
var kLineSortsSortsKey: String = "sorts"

