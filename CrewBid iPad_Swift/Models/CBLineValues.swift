//
//  CBLineValueView.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 16/04/25.
//

import Foundation
import UIKit

enum CBLineValueTypes : Int {
    case cbLineValueTypeAircraftChanges // 0
    case cbLineValueTypeAircraftTypeIs800 // 1
    case cbLineValueTypeAircraftTypeIs700 // 2
    case cbLineValueTypeAircraftTypeIs8Max // 3
    case cbLineValueTypeBlockDaysOff // 4
    case cbLineValueTypeBlockTime // 5
    case cbLineValueTypeDaysOff // 6
    case cbLineValueTypeDeadheads // 7
    case cbLineValueTypeDutyTime // 8
    case cbLineValueTypeEarliestDept // 9
    case cbLineValueTypeLatestArr // 10
    case cbLineValueTypeLegs // 11
    case cbLineValueTypeMaxLegsInDay // 12
    case cbLineValueTypeOvernightsInBase // 13
    case cbLineValueTypePassesThruBase // 14
    case cbLineValueTypePay // 15
    case cbLineValueTypePayPerBlock // 16
    case cbLineValueTypePayPerDay // 17
    case cbLineValueTypePayPerDutyTime // 18
    case cbLineValueTypePayPerLeg // 19
    case cbLineValueTypePayPerTAFB // 20
    case cbLineValueTypeT234 // 21
    case cbLineValueTypeTAFB // 22
    case cbLineValueTypeTrips // 23
    case cbLineValueTypeWeekends // 24
    case cbLineValueTypeWorkDays // 25
    case cbLineValueTypeVTotalPay // 26
    case cbLineValueTypeVFlyPay // 27
    case cbLineValueTypeVVacayPay // 28
    case cbLineValueTypeVPayPerBlock // 29
    case cbLineValueTypeVPayPerDay // 30
    case cbLineValueTypeVCarryOutPay // 31
    case cbLineValueTypeVBlockTime // 32
    case cbLineValueTypeVDaysOff // 33
    case cbLineValueTypeVLength // 34
    case cbLineValueTypeVVacayCarryOutPay // 35
    case cbLineValueTypeVCarryOutVOPay // 36
    case cbLineValueTypeVFrontVoPay // 37
    case cbLineValueTypeVBackVoPay // 38
    case cbLineValueTypeDutyHoursPerDay // 39
    case cbLineValueTypeNonConUsLegs // 40
    case cbLineValueHolidayRig // 41
    case cbVacationPayDifference // 42
    case cbNightsInMid // 43
    case cbTotalCommutes // 44
    case cbCommutableFronts // 45
    case cbCommutableBacks // 46
    case cbCommutabilityFronts // 47
    case cbCommutabilityBacks // 48
    case cbCommutabilityOverall // 49
    case cbLineValueTypeLongBlock // 50
    case cbLineValueTypeCarryOutPay // 51
    case cbLineValueTypeVVacayPayNext // 52
    case cbLineValueTypeVVacayPayBoth // 53
    case cbLineValueTypeLineRig // 54
    case cbLineValueTpLPay // 55
    case cbLineValueWorkBP // 56
    case cbLineValueTypeAircraftTypeIs7Max // 57
    case cbLineValueTypeVAbp // 58
    case cbLineValueTypeVAne // 59
    case cbLineValueTypeVAbo // 60
    case cbLineValueTypeVAPbp // 61
    case cbLineValueTypeVAPne // 62
    case cbLineValueTypeVAPbo // 63
    case cbLineValueTypeETrips // 64
    case cbLineValueTypeWorkBlockCount // 65
    case cBLineValueTypeGTmax //66
    case cBLineValueTypeGTavg //67
    case cBLineValueTypeVOBoth //68
    case cBLineValueTypeOvAvg//69
    case cBLineValueTypeReserveDaysCount//70
    case cBLineValueTyperigADG//71
    case cBLineValueTyperigDHR//72
    case cBLineValueTyperigDPM//73
    case cBLineValueTyperigTHR//74
    case cBLineValueTypeLinePay//75
    case cBLineValueTypecoHoli//76
    case cBLineValueTypePayPlusCO//77
    case cBLineValueTypeCoPlusHoli//78
    case cbLineValueTypeClawBack
}
