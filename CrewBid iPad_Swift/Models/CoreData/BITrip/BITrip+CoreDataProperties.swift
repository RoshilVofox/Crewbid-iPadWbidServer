//
//  BITrip+CoreDataProperties.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/03/25.
//
//

import Foundation
import CoreData



extension BITrip {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BITrip> {
        return NSFetchRequest<BITrip>(entityName: "Trip")
    }

    @NSManaged public var bidListHighlighted: NSNumber?
    @NSManaged public var dropForFiltersSorts: NSNumber?
    @NSManaged public var endDate: Date?
    @NSManaged public var endDateOnly: Date?
    @NSManaged public var endWeekday: NSNumber?
    @NSManaged public var highlightCount: NSNumber?
    @NSManaged public var isReserveFa: NSNumber?
    @NSManaged public var number: String?
    @NSManaged public var position: NSNumber?
    @NSManaged public var positionString: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var startDay: NSNumber?
    @NSManaged public var startWeekday: NSNumber?
    @NSManaged public var tripEndDay: String?
    @NSManaged public var tripStartDay: String?
    @NSManaged public var vacationOverlapType: NSNumber?
    @NSManaged public var vBackVoPay: NSNumber?
    @NSManaged public var vFrontVoPay: NSNumber?
    @NSManaged public var days: NSSet?
    @NSManaged public var info: BITripInfo?
    @NSManaged public var legs: NSSet?
    @NSManaged public var line: BILine?
    @NSManaged public var lineFirstTrip: BILine?
    @NSManaged public var nextTrip: BITrip?
    @NSManaged public var previousTrip: BITrip?

}

// MARK: Generated accessors for days
extension BITrip {

    @objc(addDaysObject:)
    @NSManaged public func addToDays(_ value: BIDay)

    @objc(removeDaysObject:)
    @NSManaged public func removeFromDays(_ value: BIDay)

    @objc(addDays:)
    @NSManaged public func addToDays(_ values: NSSet)

    @objc(removeDays:)
    @NSManaged public func removeFromDays(_ values: NSSet)

}

enum BITripVacationOverlapType: Int {
    case none = 0
    case front
    case back
    case full
}


// MARK: Generated accessors for legs
extension BITrip {

    @objc(addLegsObject:)
    @NSManaged public func addToLegs(_ value: BILeg)

    @objc(removeLegsObject:)
    @NSManaged public func removeFromLegs(_ value: BILeg)

    @objc(addLegs:)
    @NSManaged public func addToLegs(_ values: NSSet)

    @objc(removeLegs:)
    @NSManaged public func removeFromLegs(_ values: NSSet)

}

