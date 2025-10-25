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
    var bidPeriod : BIBidPeriod!
    var connectTime : Int = 0
    var context = CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!
    var routeDomain : CBRouteDomain!
    
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
    
    func calculateCommutability(commuteCity: String, flightRoteDetails FlightRoteDetails: NSMutableArray, isNonStopOnly: Bool, bidperiod: BIBidPeriod, start startDate: Date, end endDate: inout Date, connectTime: Int) -> (Bool, String) {
        self.bidPeriod = bidperiod
        self.connectTime = connectTime
        if let commuteTimes = bidperiod.commuteTime?.allObjects as? [CommuteTime] {
            for time in commuteTimes {
                context.delete(time)
            }
        }
        let domicile = bidperiod.base!
        let daysToAdd = 3
        endDate = endDate.addingTimeInterval(TimeInterval(60 * 60 * 24 * daysToAdd))
        let depTimeHhMm = 301
        let arrTimeHhMm = 2700
        let depTime = (depTimeHhMm / 100 * 60) + (depTimeHhMm % 100)
        let arrTime = (arrTimeHhMm / 100 * 60) + (arrTimeHhMm % 100)
        
        var arrivalCount = 0
        var departureCount = 0
        
        let minDateString = "01/01/0001 00:00:00"
        let dateDormatt = DateFormatter()
        dateDormatt.timeZone = TimeZone(secondsFromGMT: 0)
        dateDormatt.locale = Locale.current
        dateDormatt.dateFormat = "MM/dd/yyyy hh:mm:ss"
        let minDate = dateDormatt.date(from: minDateString)
        
        var oneWeek = DateComponents()
        oneWeek.day = 1
        oneWeek.hour = 1
        var tepmStartDate = startDate
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        var count = 0
        while tepmStartDate.compare(endDate) == .orderedAscending || tepmStartDate.compare(endDate) == .orderedSame {
            let objCommuteTime = CommuteTime(context: context)
            let date = formatter.string(from: tepmStartDate)
            objCommuteTime.bidDay = tepmStartDate
            objCommuteTime.bidDayStringValue = date
            objCommuteTime.earliestArrivel = minDate
            objCommuteTime.latestDeparture = minDate
            objCommuteTime.commutable = bidperiod
            
            let tempArray = (FlightRoteDetails.filtered(using: NSPredicate(format: "FlightDate == %@", "\(date)T00:00:00")) as NSArray).mutableCopy() as! NSMutableArray
            
            //block 1
            //Calculating earliest arrivel time
            let nonConnect = getNonConnectFlightsForEarliestArrivalTime(withCommuteCity: commuteCity, domicile: domicile, date: "\(date)T00:00:00", dep: depTime, arr: arrTime, flightRoteDetailsArr: tempArray, bidperiod: bidperiod, connectTime: connectTime)
            
            let oneAndNonConnect: NSMutableArray = NSMutableArray()
            if nonConnect.count > 0 {
                oneAndNonConnect.addObjects(from: nonConnect as! [Any])
            }
            
            if isNonStopOnly != true {
                let oneConnect = getOneConnectFlightsForEarliestArrivalTime(withCommuteCity: commuteCity, domicile: domicile, date: "\(date)T00:00:00", dep: depTime, arr: arrTime, flightRoteDetailsArr: tempArray, bidperiod: bidperiod, connectTime: connectTime)
                if oneConnect.count > 0 {
                    oneAndNonConnect.addObjects(from: oneConnect as! [Any])
                }
            }
            
            if oneAndNonConnect.count != 0 && oneAndNonConnect.count > 0 {
                let sorteddoneAndNonConnect = oneAndNonConnect.sortedArray(using: [NSSortDescriptor(key: "RtArr", ascending: true)])
                self.routeDomain = sorteddoneAndNonConnect[0] as? CBRouteDomain
                objCommuteTime.earliestArrivel = addminutes(with: tepmStartDate, minutes: self.routeDomain.RtArr!.doubleValue)
            }
            else {
                arrivalCount += 1
                objCommuteTime.earliestArrivel = minDate
            }
            
            // block 2
            //Calculating earliest departure time
            // Warning : May need to add a sleep code here, refer crewbid iPad
//     MARK:       function name is diffrent from block 1
            let nonConnect1 = getNonConnectFlightsEarliestForDepartureTime(withCommuteCity: commuteCity, domicile: domicile, date: "\(date)T00:00:00", dep: depTime, arr: arrTime, flightRoteDetailsArr: tempArray, bidperiod: bidperiod, connectTime: connectTime)
            
//            union of oneConnect and NonConnect
            let oneAndNonConnect1: NSMutableArray = NSMutableArray()
            if nonConnect1.count > 0 {
                oneAndNonConnect1.addObjects(from: nonConnect1 as! [Any])
            }
            
            if isNonStopOnly != true {
                //     MARK:       function name is diffrent from block 1
                let oneConnect1 = getOneConnectFlightsForDepartureTime(withCommuteCity1: commuteCity, domicile: domicile, date: "\(date)T00:00:00", dep: depTime, arr: arrTime, flightRoteDetailsArr: tempArray, bidperiod: bidperiod, connectTime: connectTime)
                if oneConnect1.count > 0 {
                    oneAndNonConnect1.addObjects(from: oneConnect1 as! [Any])
                }
            }
            if oneAndNonConnect1.count != 0 && oneAndNonConnect1.count > 0 {
                let sortedoneAndNonConnect1 = (oneAndNonConnect1 as NSArray).sortedArray(using: [NSSortDescriptor(key: "RtDep", ascending: false)])
                routeDomain = sortedoneAndNonConnect1[0] as? CBRouteDomain
                objCommuteTime.latestDeparture = addminutes(with: tepmStartDate, minutes: routeDomain.RtDep!.doubleValue)
            }
            else {
                departureCount += 1
                objCommuteTime.latestDeparture = minDate
            }
            
            objCommuteTime.type = NSNumber(value: 0)
            let tempDate = Calendar.current.date(byAdding: oneWeek, to: tepmStartDate)
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone(secondsFromGMT: 0)!
            var comps: DateComponents = cal.dateComponents([.year, .month, .day], from: tempDate!)
            comps.hour = 0
            comps.minute = 0
            comps.second = 0
            
            if let date = cal.date(from: comps) {
                tepmStartDate = date
            }
            count += 1
        }
        let totalDays = CBUtils.noOfDaysBetweenDates(startDate: startDate, endDate: endDate)
        do {
            try context.save()
        }
        catch {
            print("error saving \(error.localizedDescription)")
        }
        if totalDays == departureCount && totalDays == arrivalCount {
            return (true, commuteCity)
        }
        return (false, commuteCity)
    }
    
    //    for block 1 earliest arrival
    func getNonConnectFlightsForEarliestArrivalTime(withCommuteCity commutecity: String, domicile: String, date: String, dep Cdep: Int, arr Carr: Int, flightRoteDetailsArr FlightRoteDetailsArr: NSMutableArray, bidperiod: BIBidPeriod, connectTime: Int) -> NSMutableArray {
        self.connectTime = connectTime
        let flightRouteArray: NSMutableArray = FlightRoteDetailsArr
        var routeDomainArray: NSMutableArray = NSMutableArray()
        let predicate = NSPredicate(format: "(Dest == %@) && (Orig == %@)", domicile, commutecity)
        let filtered = (flightRouteArray as NSArray).filtered(using: predicate)
        let nonconnect = (filtered as NSArray).filtered(using: NSPredicate(format: "(Carr <= %d) && (Cdep >= %d)", Carr, Cdep))
        
        for item in nonconnect {
            if let dic2 = item as? [String: Any] {
                let dep1 = (dic2["Cdep"] as? NSNumber)?.intValue ?? 0
                let arr1 = (dic2["Carr"] as? NSNumber)?.intValue ?? 0
                let routeDomain = CBRouteDomain()
                let dateString = dic2["FlightDate"] as? String
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale.current
                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)!
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                let date = dateFormatter.date(from: dateString ?? "")
                routeDomain.Date = date
                if let object = dic2["Orig"], let anObject = dic2["Dest"] {
                    routeDomain.Route = "\(object)-\(anObject)"
                }
                routeDomain.RtDep = dic2["Cdep"] as? NSNumber
                routeDomain.RtArr = dic2["Carr"] as? NSNumber
                routeDomain.RtTime = NSNumber(value: arr1 - dep1)
                routeDomainArray.add(routeDomain)
            }
        }
        routeDomainArray = (routeDomainArray.sortedArray(using: [NSSortDescriptor(key: "Route", ascending: true), NSSortDescriptor(key: "RtTime", ascending: true)]) as NSArray).mutableCopy() as! NSMutableArray
        return routeDomainArray
    }
    
