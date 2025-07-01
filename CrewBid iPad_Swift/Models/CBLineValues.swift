//
//  CBLineValueView.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 16/04/25.
//

import Foundation
import UIKit

enum CBLineValueTypes : Int {
    case AircraftChanges // 0
    case AircraftTypeIs800 // 1
    case AircraftTypeIs700 // 2
    case AircraftTypeIs8Max // 3
    case BlockDaysOff // 4
    case BlockTime // 5
    case DaysOff // 6
    case Deadheads // 7
    case DutyTime // 8
    case EarliestDept // 9
    case LatestArr // 10
    case Legs // 11
    case MaxLegsInDay // 12
    case OvernightsInBase // 13
    case PassesThruBase // 14
    case Pay // 15
    case PayPerBlock // 16
    case PayPerDay // 17
    case PayPerDutyTime // 18
    case PayPerLeg // 19
    case PayPerTAFB // 20
    case T234 // 21
    case TAFB // 22
    case Trips // 23
    case Weekends // 24
    case WorkDays // 25
    case VTotalPay // 26
    case VFlyPay // 27
    case VVacayPay // 28
    case VPayPerBlock // 29
    case VPayPerDay // 30
    case VCarryOutPay // 31
    case VBlockTime // 32
    case VDaysOff // 33
    case VLength // 34
    case VVacayCarryOutPay // 35
    case VCarryOutVOPay // 36
    case VFrontVoPay // 37
    case VBackVoPay // 38
    case DutyHoursPerDay // 39
    case NonConUsLegs // 40
    case HolidayRig // 41
    case VacationPayDifference // 42
    case NightsInMid // 43
    case TotalCommutes // 44
    case CommutableFronts // 45
    case CommutableBacks // 46
    case CommutabilityFronts // 47
    case CommutabilityBacks // 48
    case CommutabilityOverall // 49
    case LongBlock // 50
    case CarryOutPay // 51
    case VVacayPayNext // 52
    case VVacayPayBoth // 53
    case LineRig // 54
    case TpLPay // 55
    case WorkBP // 56
    case AircraftTypeIs7Max // 57
    case VAbp // 58
    case VAne // 59
    case VAbo // 60
    case VAPbp // 61
    case VAPne // 62
    case VAPbo // 63
    case ETrips // 64
    case WorkBlockCount // 65
    case GTmax //66
    case GTavg //67
    case VOBoth //68
    case OvAvg//69
    case ReserveDaysCount//70
    case rigADG//71
    case rigDHR//72
    case rigDPM//73
    case rigTHR//74
    case LinePay//75
    case coHoli//76
    case PayPlusCO//77
    case CoPlusHoli//78
    case ClawBack
}
