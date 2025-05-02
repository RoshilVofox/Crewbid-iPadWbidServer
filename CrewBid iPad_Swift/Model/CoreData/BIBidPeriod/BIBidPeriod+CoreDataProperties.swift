//
//  BIBidPeriod+CoreDataProperties.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 25/03/25.
//
//

import Foundation
import CoreData


extension BIBidPeriod {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BIBidPeriod> {
        return NSFetchRequest<BIBidPeriod>(entityName: "BidPeriod")
    }

    @NSManaged public var appVersion: String?
    @NSManaged public var aWeekDays: String?
    @NSManaged public var base: String?
    @NSManaged public var baseLine: NSObject?
    @NSManaged public var bidLineNumbers: NSObject?
    @NSManaged public var bidListLineCount: NSNumber?
    @NSManaged public var bidPackageErrorDisplayed: NSNumber?
    @NSManaged public var buddyBidder1: String?
    @NSManaged public var buddyBidder2: String?
    @NSManaged public var bWeekDays: String?
    @NSManaged public var cbFileIntent: String?
    @NSManaged public var cbFileIntentF: String?
    @NSManaged public var cbVacationFiles: NSObject?
    @NSManaged public var cbVacationFilesF: NSObject?
    @NSManaged public var containsCFV: NSNumber?
    @NSManaged public var containsEBG: NSNumber?
    @NSManaged public var containsFvVacay: NSNumber?
    @NSManaged public var containsMissingTripLines: NSNumber?
    @NSManaged public var containsVacay: NSNumber?
    @NSManaged public var coverLetterDisplayed: NSNumber?
    @NSManaged public var crewBidSecretVacation: NSObject?
    @NSManaged public var crewIdentifier: NSNumber?
    @NSManaged public var currentAmPmHerb: NSNumber?
    @NSManaged public var currentDateTime: Date?
    @NSManaged public var cWeekDays: String?
    @NSManaged public var dWeekDays: String?
    @NSManaged public var eomIsNo: String?
    @NSManaged public var eWeekDays: String?
    @NSManaged public var faEomSelectedDate: NSNumber?
    @NSManaged public var faFileIntent: String?
    @NSManaged public var faFileIntentEomOnly: String?
    @NSManaged public var faFileIntentF: String?
    @NSManaged public var faMrtLineExists: NSNumber?
    @NSManaged public var faReserveLineExists: NSNumber?
    @NSManaged public var faVacationFiles: NSObject?
    @NSManaged public var faVacationFilesEomOnlyFA1: NSObject?
    @NSManaged public var faVacationFilesEomOnlyFA2: NSObject?
    @NSManaged public var faVacationFilesEomOnlyFA3: NSObject?
    @NSManaged public var faVacationFilesEomOnlyFA4: NSObject?
    @NSManaged public var faVacationFilesEomOnlyFA5: NSObject?
    @NSManaged public var faVacationFilesEomOnlyFA6: NSObject?
    @NSManaged public var faVacationFilesEomOnlyFA7: NSObject?
    @NSManaged public var faVacationFilesFA1: NSObject?
    @NSManaged public var faVacationFilesFA2: NSObject?
    @NSManaged public var faVacationFilesFA3: NSObject?
    @NSManaged public var faVacationStatus: NSNumber?
    @NSManaged public var filteredLineNumbers: NSObject?
    @NSManaged public var firstLineNumber: NSNumber?
    @NSManaged public var fWeekDays: String?
    @NSManaged public var historicSecretUser: NSNumber?
    @NSManaged public var isAllLinesTrashed: NSNumber?
    @NSManaged public var isAwardSortOn: NSNumber?
    @NSManaged public var isBidListSortOn: NSNumber?
    @NSManaged public var isContainVacationLineValues: NSNumber?
    @NSManaged public var isEomFADeafaultDownload: NSNumber?
    @NSManaged public var isEomOn: NSNumber?
    @NSManaged public var isEtopsLinesContainsInBid: NSNumber?
    @NSManaged public var isFAVacationOn: NSNumber?
    @NSManaged public var isFirstRoundPaperBidder: NSNumber?
    @NSManaged public var isHistoric: NSNumber?
    @NSManaged public var isMaxSubScriptionOfEnteredUser: NSNumber?
    @NSManaged public var isMockData: NSNumber?
    @NSManaged public var isNetwrkNotAvailForSeniorityVacParsing: NSNumber?
    @NSManaged public var isOverNightBulkApplied: String?
    @NSManaged public var isQAdata: String?
    @NSManaged public var isReportReleaseFilterApplied: NSNumber?
    @NSManaged public var isSeniorityVacParsingFailed: NSNumber?
    @NSManaged public var isSortBySubmitOn: NSNumber?
    @NSManaged public var isStateFileModifiedToSync: NSNumber?
    @NSManaged public var isSwaptimizerOn: NSNumber?
    @NSManaged public var isVacationRemoved: NSNumber?
    @NSManaged public var isWbidMaxOn: NSNumber?
    @NSManaged public var lastBidDate: Date?
    @NSManaged public var lastTrashedArray: NSObject?
    @NSManaged public var lastTrashedDetails: NSObject?
    @NSManaged public var latestNewsDisplayed: NSNumber?
    @NSManaged public var loadedPresetIdentifier: String?
    @NSManaged public var month: NSNumber?
    @NSManaged public var mRTEnabledForASort: NSNumber?
    @NSManaged public var mRTLineIndexForASort: NSNumber?
    @NSManaged public var myCalEnabled: NSNumber?
    @NSManaged public var myCalEndDate: Date?
    @NSManaged public var myCalStartDate: Date?
    @NSManaged public var numVacations: NSNumber?
    @NSManaged public var onlyContainEOM: String?
    @NSManaged public var overNightBulk: NSObject?
    @NSManaged public var overNightCities: NSObject?
    @NSManaged public var paperBidCount: NSNumber?
    @NSManaged public var paperBidVacArray: NSObject?
    @NSManaged public var positionType: NSNumber?
    @NSManaged public var reservedLineIndexForASort: NSNumber?
    @NSManaged public var reserveEnabledForASort: NSNumber?
    @NSManaged public var round: NSNumber?
    @NSManaged public var secretSwitchOn: String?
    @NSManaged public var selectedSegmentVacType: String?
    @NSManaged public var seniorityNumber: NSNumber?
    @NSManaged public var seniorityVacayAvailable: NSNumber?
    @NSManaged public var stateFileVersion: NSNumber?
    @NSManaged public var stateSyncVersion: NSNumber?
    @NSManaged public var stateUpdatedTime: Date?
    @NSManaged public var submitSortOrder: NSNumber?
    @NSManaged public var submittedBid: String?
    @NSManaged public var swaptimizerIdentifier: NSNumber?
    @NSManaged public var swaptimizerStatus: NSNumber?
    @NSManaged public var userVacationWbidOrCrewBid: String?
    @NSManaged public var vacationDeffArray: NSObject?
    @NSManaged public var vacationName: String?
    @NSManaged public var vacationType: String?
    @NSManaged public var vacayAlertDisplayed: NSNumber?
    @NSManaged public var vactionWeekAlertDisplayed: NSNumber?
    @NSManaged public var wbFileIntent: String?
    @NSManaged public var wbFileIntentF: String?
    @NSManaged public var wbidSecretVacation: NSObject?
    @NSManaged public var wbVacationfile: NSObject?
    @NSManaged public var wbVacationfileF: NSObject?
    @NSManaged public var year: NSNumber?
    @NSManaged public var awardDetails: NSSet?
    @NSManaged public var bidReceipts: NSSet?
    @NSManaged public var commuteTime: NSSet?
    @NSManaged public var deadheadAtEndCities: NSSet?
    @NSManaged public var deadheadAtStartCities: NSSet?
    @NSManaged public var lines: NSSet?
    @NSManaged public var lineSortKeyMaps: NSSet?
    @NSManaged public var lineSorts: NSSet?
    @NSManaged public var textFiles: NSSet?
    @NSManaged public var vacationArrayFromServer: VacationArrayFromServer?
    @NSManaged public var vacations: NSSet?
    @NSManaged public var lineFilters: NSSet?

}

