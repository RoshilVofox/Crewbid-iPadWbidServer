//
//  CBCommutingCellHelper.swift
//  CrewBid iPad_Swift
//
//  Created by Rishad on 18/08/25.
//

import UIKit

class CBCommutingCellHelper: NSObject {
    
    private let internationalCityMinutes = 75
    private let cityMinutes = 60
    
    func calculateCommuteLinePropertiesForWorkblock(withDepartureMonThursText departureMonThuesText: String, departureFriText: String, departureSatText: String, departureSunText: String, returnMonThursText: String, returnSunText: String, returnSatText: String, returnFriText: String, bidPeriod: BIBidPeriod, isFromSort: Bool = false) {
        
        let commuteList: NSMutableArray = fetchCommuteTimeWithBidPeriod(bidPeriod)
        let formatterDate = DateFormatter()
        formatterDate.timeZone = TimeZone(secondsFromGMT: 0)
        formatterDate.dateFormat = "yyyy-MM-dd"
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        if let timezone = TimeZone(secondsFromGMT: 0) {
            calendar.timeZone = timezone as TimeZone
        }
        
        for line in CBGlobalMethods.shared.selectedBidPeriod!.orderedLines() {
            line.commutableBacks = NSNumber(value: 0)
            line.commutableFronts = NSNumber(value: 0)
            line.commutabilityFront = NSNumber(value: 0)
            line.commutabilityBack = NSNumber(value: 0)
            line.commutabilityOverall = NSNumber(value: 0)
            
            for workblock in line.orderedWorkBlocks as! [WorkBlockList] {
                var isCommuteFrontEnd = false
                var isCommuteBackEnd = false
                let filtered = commuteList.filtered(using: NSPredicate(format: "bidDayStringValue == %@", "\(formatterDate.string(from: workblock.startDateTime!))"))
                if filtered.count > 0 {
                    if let objCommuteTime = filtered[0] as? CommuteTime {
                        let datePlusMinute: Date = objCommuteTime.earliestArrivel!
                        let secondDate: Date = workblock.startDateTakeOffTime!.addingTimeInterval(TimeInterval(60 * (workblock.briefMinutes?.intValue ?? 0)))
                        if secondDate >= datePlusMinute {
                            isCommuteFrontEnd = true
                            line.commutableFronts = (line.commutableFronts!.doubleValue + 1) as NSNumber
                        }
                        else if (calendar.component(.hour, from: datePlusMinute) == 0 && calendar.component(.minute, from: datePlusMinute) == 0 && calendar.component(.day, from: datePlusMinute) == calendar.component(.day, from: secondDate)) {
                            isCommuteFrontEnd = true
                            line.commutableFronts = (line.commutableFronts!.doubleValue + 1) as NSNumber
                        }
                    }
                }
                let endDateList = commuteList.filtered(using: NSPredicate(format: "bidDayStringValue == %@", "\(formatterDate.string(from: workblock.endDateOnly!))"))
                if endDateList.count > 0 {
                   if let objCommuteTime = endDateList[0] as? CommuteTime {
                       let latestDeparture: Date = objCommuteTime.latestDeparture!
                       let endDateTime: Date = workblock.endDateTime!
                       if endDateTime <= latestDeparture {
                           line.commutableBacks = (line.commutableBacks!.doubleValue + 1) as NSNumber
                           isCommuteBackEnd = true
                       }
                       else if (calendar.component(.hour, from: latestDeparture) == 0 && calendar.component(.minute, from: latestDeparture) == 0) {
                           if (calendar.component(.day, from: workblock.endDateOnly!) == calendar.component(.day, from: latestDeparture)) {
                               line.commutableBacks = (line.commutableBacks!.doubleValue + 1) as NSNumber
                               isCommuteBackEnd = true
                           }
                       }
                    }
                }
                if isCommuteFrontEnd && isCommuteBackEnd && isFromSort {
                    self.calculateIsTripFullyCommutable(line: line, and: workblock)
                }
            }
            let workBlockCount = line.orderedWorkBlocks.count
            line.totalCommutes = NSNumber(value: workBlockCount * 2)
            
            if workBlockCount > 0 {
                let temp1 = Float(String(format: "%.02f", (line.commutableFronts!.doubleValue / Double(workBlockCount)) * 100)) ?? 0.0
                line.commutabilityFront = NSNumber(value: temp1)
            }
            
            if workBlockCount > 0 {
                let temp2 = Float(String(format: "%.02f", (line.commutableBacks!.doubleValue / Double(workBlockCount)) * 100)) ?? 0.0
                line.commutabilityBack = NSNumber(value: temp2)
            }
            
            if line.totalCommutes!.intValue > 0 {
                var temp3 = Float(String(format: "%.02f", ((line.commutableFronts!.doubleValue + line.commutableBacks!.doubleValue) / line.totalCommutes!.doubleValue) * 100)) ?? 0.0
                if line.commutableBacks!.doubleValue == 0 && line.commutableFronts!.doubleValue == 0 {
                    temp3 = 0
                }
                line.commutabilityOverall = NSNumber(value: temp3)
            }
            else if workBlockCount == 0 {
                line.commutabilityOverall = NSNumber(value: 100)
                line.commutabilityFront = NSNumber(value: 100)
                line.commutabilityBack = NSNumber(value: 100)
            }
            else {
                line.commutabilityOverall = NSNumber(value: 100)
                line.commutabilityFront = NSNumber(value: 100)
                line.commutabilityBack = NSNumber(value: 100)
            }
        }
        try? CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!.save()
    }
    