//    for block 1 earliest arrival
    func getOneConnectFlightsForEarliestArrivalTime(withCommuteCity commutecity: String, domicile: String, date: String, dep Cdep: Int, arr Carr: Int, flightRoteDetailsArr FlightRoteDetailsArr: NSMutableArray, bidperiod: BIBidPeriod, connectTime: Int) -> NSMutableArray {
        self.connectTime = connectTime
        var oneConnectRouteDomainArray: NSMutableArray = NSMutableArray()
        let newFRD1: NSArray = FlightRoteDetailsArr.filtered(using: NSPredicate(format: "(Orig == %@) &&(Cdep >= %d)&&(Dest != %@) ", commutecity, Cdep, domicile)) as NSArray
        let newFRD2 : NSArray = FlightRoteDetailsArr.filtered(using: NSPredicate(format: "(Dest == %@) &&(Carr <= %d)", domicile, Carr)) as NSArray
        let filteredFinalArray: NSMutableArray = NSMutableArray()
        for item in newFRD1 {
            if let dic = item as? [String: Any] {
                var carr1 = (dic["Carr"] as? NSNumber)?.intValue ?? 0
                carr1 += connectTime
                let newAr: NSArray = newFRD2.filtered(using: NSPredicate(format: "(Orig == %@)&&((Cdep >= %d)||(RouteNum == %d))&&(Cdep > %d)", dic["Dest"] as! String, carr1, (dic["RouteNum"] as? NSNumber)?.intValue ?? 0, (dic["Cdep"] as? NSNumber)?.intValue ?? 0)) as NSArray
                if newAr.count > 0 {
                    for newDic in newAr {
                        let combinationsArray: NSMutableArray = NSMutableArray()
                        combinationsArray.add(dic)
                        combinationsArray.add(newDic)
                        filteredFinalArray.add(combinationsArray)
                    }
                }
            }
        }
        
        for item in filteredFinalArray {
            if let arr = item as? NSArray {
                let tempDict0 = arr[0] as! [String: Any]
                let tempDict1 = arr[1] as! [String: Any]
                let dep1 = (tempDict0["Cdep"] as? NSNumber)?.intValue ?? 0
                let arr2 = (tempDict1["Carr"] as? NSNumber)?.intValue ?? 0
                
                let routeDomain = CBRouteDomain()
                let date = self.date(fromDateString: (arr[0] as? [String : Any])!["FlightDate"] as? String, asFormat: "yyyy-MM-dd'T'HH:mm:ss")
                routeDomain.Date = date
                
                if let object = tempDict0["Orig"], let anObject = tempDict0["Dist"], let aAnOject = tempDict1["Dest"] {
                    routeDomain.Route = "\(object)-\(anObject)-\(aAnOject)"
                }
                routeDomain.RtDep = tempDict0["Cdep"] as? NSNumber
                routeDomain.RtArr = tempDict1["Carr"] as? NSNumber
                routeDomain.RtTime = NSNumber(value: arr2 - dep1)
                oneConnectRouteDomainArray.add(routeDomain)
            }
        }
        oneConnectRouteDomainArray = (oneConnectRouteDomainArray.sortedArray(using: [NSSortDescriptor(key: "Route", ascending: true), NSSortDescriptor(key: "RtTime", ascending: true)]) as NSArray).mutableCopy() as! NSMutableArray
        return oneConnectRouteDomainArray
    }
    
    func date(fromDateString dateString: String?, asFormat format: String?) -> Date? {
        var format = format
        if format == nil {
            format = "yyyy-MM-dd'T'HH:mm:ss"
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        let date = dateFormatter.date(from: dateString ?? "")
        return date
    }
    
    func addminutes(with CurrentDate: Date, minutes Minutes: Double) -> Date {
        let ModifiedDate = CurrentDate.addingTimeInterval(TimeInterval(Minutes * 60))
        return ModifiedDate
    }
    
    func calculateCommutabilityForCommuteDiff(commuteCity: String, flightRoteDetails FlightRoteDetails: NSMutableArray, isNonStopOnly: Bool, bidperiod: BIBidPeriod, start startDate: Date, end endDate: inout Date, connectTime: Int) -> (Bool, NSMutableArray) {
        let commuteArray = NSMutableArray()
        self.bidPeriod = bidperiod
        self.connectTime = connectTime
        let domicile = bidperiod.base!
        
        var daysToAdd = 3
        endDate = endDate.addingTimeInterval(TimeInterval(60 * 60 * 24 * daysToAdd))
        let depTimeHhMm = 301
        let arrTimeHhMm = 2700
        let depTime = (depTimeHhMm / 100 * 60) + (depTimeHhMm % 100)
        let arrTime = (arrTimeHhMm / 100 * 60) + (arrTimeHhMm % 100)
        var arrivalCount = 0
        var departureCount = 0
        
        let minDateString = "01/01/0001 00:00:00"
        let dateFormat = DateFormatter()
        dateFormat.timeZone = TimeZone(secondsFromGMT: 0)!
        dateFormat.locale = Locale.current
        dateFormat.dateFormat = "MM/dd/yyyy HH:mm:ss"
        let mindate = dateFormat.date(from: minDateString)
        
        var oneWeek = DateComponents()
        oneWeek.day = 1
        oneWeek.hour = 1
        var tempStartDate = startDate
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)!
        formatter.dateFormat = "yyyy-MM-dd"
        var count = 0
        
        while tempStartDate.compare(endDate) == .orderedAscending || tempStartDate.compare(endDate) == .orderedSame {
            var objCommuteTime = [String: Any]()
            let date = formatter.string(from: tempStartDate)
            objCommuteTime["bidDay"] = tempStartDate
            objCommuteTime["bidDayStringValue"] = date
            objCommuteTime["earliestArrivel"] = mindate
            objCommuteTime["latestDeparture"] = mindate
            objCommuteTime["commutable"] = bidperiod
            let tempArray = (FlightRoteDetails.filtered(using: NSPredicate(format: "FlightDate == %@", "\(date)T00:00:00")) as NSArray).mutableCopy() as! NSMutableArray
            
//            Block 1
//            calculating earliest Arrival Time
            let nonConnect = getNonConnectFlightsForEarliestArrivalTime(withCommuteCity: commuteCity, domicile: domicile, date: "\(date)T00:00:00", dep: depTime, arr: arrTime, flightRoteDetailsArr: tempArray, bidperiod: bidperiod, connectTime: connectTime)
            let oneAndNonConnect: NSMutableArray = NSMutableArray()
            if nonConnect.count > 0 {
                oneAndNonConnect.addObjects(from: nonConnect as! [Any])
            }
            
            if isNonStopOnly != true {
                let oneConnect = getOneConnectFlightsForEarliestArrivalTime(withCommuteCity: commuteCity, domicile: domicile, date: "\(date)T00:00:00", dep: depTime, arr: arrTime, flightRoteDetailsArr: tempArray, bidperiod: bidperiod, connectTime: connectTime)
                if oneConnect.count > 0 {
                    oneAndNonConnect.addObjects(from: oneConnect as! [Any])
                }
            }
            
            if oneAndNonConnect.count != 0 && oneAndNonConnect.count > 0 {
                let sortedOneAndNonConnect = oneAndNonConnect.sortedArray(using: [NSSortDescriptor(key: "RtArr", ascending: true)])
                self.routeDomain = sortedOneAndNonConnect[0] as? CBRouteDomain
                objCommuteTime["earliestArrivel"] = mindate
            }
            else {
                arrivalCount += 1
                objCommuteTime["earliestArrivel"] = mindate
            }
            
//            Block 2
            //Calculating earliest departure time
            // Warning : May need to add a sleep code here, refer crewbid iPad
            let nonConnect1 = getNonConnectFlightsEarliestForDepartureTime(withCommuteCity: commuteCity, domicile: domicile, date: "\(date)T00:00:00", dep: depTime, arr: arrTime, flightRoteDetailsArr: tempArray, bidperiod: bidperiod, connectTime: connectTime)
            
//            union of oneConnect and NonConnect
            let oneAndNonConnect1 = NSMutableArray()
            if nonConnect1.count > 0 {
                oneAndNonConnect1.addObjects(from: nonConnect1 as! [Any])
            }
            
            if isNonStopOnly != true {
                let oneConnect1 = getOneConnectFlightsForDepartureTime(withCommuteCity1: commuteCity, domicile: domicile, date: "\(date)T00:00:00", dep: depTime, arr: arrTime, flightRoteDetailsArr: tempArray, bidperiod: bidperiod, connectTime: connectTime)
                if oneConnect1.count > 1 {
                    oneAndNonConnect1.addObjects(from: oneConnect1 as! [Any])
                }
            }
            
            if oneAndNonConnect1.count != 0 && oneAndNonConnect1.count > 0 {
                let sortedOneAndNonConnect1 = oneAndNonConnect1.sortedArray(using: [NSSortDescriptor(key: "RtDep", ascending: false)])
                routeDomain = sortedOneAndNonConnect1[0] as? CBRouteDomain
                objCommuteTime["latestDeparture"] = addminutes(with: tempStartDate, minutes: routeDomain.RtDep!.doubleValue)
            }
            else {
                departureCount += 1
                objCommuteTime["latestDeparture"] = mindate
            }
            
            objCommuteTime["type"] = NSNumber(value: 0)
            let tempDate = Calendar.current.date(byAdding: oneWeek, to: tempStartDate)
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone(secondsFromGMT: 0)!
            
            var comps = cal.dateComponents([.year, .month, .day], from: tempDate!)
            comps.hour = 0
            comps.minute = 0
            comps.second = 0
            
            if let date = cal.date(from: comps) {
                tempStartDate = date
            }
            count += 1
            commuteArray.add(objCommuteTime)
        }
        
        let totalDays = CBUtils.noOfDaysBetweenDates(startDate: startDate, endDate: endDate)
        
        do {
            try self.context.save()
        }
        catch {
            print("error saving \(error.localizedDescription)")
        }
        if totalDays == departureCount && totalDays == arrivalCount {
            return (true, commuteArray)
        }
        return(false, commuteArray)
    }
    
    //    for block 2 latest departure
    func getNonConnectFlightsEarliestForDepartureTime(withCommuteCity commutecity: String, domicile: String, date: String, dep Cdep: Int, arr Carr: Int, flightRoteDetailsArr FlightRoteDetailsArr: NSMutableArray, bidperiod: BIBidPeriod, connectTime: Int) -> NSMutableArray {
        self.connectTime = connectTime
        var arr: NSMutableArray = NSMutableArray()
        let filtered = FlightRoteDetailsArr.filtered(using: NSPredicate(format: "(Dest == %@) && (Orig == %@)", commutecity, domicile))
        let nonconnect = (filtered as NSArray).filtered(using: NSPredicate(format: "(Carr <= %d) && (Cdep >= %d)", Carr, Cdep))
        for item in nonconnect {
            if let dic2 = item as? [String : Any]{
                let dep1 = (dic2["Cdep"] as? NSNumber)?.intValue ?? 0
                let arr1 = (dic2["Carr"] as? NSNumber)?.intValue ?? 0
                let routeDomain = CBRouteDomain()
                let date = self.date(fromDateString: dic2["FlightDate"] as? String, asFormat: "yyyy-MM-dd'T'HH:mm:ss")
                
                routeDomain.Date = date
                if let object = dic2["Orig"], let anObject = dic2["Dest"] {
                    routeDomain.Route = "\(object)-\(anObject)"
                }
                
                routeDomain.RtDep = dic2["Cdep"] as? NSNumber
                routeDomain.RtArr = dic2["Carr"] as? NSNumber
                routeDomain.RtTime = NSNumber(value: arr1 - dep1)
                arr.add(routeDomain)
            }
        }
        arr = (arr.sortedArray(using: [NSSortDescriptor(key: "Route", ascending: true), NSSortDescriptor(key: "RtTime", ascending: true)]) as NSArray).mutableCopy() as! NSMutableArray
        return arr
    }
    