// MARK: Generated accessors for awardDetails
extension BIBidPeriod {

    @objc(addAwardDetailsObject:)
    @NSManaged public func addToAwardDetails(_ value: AwardDetails)

    @objc(removeAwardDetailsObject:)
    @NSManaged public func removeFromAwardDetails(_ value: AwardDetails)

    @objc(addAwardDetails:)
    @NSManaged public func addToAwardDetails(_ values: NSSet)

    @objc(removeAwardDetails:)
    @NSManaged public func removeFromAwardDetails(_ values: NSSet)

}

// MARK: Generated accessors for bidReceipts
extension BIBidPeriod {

    @objc(addBidReceiptsObject:)
    @NSManaged public func addToBidReceipts(_ value: BIBidReceipt)

    @objc(removeBidReceiptsObject:)
    @NSManaged public func removeFromBidReceipts(_ value: BIBidReceipt)

    @objc(addBidReceipts:)
    @NSManaged public func addToBidReceipts(_ values: NSSet)

    @objc(removeBidReceipts:)
    @NSManaged public func removeFromBidReceipts(_ values: NSSet)

}

// MARK: Generated accessors for commuteTime
extension BIBidPeriod {

    @objc(addCommuteTimeObject:)
    @NSManaged public func addToCommuteTime(_ value: CommuteTime)

    @objc(removeCommuteTimeObject:)
    @NSManaged public func removeFromCommuteTime(_ value: CommuteTime)