    func fetchCommuteTimeWithBidPeriod(_ bidPeriod: BIBidPeriod) -> NSMutableArray {
        let fetchedObjects : NSArray  = (CBGlobalMethods.shared.selectedBidPeriod!.commuteTime ?? NSSet()).allObjects as NSArray
        return fetchedObjects.mutableCopy() as! NSMutableArray
    }
    
    func calculateIsTripFullyCommutable(line: BILine, and workblock: WorkBlockList) {
        var tripStartDate: Date!
        var workBlockStartDate: Date!
        var dateStatus = false
        for trip in line.orderedTrips as! [BITrip] {
            tripStartDate = self.getOnlyStartDateOfTrip(trip: trip)
            workBlockStartDate = self.getOnlyStartDateOfWorkBlock(date: workblock.startDateTime! as Date)
            dateStatus = self.daydateCheck(date: tripStartDate!, isBetweenDate: workBlockStartDate!, andDate: workblock.endDateOnly! as Date)
            if dateStatus {
                trip.info?.isFullyCommutable = NSNumber(booleanLiteral: true)
                trip.highlightCount = NSNumber(integerLiteral: trip.highlightCount!.intValue + 1)
            }
        }
    }
    
    func getOnlyStartDateOfTrip(trip: BITrip) -> Date {
        var startDate: Date!
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let dateComps = calendar.dateComponents(Set<Calendar.Component>([.year, .month, .day]), from: trip.startDate! as Date)
        startDate = calendar.date(from: dateComps)
        return startDate
    }
    
    func getOnlyStartDateOfWorkBlock(date: Date) -> Date {
        var startDate: Date!
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let dateComps = calendar.dateComponents(Set<Calendar.Component>([.year, .month, .day]), from: date)
        startDate = calendar.date(from: dateComps)
        return startDate
    }
    
    func daydateCheck(date: Date, isBetweenDate beginDate: Date, andDate endDate: Date) -> Bool {
        if date.compare(beginDate) == .orderedAscending {
            return false
        }
        if date.compare(endDate) == .orderedDescending {
            return false
        }
        return true
    }
    