//    for block 2 latest departure
    func getOneConnectFlightsForDepartureTime(withCommuteCity1 commutecity: String, domicile: String, date: String, dep Cdep: Int, arr Carr: Int, flightRoteDetailsArr FlightRoteDetailsArr: NSMutableArray, bidperiod: BIBidPeriod, connectTime: Int) -> NSMutableArray {
        var newArr: NSMutableArray = NSMutableArray()
        /*MARK:
         For calculating latestDeparture,
         we need to set the Orig as commute City and Dest as Domicile,
         for other cases we need to set Orig as Domicle and Dest as Commute city*/
        let newFRD1 = FlightRoteDetailsArr.filtered(using: NSPredicate(format: "(Orig == %@) &&(Cdep >= %d)&&(Dest != %@) ", domicile, Cdep, commutecity))
        let newFRD2 = FlightRoteDetailsArr.filtered(using: NSPredicate(format: "(Dest == %@) && (Carr <= %d)", commutecity , Carr))
        
        let filteredFinalArray: NSMutableArray = NSMutableArray()
        
        for item in newFRD1 {
            if let dic = item as? [String : Any] {
                var Carr1 = (dic["Carr"] as? NSNumber)?.intValue ?? 0
                Carr1 = Carr1 + connectTime
                let newAr: NSArray = (newFRD2 as NSArray).filtered(using: NSPredicate(format: "(Orig == %@)&&((Cdep >= %d)||(RouteNum == %d))&& (Cdep > %d)", dic["Dest"] as! String, Carr1, (dic["RouteNum"] as? NSNumber)?.intValue ?? 0, (dic["Cdep"] as? NSNumber)?.intValue ?? 0)) as NSArray
                
                if newAr.count > 0 {
                    for newDic in newAr {
                        let combinationsArray: NSMutableArray = NSMutableArray()
                        combinationsArray.add(dic)
                        combinationsArray.add(newDic)
                        filteredFinalArray.add(combinationsArray)
                    }
                }
            }
        }
        
        
        for item in filteredFinalArray {
            if let arr = item as? [[String : Any]] {
                let myDict0 = arr[0]
                let myDict1 = arr[1]
                let dep1 = (myDict0["Cdep"] as? NSNumber)?.intValue ?? 0
                let arr2 = (myDict1["Carr"] as? NSNumber)?.intValue ?? 0
                let routeDomain = CBRouteDomain()
                let date = self.date(fromDateString: myDict0["FlightDate"] as? String, asFormat: "yyyy-MM-dd'T'HH:mm:ss")
                routeDomain.Date = date
                if let object = myDict0["Orig"], let anObject = myDict0["Dest"], let aAnObject = myDict1["Dest"] {
                    routeDomain.Route = "\(object)-\(anObject)-\(aAnObject)"
                }
                routeDomain.RtDep = myDict0["Cdep"] as? NSNumber
                routeDomain.RtArr = myDict1["Carr"] as? NSNumber
                routeDomain.RtTime = NSNumber(value: arr2 - dep1)
                newArr.add(routeDomain)
            }
        }
        
        
        newArr = (newArr.sortedArray(using: [NSSortDescriptor(key: "Route", ascending: true), NSSortDescriptor(key: "RtTime", ascending: true)]) as NSArray).mutableCopy() as! NSMutableArray
        return newArr
    }
}