extension BITrip : Identifiable {
    static func staticTimeForReserveType(trip: BITrip, line: BILine, key: String, timeZone: String) -> String? {
        guard let bidPeriod = line.bidPeriod else { return nil }
        if bidPeriod.isFirstRoundBid() || !bidPeriod.isFABid() || !trip.isReserve {
            return nil}
        let type = trip.line?.faReserveLineType?.intValue
        var timeStr: String?
        switch type {
        case BIFaReserveLineType.SnrAMres.rawValue:
            timeStr = (key == "depart") ? "0300" : "1100"
        case BIFaReserveLineType.SnrPMres.rawValue:
            timeStr = (key == "depart") ? "1000" : "1800"
        case BIFaReserveLineType.JnrAMres.rawValue:
            timeStr = (key == "depart") ? "0300" : "1500"
        case BIFaReserveLineType.JnrPMres.rawValue:
            timeStr = (key == "depart") ? "1000" : "2200"
        case BIFaReserveLineType.JnrLateRes.rawValue:
            timeStr = (key == "depart") ? "1500" : "0259"
        default:
            break
        }
        guard let timeStrUnwrapped = timeStr else { return nil }
        let timeZoneSetting = UserDefaults.standard.integer(forKey: kCBTimeZoneSetting)
        if timeZoneSetting == CBTimeZoneSetting.localTime.rawValue {
            return timeStrUnwrapped
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "HHmm"
        formatter.timeZone = TimeZone(identifier: timeZone)

        guard let localTime = formatter.date(from: timeStrUnwrapped) else {
            return nil
        }

        formatter.timeZone = TimeZone(identifier: "US/Central")
        return formatter.string(from: localTime)
    }
    
    var orderedDays: [BIDay] {
        let daysArray = (self.days as? Set<BIDay>) ?? []

        return daysArray.sorted { day1, day2 in
            let minDepart1 = day1.info?.legs?.compactMap { ($0 as? BILegInfo)?.departMinutes?.intValue }.min() ?? Int.max
            let minDepart2 = day2.info?.legs?.compactMap { ($0 as? BILegInfo)?.departMinutes?.intValue }.min() ?? Int.max
            return minDepart1 < minDepart2
        }
    }
    
    var redEyeCount: NSNumber {
        let myArray = legs?.allObjects
        let predicate = NSPredicate(format: "info.isRedEyeFlight == YES")
        let filteredArray = (myArray! as NSArray).filtered(using: predicate)
        return NSNumber(value: filteredArray.count)
    }


    
    var isRedEyeTrip: Bool {
        return redEyeCount.intValue > 0
    }

    func isAM() -> Bool {
        let StatusValue = 1
        return StatusValue == Int(truncating: info!.amPM!)
    }
    
    func isPM() -> Bool {
        let StatusValue = 2
        return StatusValue == Int(truncating: info!.amPM!)
    }
    
    var isReserve: Bool {
        if line?.bidPeriod?.isFABid() == true {
            return isReserveFa?.boolValue ?? false
        } else {
            if let number = info?.number, number.count > 1 {
                let index = number.index(number.startIndex, offsetBy: 1)
                return number[index] >= "W"
            }
            return false
        }
    }
    
    func tripText() -> String {
        return textForTrip(self, isFA: (line?.bidPeriod?.isFABid())!)
    }
    
    
    
    func textForTrip(_ trip: BITrip, isFA: Bool) -> String {
        var textForTrip = String()
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US")
        calendar.timeZone = TimeZone(identifier: "US/Central")!
        let df = DateFormatter()
        df.dateFormat = "ddMMMyy"
        df.timeZone = TimeZone(identifier: "US/Central")!
        var dateComps: DateComponents? = calendar.dateComponents([.year, .month, .day], from: trip.startDate! as Date)
        let date: Date? = trip.startDate as Date?
        
        if isFA {
            textForTrip += String(format: "Trip %@ dated %@   Position %@\n\n", trip.info?.number!.substring(to: 4) ?? "", df.string(from: date!), trip.isReserve ? "RESERVE" : (trip.positionString ?? ""))
                                     
        } else {
            let tripNo = trip.info!.number!.substring(to: 4)
            textForTrip += "Trip \(tripNo) dated \(df.string(from: date!))\n\n"
        }
        
        textForTrip += "Date  Flight  Depart   Arrive  Eqp Blk Grnd  Blk Duty  Cred\n\n"
        df.dateFormat = "ddMMM"
        let departFormatter = DateFormatter()
        departFormatter.dateFormat = "HHmm"
        let arriveFormatter = DateFormatter()
        arriveFormatter.dateFormat = "HHmm"
        var legFlight: String
        
        var departDate: Date?
        var arriveDate: Date?
        var blockMinutes: Int = 0
        var blockHours: Int = 0
        var blockTime: String
        var groundMinutes: Int = 0
        var groundHours: Int = 0
        var groundTime: String
        var dayBlockMinutes: Int = 0
        var report: String
        var release: String
        var layover: String
        var dayDutyMinutes: Int
        var dutyTime: String
        var tripBlockMinutes: Int = 0
        var tripDutyMinutes: Int = 0
        var tafbTime: String
        var departMinutes:CGFloat = 0
        var returnMinutes:CGFloat = 0
        

        //    NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];
        let tripOrderedDays: [BIDayInfo] = trip.info!.orderedDays()
        for (index, dayInfo) in tripOrderedDays.enumerated() {
            dayBlockMinutes = 0
            let dayOrderedLegs: [BILegInfo] = dayInfo.orderedLegs
            for (index2, legInfo) in dayOrderedLegs.enumerated() {
                // Leg is reserve if depart and arrive cities are the same.
                let isReserveLeg: Bool = (legInfo.departCity == legInfo.arriveCity)
                let isDeadheadLeg: Bool = legInfo.isDeadhead as! Bool
                // Reserve legs have block of 1 hour from bid info data, but should
                // have 0 block when displayed. Deadhead legs have 0 block as
                // parsed from bid info, but set to 0 here and also to set block
                // time string.
                if isReserveLeg || isDeadheadLeg {
                    blockMinutes = 0
                    blockTime = "  0"
                }
                else {
                    blockMinutes = Int(truncating: legInfo.blockMinutes as NSNumber)
                    blockHours = blockMinutes / 60
                    if 0 == blockHours {
                        blockTime = String(format: " %02zd", blockMinutes % 60)
                    }
                    else {
                        blockTime = "\(String(format: "%zd%02zd", blockHours, blockMinutes % 60))"
                    }
                }
                // Leg flight is always 6 characters and will have leading
                // whitespace. If deadhead, first two characters will be DH, which
                // should be removed.
                legFlight = legInfo.flight!
                
                dateComps?.minute = Int(truncating: legInfo.departMinutes!)
                departDate = calendar.date(from: dateComps!)
                dateComps?.minute = Int(truncating: legInfo.arriveMinutes!)
                arriveDate = calendar.date(from: dateComps!)
                // Ground time.
                groundMinutes = legInfo.groundMinutes.intValue
                if groundMinutes <= 0{
                    groundTime = "   0"
                } else {
                    groundHours = groundMinutes / 60
                    if 0 == groundHours {
                        groundTime = String(format: "  %02zd", groundMinutes % 60)
                    } else {
                        groundTime = String(format: "%2zd%02zd", Int(groundHours), groundMinutes % 60)
                    }
                }
                df.timeZone = CBUtils.timeZone(forAirportCode: legInfo.departCity!)
                departFormatter.timeZone = CBUtils.timeZone(forAirportCode: legInfo.departCity!)
                arriveFormatter.timeZone = CBUtils.timeZone(forAirportCode: legInfo.arriveCity!)
                let deadHead = legInfo.isDeadhead as! Bool
                let departCity = legInfo.departCity!
                let arriveCity = legInfo.arriveCity!
                let equipValue = legInfo.equipment!
                var equipment = ""
                if isReserve {
                    equipment = "   "
                } else if equipValue == "6" {
                    equipment = "8MX"
                } else if equipValue.isEmpty {
                    equipment = "000"
                } else {
                    equipment = "\(equipValue)00"
                }
                let result = (legFlight as NSString).utf8String
                
                let formattedLegFlight = String(format: "%4s", result!)
                if isFA{
                    if (legInfo.equipment == "6") {
                        textForTrip += "\(df.string(from: departDate!)) \(deadHead ? "DH" : "  ")\(formattedLegFlight) \(departCity) \(departFormatter.string(from: departDate!)) \(arriveCity) \(arriveFormatter.string(from: arriveDate!)) \("MAX") \(blockTime) \(groundTime) \((legInfo.isAircraftChange?.boolValue)! ? "acft change" : "           ") \(String(format:"%03.0f", (legInfo.pay?.floatValue)! * 100.0))\n"
                    }
                    else if legInfo.equipment == "   "{
                        textForTrip += "\(df.string(from: departDate!)) \(deadHead ? "DH" : "  ")\(formattedLegFlight) \(departCity) \(departFormatter.string(from: departDate!)) \(arriveCity) \(arriveFormatter.string(from: arriveDate!)) \(equipment) \(blockTime) \(groundTime) \((legInfo.isAircraftChange?.boolValue)! ? "acft change" : "           ") \(String(format:"%03.0f", (legInfo.pay?.floatValue)! * 100.0))\n"
                    }
                    else {
                        textForTrip += "\(df.string(from: departDate!)) \(deadHead ? "DH" : "  ")\(formattedLegFlight) \(departCity) \(departFormatter.string(from: departDate!)) \(arriveCity) \(arriveFormatter.string(from: arriveDate!)) \(equipment) \(blockTime) \(groundTime) \((legInfo.isAircraftChange?.boolValue)! ? "acft change" : "           ") \(String(format:"%03.0f", (legInfo.pay?.floatValue)! * 100.0))\n"
                    }
                }
                else{
                    textForTrip += "\(df.string(from: departDate!)) \(deadHead ? "DH" : "  ")\(formattedLegFlight) \(departCity) \(departFormatter.string(from: departDate!)) \(arriveCity) \(arriveFormatter.string(from: arriveDate!)) \(equipment) \(blockTime) \(groundTime) \((legInfo.isAircraftChange?.boolValue)! ? "acft change" : "           ") \(String(format:"%03.0f", (legInfo.pay?.floatValue)! * 100.0))\n"
                }
                dayBlockMinutes += blockMinutes
                
            }
            // Day summary (report and release times, layover city and duration,
            // block time, duty time, and pay).
            if tripOrderedDays[0] == dayInfo {
                dateComps?.minute = Int(truncating: dayOrderedLegs[0].departMinutes!) - Int(truncating: (trip.info?.briefMinutes)!)
            } else {
                dateComps?.minute = Int(truncating: dayOrderedLegs[0].departMinutes!) - Int(truncating: (trip.info?.debriefMinutes)!)
            }
            
            departFormatter.timeZone = CBUtils.timeZone(forAirportCode: (dayOrderedLegs.first)!.departCity!)
            arriveFormatter.timeZone = CBUtils.timeZone(forAirportCode: (dayOrderedLegs.last)!.arriveCity!)
            departDate = calendar.date(from: dateComps!)
            report = "Rpt \(departFormatter.string(from: departDate!))"
            
            //Release calcultions
            dateComps?.minute = Int(truncating: (dayOrderedLegs.last?.arriveMinutes)!) + Int(truncating: (trip.info?.debriefMinutes!)!)
            if isFA && trip.isReserve{
                dateComps?.minute = Int(truncating: (dayOrderedLegs.last?.arriveMinutes)!)
            }
            arriveDate = calendar.date(from: dateComps!)
            release = "Rls \(arriveFormatter.string(from: arriveDate!))"
       
            let tripInfoNumber:String = (trip.info?.number)!
            let index = tripInfoNumber.index(tripInfoNumber.startIndex, offsetBy: 1)
            let secondCharecter:Character = tripInfoNumber[index]
            if secondCharecter >= "W" {
                if !isFA {
                    
                    let departTimes = (trip.info?.departTime?.intValue)! % 2400
                    let departMins = (departTimes / 100) * 60 + departTimes % 100
                    dateComps?.minute = departMins
                    departFormatter.timeZone = CBUtils.timeZone(forAirportCode: ((dayOrderedLegs.first)?.departCity)!)
                    departDate = calendar.date(from: dateComps!)
                    report = "Rpt \(departFormatter.string(from: departDate!))"
                    
                    
                    let returnTimes = (trip.info?.returnTime?.intValue)! % 2400
                    let arriveMins = (returnTimes / 100) * 60 + returnTimes % 100
                    dateComps?.minute = arriveMins
                    arriveFormatter.timeZone = CBUtils.timeZone(forAirportCode: ((dayOrderedLegs.first)?.arriveCity)!)
                    arriveDate = calendar.date(from: dateComps!)
                    release = "Rls \(arriveFormatter.string(from: arriveDate!))"
                    
                    
                    let returnTimeString1 = String(format: "%04d", returnTimes % 2400)
                    let returnTimeString = NSMutableString(string: returnTimeString1)
                    returnTimeString.insert(":", at: 2)
                    
                    let departTimeString1 = String(format: "%04d", departTimes % 2400)
                    let departTimeString = NSMutableString(string: departTimeString1)
                    departTimeString.insert(":", at: 2)
                    
                    let zeroString = "00:00"
                    let departTime = departTimeString
                    let returnTime = returnTimeString
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "HH:mm"
                    let zeroDate: Date? = dateFormatter.date(from: zeroString)
                    
                   //Depart Minutes
                    let departOffsetDate: Date? = dateFormatter.date(from: departTime as String)
                    let departTimeDifference: TimeInterval? = departOffsetDate?.timeIntervalSince(zeroDate!)
                    departMinutes = CGFloat((departTimeDifference ?? 0.0) / 60)
                    
                    let returnOffsetDate: Date? = dateFormatter.date(from: returnTime as String)
                    let returnTimeDifference: TimeInterval? = returnOffsetDate?.timeIntervalSince(zeroDate!)
                    returnMinutes = CGFloat((returnTimeDifference ?? 0.0) / 60)
                }
            }
            if tripOrderedDays.last == dayInfo {
                // 12 spaces, if blank.
                layover = "            "
            } else {
                if self.isReserve {
                    let departAndReturnDifference: CGFloat = returnMinutes - departMinutes
                    groundMinutes = Int(1440 - departAndReturnDifference)
                    groundHours = groundMinutes / 60
                    groundTime = String(format: "%2zd%02zd", Int(groundHours), Int(groundMinutes) % 60)
                } else {
                    groundMinutes -= 2 * Int(truncating: (trip.info?.debriefMinutes!)!)
                    groundHours = groundMinutes / 60
                    groundTime = String(format: "%2zd%02zd", Int(groundHours), Int(groundMinutes) % 60)
                }
                layover = "L/O \(dayInfo.city!) \(groundTime)"
            }
            if 0 == dayBlockMinutes {
                blockTime = "  0"
            } else {
                blockTime = "\(String(format: "%zd%02zd", dayBlockMinutes / 60, dayBlockMinutes % 60))"
            }

            let component: DateComponents = calendar.dateComponents(Set<Calendar.Component>([ Calendar.Component.minute]), from: departDate!, to: arriveDate!)
            dayDutyMinutes = component.minute!
            
            
            // If the depart time is greater thn the arrive time,
            // dayDutyMinutes will be less than zero (-ve integer).
            // For avoiding this we are substracting 1 day (1440 minutes) from departTimeFirstLeg
            if dayDutyMinutes < 0 {
                let departTimeFirstLeg = dayInfo.departTimeFirstLeg!.intValue - 1440
                dateComps?.minute = departTimeFirstLeg
                departDate = calendar.date(from: dateComps!)
                dayDutyMinutes = calendar.dateComponents([.minute], from: departDate!, to: arriveDate!).minute!
            }
            
            if self.isReserve {
                let departAndReturnDifference: CGFloat = returnMinutes - departMinutes
                dayDutyMinutes = Int(departAndReturnDifference)
                dutyTime = String(format: "%2zd%02zd", dayDutyMinutes / 60, dayDutyMinutes % 60)
            } else {
                dutyTime = String(format: "%2zd%02zd", dayDutyMinutes / 60, dayDutyMinutes % 60)
            }
            textForTrip += "             \(report) \(release) \(layover)  \(blockTime) \(dutyTime)  \(String(format:"%4.0f", dayInfo.dayPayWithRig!.floatValue * 100.0))\n\n"
            tripBlockMinutes += dayBlockMinutes
            tripDutyMinutes += dayDutyMinutes
        }
        
        // Trip summary.
        if 0 == tripBlockMinutes {
            blockTime = "   0"
        } else {
            blockTime = String(format: "%2zd%02zd", tripBlockMinutes / 60, tripBlockMinutes % 60)
        }
        dutyTime = String(format: "%2zd%02zd", tripDutyMinutes / 60, tripDutyMinutes % 60)
        if self.isReserve {
            let a: Int = (Int(truncating: (trip.info?.dutyPeriodsCount)!) - 1) * 1440
            let lastlegArriveMinutes: Int = a + Int(returnMinutes)
            let tafbMinutes: Int = lastlegArriveMinutes - Int(departMinutes)
            tafbTime = String(format: "%2d%02d", tafbMinutes / 60, tafbMinutes % 60)
        } else {
            let tafbValue: CInt = trip.info?.tafbMinutes as! CInt
            tafbTime = String(format: "%2zd%02zd", tafbValue / 60, tafbValue % 60)
        }
        if let tafbInt = Int(tafbTime.trimmingCharacters(in: .whitespaces)), tafbInt < 0{
            tafbTime = "0   "
        }
        let number = trip.info?.number ?? ""
        let secondChar = number[number.index(number.startIndex, offsetBy: 1)]

        if secondChar == "P" || secondChar == "M" {
            let tafbPadding = String(repeating: " ", count: 8)
            let totalsPadding = String(repeating: " ", count: 20)

            let payValue = (isFA ? trip.info?.faPay?.floatValue ?? 0 : trip.info?.jsonPay?.floatValue ?? 0) * 100.0

            textForTrip += "\(tafbPadding)TAFB \(tafbTime)\(totalsPadding)Totals \(blockTime) \(dutyTime)  \(String(format: "%4.0f", payValue))"
        } else {
            // Padding spaces
            let tafbPrefix = String(repeating: " ", count: 8)
            let totalsSpacer = String(repeating: " ", count: 20)

            textForTrip += "\(tafbPrefix)TAFB \(tafbTime)\(totalsSpacer)Totals \(blockTime) \(dutyTime)  \(String(format: "%4.0f", (trip.info?.faPay?.floatValue ?? 0) * 100.0))"
        }
        return textForTrip
    }
    
    static func staticTimeForFAReserveType(trip: BITrip, line: BILine, key: String, timeZone: String) -> String? {
        if line.bidPeriod?.isFirstRoundBid() == true || !line.bidPeriod!.isFABid() == true || !trip.isReserve {
            return nil
        }
        let type = trip.line?.faReserveLineType?.intValue
        var timeStr: String?
        if type == BIFaReserveLineType.SnrAMres.rawValue {
            timeStr = key == "depart" ? "0300" : "1100"
        }
        else if type == BIFaReserveLineType.SnrPMres.rawValue {
            timeStr = key == "depart" ? "1000" : "1800"
        }
        else if type == BIFaReserveLineType.JnrAMres.rawValue {
            timeStr = key == "depart" ? "0300" : "1500"
        }
        else if type == BIFaReserveLineType.JnrPMres.rawValue {
            timeStr = key == "depart" ? "1000" : "2200"
        }
        else if type == BIFaReserveLineType.JnrLateRes.rawValue {
            timeStr = key == "depart" ? "1500" : "0259"
        }
        
        if UserDefaults.standard.integer(forKey: kCBTimeZoneSetting) == CBTimeZoneSetting.localTime.rawValue {
            return timeStr
        }
        let now = Date()
        var calendar = Calendar(identifier: .gregorian)
        var todayComps = calendar.dateComponents([.year, .month, .day], from: now)
        todayComps.hour = Int(timeStr!.prefix(2))
        todayComps.minute = Int(timeStr!.suffix(from: timeStr!.index(timeStr!.startIndex, offsetBy: 2)))
        
        calendar.timeZone = TimeZone(identifier: timeZone)!
        let sourceDate: Date = calendar.date(from: todayComps)!
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "HHmm"
        formatter.timeZone = TimeZone(identifier: "US/Central")
        
        let herbTimeString = formatter.string(from: sourceDate)
        return herbTimeString
    }
    
    
    static func resetTripHighlightCount(in context: NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<BITrip>(entityName: "Trip")
        fetchRequest.predicate = NSPredicate(format: "highlightCount > 0")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "info.number", ascending: true)]

        let fetchController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        do {
            try fetchController.performFetch()
            if let trips = fetchController.fetchedObjects {
                for trip in trips {
                    trip.highlightCount = 0
                    trip.bidListHighlighted = false
                }
            }
        } catch {
            print("Error executing trips fetch: \(error)")
        }
    }
    
    
    
}