    func calculateCommuteLinePropertiesForManualTrips(withDepartureMonThursText departureMonThursText: String, departureFriText: String, departureSatText: String, departureSunText: String, returnMonThursText: String, returnSunText: String, returnSatText: String, returnFriText: String, bidPeriod: BIBidPeriod, isFromSort:Bool = false) {

        let CommuteList : NSMutableArray = fetchCommuteTimeWithBidPeriod(bidPeriod)
        let formatterDate = DateFormatter()
        formatterDate.timeZone = TimeZone(secondsFromGMT: 0)!
        formatterDate.dateFormat = "yyyy-MM-dd"
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        if let timeZone = TimeZone(secondsFromGMT: 0) {
            calendar.timeZone = timeZone as TimeZone
        }
        
        for line in CBGlobalMethods.shared.selectedBidPeriod!.orderedLines(){
            line.commutableBacks = NSNumber(value: 0)
            line.commutableFronts = NSNumber(value: 0)
            line.commutabilityFront = NSNumber(value: 0)
            line.commutabilityBack = NSNumber(value: 0)
            line.commutabilityOverall = NSNumber(value: 0)
            
            for trip in line.orderedTripObjects() {
                if trip.dropForFiltersSorts?.intValue != 1 {
                    var isCommuteFrontEnd = false
                    var isCommuteBackEnd = false
                    
                    let tripStartDate : Date = getStartDate(trip: trip)!
                    let tripStartDateTakeOff : Date = getStartDatewithTakeOff(trip: trip)!
                    if line.number!.intValue == 38 {
                        print("")
                    }
                    let tripEndDate : Date = getEndDateOfTrip(trip: trip)!
                    let tripEndateOnly : Date = getOnlyEndDateOfTrip(trip: trip)!
                    trip.tripEndDay = getDayFromDate(date: tripEndateOnly as NSDate) as String?
                    
                    let filtered = CommuteList.filtered(using: NSPredicate(format: "bidDayStringValue == %@", "\(formatterDate.string(from: tripStartDate))"))
                    if filtered.count > 0 {
                        if let ObjcommuteTime = filtered[0] as? CommuteTime {
                            let datePlusMinute : Date = ObjcommuteTime.earliestArrivel!
                            let secondDate : Date = tripStartDateTakeOff
                            if secondDate >= datePlusMinute {
                                line.commutableFronts = (line.commutableFronts!.doubleValue  +  1) as NSNumber
                                isCommuteFrontEnd = true
                            }else if calendar.component(.hour, from: datePlusMinute) == 0 && calendar.component(.minute, from: datePlusMinute) == 0{
                                line.commutableFronts = (line.commutableFronts!.doubleValue  +  1) as NSNumber
                                isCommuteFrontEnd = true
                            }
                        }
                    }
                    
                    let EndDateList = CommuteList.filtered(using: NSPredicate(format: "bidDayStringValue == %@", "\(formatterDate.string(from: tripEndateOnly))"))
                    if EndDateList.count > 0 {
                        if let ObjcommuteTime = EndDateList[0] as? CommuteTime {
                            let datePlusMinute : Date = ObjcommuteTime.latestDeparture!
                            let secondDate : Date = tripEndDate
                            if secondDate <= datePlusMinute {
                                line.commutableBacks = (line.commutableBacks!.doubleValue  +  1) as NSNumber
                                isCommuteBackEnd = true
                            }
                            //Added by Akarsh one more condition to fix commute back issue
                            else if calendar.component(.hour, from: datePlusMinute) == 0 && calendar.component(.minute, from: datePlusMinute) == 0{
                                line.commutableBacks = (line.commutableBacks!.doubleValue  +  1) as NSNumber
                                isCommuteBackEnd = true
                            }
                        }
                    }
                    
                    
                    if isCommuteFrontEnd && isCommuteBackEnd && isFromSort {
                        trip.info?.isFullyCommutable = NSNumber(booleanLiteral: true)
                        trip.highlightCount = NSNumber(integerLiteral: trip.highlightCount!.intValue + 1)
                    }
                }
            }
            let tripCount = (line.orderedTripObjects() as NSArray).filtered(using: NSPredicate(format: "dropForFiltersSorts != 1")).count

            line.totalCommutes = NSNumber(value: tripCount * 2)
            if tripCount > 0 {
                let temp1 = Float(String(format: "%.02f", (line.commutableFronts!.doubleValue / Double(tripCount)) * 100)) ?? 0.0
                line.commutabilityFront = NSNumber(value: temp1)
            }
            if tripCount > 0 {
                let temp2 = Float(String(format: "%.02f", (line.commutableBacks!.doubleValue / Double(tripCount)) * 100)) ?? 0.0
                line.commutabilityBack = NSNumber(value: temp2)
            }
            if (line.totalCommutes!.intValue > 0) {
                var temp3 = Float(String(format: "%.02f", ((line.commutableFronts!.doubleValue + line.commutableBacks!.doubleValue) / line.totalCommutes!.doubleValue) * 100)) ?? 0.0
                if line.commutableBacks!.doubleValue == 0 && line.commutableFronts!.doubleValue == 0 {
                    temp3 = 0
                }
                line.commutabilityOverall = NSNumber(value: temp3)
            } else if tripCount == 0 {
                line.commutabilityOverall = NSNumber(value: 100)
                line.commutabilityFront = NSNumber(value: 100)
                line.commutabilityBack = NSNumber(value: 100)
            }else {
                line.commutabilityOverall = NSNumber(value: 100)
                line.commutabilityFront = NSNumber(value: 100)
                line.commutabilityBack = NSNumber(value: 100)
            }
        }
        try? CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!.save()
    }
    