    @objc(addCommuteTime:)
    @NSManaged public func addToCommuteTime(_ values: NSSet)

    @objc(removeCommuteTime:)
    @NSManaged public func removeFromCommuteTime(_ values: NSSet)

}

// MARK: Generated accessors for deadheadAtEndCities
extension BIBidPeriod {

    @objc(addDeadheadAtEndCitiesObject:)
    @NSManaged public func addToDeadheadAtEndCities(_ value: BIDeadheadAtEndCity)

    @objc(removeDeadheadAtEndCitiesObject:)
    @NSManaged public func removeFromDeadheadAtEndCities(_ value: BIDeadheadAtEndCity)

    @objc(addDeadheadAtEndCities:)
    @NSManaged public func addToDeadheadAtEndCities(_ values: NSSet)

    @objc(removeDeadheadAtEndCities:)
    @NSManaged public func removeFromDeadheadAtEndCities(_ values: NSSet)

}

// MARK: Generated accessors for deadheadAtStartCities
extension BIBidPeriod {

    @objc(addDeadheadAtStartCitiesObject:)
    @NSManaged public func addToDeadheadAtStartCities(_ value: BIDeadheadAtStartCity)

    @objc(removeDeadheadAtStartCitiesObject:)
    @NSManaged public func removeFromDeadheadAtStartCities(_ value: BIDeadheadAtStartCity)

    @objc(addDeadheadAtStartCities:)
    @NSManaged public func addToDeadheadAtStartCities(_ values: NSSet)

    @objc(removeDeadheadAtStartCities:)
    @NSManaged public func removeFromDeadheadAtStartCities(_ values: NSSet)

}

// MARK: Generated accessors for lines
extension BIBidPeriod {

    @objc(addLinesObject:)
    @NSManaged public func addToLines(_ value: BILine)

    @objc(removeLinesObject:)
    @NSManaged public func removeFromLines(_ value: BILine)

    @objc(addLines:)
    @NSManaged public func addToLines(_ values: NSSet)

    @objc(removeLines:)
    @NSManaged public func removeFromLines(_ values: NSSet)

}

// MARK: Generated accessors for lineSortKeyMaps
extension BIBidPeriod {

    @objc(addLineSortKeyMapsObject:)
    @NSManaged public func addToLineSortKeyMaps(_ value: BILineSortKeyMap)

    @objc(removeLineSortKeyMapsObject:)
    @NSManaged public func removeFromLineSortKeyMaps(_ value: BILineSortKeyMap)

    @objc(addLineSortKeyMaps:)
    @NSManaged public func addToLineSortKeyMaps(_ values: NSSet)

    @objc(removeLineSortKeyMaps:)
    @NSManaged public func removeFromLineSortKeyMaps(_ values: NSSet)

}

// MARK: Generated accessors for lineSorts
extension BIBidPeriod {

    @objc(addLineSortsObject:)
    @NSManaged public func addToLineSorts(_ value: BILineSort)

    @objc(removeLineSortsObject:)
    @NSManaged public func removeFromLineSorts(_ value: BILineSort)

    @objc(addLineSorts:)
    @NSManaged public func addToLineSorts(_ values: NSSet)

    @objc(removeLineSorts:)
    @NSManaged public func removeFromLineSorts(_ values: NSSet)

}

// MARK: Generated accessors for textFiles
extension BIBidPeriod {

    @objc(addTextFilesObject:)
    @NSManaged public func addToTextFiles(_ value: BITextFile)

    @objc(removeTextFilesObject:)
    @NSManaged public func removeFromTextFiles(_ value: BITextFile)

    @objc(addTextFiles:)
    @NSManaged public func addToTextFiles(_ values: NSSet)

    @objc(removeTextFiles:)
    @NSManaged public func removeFromTextFiles(_ values: NSSet)

}

// MARK: Generated accessors for vacations
extension BIBidPeriod {

    @objc(addVacationsObject:)
    @NSManaged public func addToVacations(_ value: BIVacation)

    @objc(removeVacationsObject:)
    @NSManaged public func removeFromVacations(_ value: BIVacation)

    @objc(addVacations:)
    @NSManaged public func addToVacations(_ values: NSSet)

    @objc(removeVacations:)
    @NSManaged public func removeFromVacations(_ values: NSSet)

}

// MARK: Generated accessors for lineFilters
extension BIBidPeriod {

    @objc(addLineFiltersObject:)
    @NSManaged public func addToLineFilters(_ value: BIFilterRule)

    @objc(removeLineFiltersObject:)
    @NSManaged public func removeFromLineFilters(_ value: BIFilterRule)

    @objc(addLineFilters:)
    @NSManaged public func addToLineFilters(_ values: NSSet)

    @objc(removeLineFilters:)
    @NSManaged public func removeFromLineFilters(_ values: NSSet)

}

extension BIBidPeriod : Identifiable {

}