    func getStartDate(trip: BITrip?) -> Date? {
        var startdate: Date? = nil
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        if let timeZone = TimeZone(secondsFromGMT: 0) {
            calendar.timeZone = timeZone as TimeZone
        }
        var dateComps = calendar.dateComponents([.year, .month, .day], from: trip!.startDate!)
        let dayInfo = trip!.info!.orderedDays().first
        var isInternationalCity = false
        var arrInternationalCities: NSMutableArray? = nil
        if let object1 = UserDefaults.standard.object(forKey: kCBInternationalCitiesList) as? [Any] {
            let object = NSMutableArray(array: object1)
            arrInternationalCities = object
        }
        if (dayInfo != nil) {
            let dayOrderedLegs = dayInfo!.orderedLegs
            let legInfo = dayOrderedLegs.first
            if let legInfo = legInfo {
                dateComps.minute = legInfo.departMinutes?.intValue
                startdate = calendar.date(from: dateComps)
                isInternationalCity = arrInternationalCities!.contains(legInfo.arriveCity!)
            }
        }
        var UpdateTime: Date?
        if isInternationalCity {
            UpdateTime = startdate!.addingTimeInterval(TimeInterval(Int(-internationalCityMinutes) * 60))
        } else {
            UpdateTime = startdate!.addingTimeInterval(TimeInterval(Int(-cityMinutes) * 60))
        }
        if trip!.info!.number![trip!.info!.number!.index(trip!.info!.number!.startIndex, offsetBy: 1)] >= "W" || trip!.info!.number![trip!.info!.number!.index(trip!.info!.number!.startIndex, offsetBy: 1)] >= "Y" {
            var dateCompsReserve = calendar.dateComponents([.year, .month, .day], from: trip!.startDate!)
            let departTime = trip!.info!.departTime!.intValue
            let time = String(format: "%04zd", departTime % 2400)
            let strHour = (time as NSString).substring(with: NSRange(location: 0, length: 2))
            let strMinute = (time as NSString).substring(with: NSRange(location: 2, length: time.count - strHour.count))
            dateCompsReserve.hour = Int(strHour) ?? 0
            dateCompsReserve.minute = Int(strMinute) ?? 0
            if let date = calendar.date(from: dateCompsReserve) {
                UpdateTime = date
            }
        }
        return UpdateTime
    }
    
    func getStartDatewithTakeOff(trip: BITrip?) -> Date? {
        var updateTime: Date? = nil
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        if let timeZone = TimeZone(secondsFromGMT: 0) {
            calendar.timeZone = timeZone as TimeZone
        }
        var dateComps = calendar.dateComponents([.year, .month, .day], from: trip!.startDate!)
        let dayInfo = trip!.info?.orderedDays().first
        if let dayInfo = dayInfo {
            let dayOrderedLegs = dayInfo.orderedLegs
            let legInfo = dayOrderedLegs.first
            if let legInfo = legInfo {
                dateComps.minute = legInfo.departMinutes!.intValue
                if let date = calendar.date(from: dateComps) {
                    updateTime = date
                }
            }
        }
        if trip!.info!.number![trip!.info!.number!.index(trip!.info!.number!.startIndex, offsetBy: 1)] >= "W" || trip!.info!.number![trip!.info!.number!.index(trip!.info!.number!.startIndex, offsetBy: 1)] >= "Y" {
            var dateCompsReserve = calendar.dateComponents([.year, .month, .day], from: trip!.startDate!)
            let departTime = trip!.info!.departTime!.intValue
            let time = String(format: "%04zd", departTime % 2400)
            let strHour = (time as NSString).substring(with: NSRange(location: 0, length: 2))
            let strMinutes = (time as NSString).substring(with: NSRange(location: 2, length: time.count - strHour.count))
            dateCompsReserve.hour = Int(strHour) ?? 0
            dateCompsReserve.minute = Int(strMinutes) ?? 0
            if let date = calendar.date(from: dateCompsReserve) {
                updateTime = date
            }
        }
        return updateTime
    }
    
    func getEndDateOfTrip(trip: BITrip?) -> Date? {
        var endDate: Date? = nil
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        if let timeZone = TimeZone(secondsFromGMT: 0) {
            calendar.timeZone = timeZone as TimeZone
        }
        var dateComps = calendar.dateComponents([.year, .month, .day], from: trip!.startDate!)
        let dayInfo = trip!.info?.orderedDays().last
        if dayInfo != nil {
            let dayOrderedLegs = dayInfo!.orderedLegs
            let legInfo = dayOrderedLegs.last
            if let legInfo = legInfo {
                dateComps.minute = legInfo.arriveMinutes?.intValue
                endDate = calendar.date(from: dateComps)
            }
        }
        if trip!.info!.number![trip!.info!.number!.index(trip!.info!.number!.startIndex, offsetBy: 1)] >= "W" || trip!.info!.number![trip!.info!.number!.index(trip!.info!.number!.startIndex, offsetBy: 1)] >= "Y" {
            var dateCompsReserve = calendar.dateComponents([.year, .month, .day], from: endDate!)
            let returnTime = trip!.info!.returnTime!.intValue
            let time = String(format: "%04zd", returnTime % 2400)
            let strHour = (time as NSString).substring(with: NSRange(location: 0, length: 2))
            let strMinute = (time as NSString).substring(with: NSRange(location: 2, length: time.count - strHour.count))
            dateCompsReserve.hour = Int(strHour)
            dateCompsReserve.minute = Int(strMinute)
            endDate = calendar.date(from: dateCompsReserve)
            let hour = dateCompsReserve.hour
            if hour! >= 0 && hour! <= 4 {
                var dateComponents = DateComponents()
                dateComponents.day = 1
                endDate = Calendar.current.date(byAdding: dateComponents, to: endDate!, wrappingComponents: false)
            }
        }
        return endDate
    }
    
    func getOnlyEndDateOfTrip(trip: BITrip?) -> Date? {
        var endDate: Date? = nil
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        if let timeZone = TimeZone(secondsFromGMT: 0) {
            calendar.timeZone = timeZone as TimeZone
        }
        let now = trip!.startDate
        let daysToAdd = Int(trip!.days!.count)
        let newDate = now!.addingTimeInterval(TimeInterval(60 * 60 * 24 * (daysToAdd - 1)))
        let dateComps = calendar.dateComponents([.year, .month, .day], from: newDate)
        endDate = calendar.date(from: dateComps)
        return endDate
    }
    
    func getDayFromDate(date: NSDate?) -> NSString? {
        let dateFormatterForDayname = DateFormatter()
        dateFormatterForDayname.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatterForDayname.dateFormat = "EEEE"
        let dayName = dateFormatterForDayname.string(from: date! as Date) as NSString
        return dayName
    }
}
