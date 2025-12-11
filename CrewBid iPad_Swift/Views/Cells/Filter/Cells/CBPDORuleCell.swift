//
//  CBPDORuleCell.swift
//  CrewBid iPad_Swift
//
//  Created by Rishad on 09/12/25.
//

import UIKit

class CBPDORuleCell: UITableViewCell, RefreshDelegate {

    @IBOutlet weak var dayBtn: UIButton!
    @IBOutlet weak var cityBtn: UIButton!
    @IBOutlet weak var beforeOrAfterBtn: UIButton!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var TimeBtn: UIButton!
    @IBOutlet weak var Removecell: UIButton!

    var bidPeriod: BIBidPeriod?
    var calendarData: BICalendarData?
    var filterRule: BIFilterRule?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        NotificationCenter.default.addObserver(self, selector: #selector(filterViewWillDisappear), name: NSNotification.Name("FilterViewWillDisappear"), object: nil)
    }

    @objc func filterViewWillDisappear() { self.endEditing(true) }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        configurePartialDayOffCell()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        TimeBtn.setTitle("", for: .normal)
        beforeOrAfterBtn.setTitle("", for: .normal)
        cityBtn.setTitle("", for: .normal)
        dayBtn.setTitle("", for: .normal)
    }
    
    func configurePartialDayOffCell() {
        guard let filterRule = filterRule else { return }
        let vars = filterRule.variables ?? [:]
        
        let timeValue = (vars[BIFilterRuleValueVariablesKey] as? NSNumber)?.intValue ?? 0
        TimeBtn.setTitle(String(format: "%02d:%02d", timeValue / 60, timeValue % 60), for: .normal)

     
        let compNum = filterRule.comparison?.intValue ?? 1
        let compStr = (compNum == 2 || compNum == 3) ? "at-before" : "at-after"
        beforeOrAfterBtn.setTitle(compStr, for: .normal)

       
        let storedCity = vars["CITY"] as? String ?? ""
        let uiCity = storedCity.isEmpty ? "Any Cities" : storedCity
        cityBtn.setTitle(uiCity, for: .normal)

        
        let storedDay = vars["DAY"] as? String ?? ""
        let uiDay = storedDay.isEmpty ? "Any Days" : storedDay
        dayBtn.setTitle(uiDay, for: .normal)
    }

    func setFilterRule(_ filterRule: BIFilterRule?) {
        self.filterRule = filterRule
        getLinesForFilterRule()
    }
    
    func getLinesForFilterRule() {
        guard let rule = filterRule, let bid = bidPeriod else { return }
        
        for lineAny in bid.orderedLines() {
            if let line = lineAny as? BILine {
                line.isPdoFiltered = false
            }
        }
        
        let vars = rule.variables ?? [:]
        let dayValue = vars["DAY"] as? String ?? ""
        let city = vars[BIFilterRuleCityVariablesKey] as? String ?? ""
        let comparison = rule.comparison
        let filterMinutes = (vars[BIFilterRuleValueVariablesKey] as? NSNumber)?.intValue ?? 0
        
        var filterDate: Date? = nil
        if !dayValue.isEmpty && dayValue != "Any Days" {
            var year = bid.year?.intValue ?? 0
            if (bid.month?.intValue ?? 0) == 12 && dayValue.contains("Jan") {
                year += 1
            }
            let df = DateFormatter()
            df.dateFormat = "dd-MMM-yyyy"
            df.timeZone = TimeZone(abbreviation: "UTC")
            filterDate = df.date(from: "\(dayValue)-\(year)")
        }
        
        let checkCity = (!city.isEmpty && city != "Any Cities")
        let checkDate = (filterDate != nil)
       
        let isAtAfter: Bool
        if let comp = comparison?.intValue {
            isAtAfter = (comp == 1)
        } else {
            isAtAfter = true
        }

        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(abbreviation: "UTC")!
        
        for anyLine in bid.orderedLines() {
            guard let line = anyLine as? BILine else { continue }
         
            if (checkCity || checkDate),
               !bid.isFABid(),
               ((line.orderedTrips as? [BITrip])?.isEmpty ?? true) {
                line.isPdoFiltered = true
                continue
            }
            
            var lineMatched = false
            var allLegsMeetMinutes = true
            
            tripsLoop: for anyTrip in line.orderedTrips ?? [] {
                guard let trip = anyTrip as? BITrip else { continue }
                
                if (line.daysOff?.intValue ?? 0) > 0,
                   checkCity,
                   !checkDate,
                   city == bid.base {
                    continue
                }
                
                if let fd = filterDate, checkDate {
                    let filterComp = utcCal.dateComponents([.year, .month, .day], from: fd)
                    let startComp = utcCal.dateComponents([.year, .month, .day], from: trip.startDate ?? Date())
                    let endComp = utcCal.dateComponents([.year, .month, .day], from: trip.endDate ?? Date())
                    
                    let filterDay = utcCal.date(from: filterComp)!
                    let tripStartDay = utcCal.date(from: startComp)!
                    
                    var tripEndDay = utcCal.date(from: endComp)!
                    
                    if trip.isRedEyeTrip == true {
                        if let lastDay = trip.info?.orderedDays().last,
                           let firstLegOfLastDay = lastDay.orderedLegs.first {

                            let lastLegDepartMinutes = firstLegOfLastDay.departMinutes?.intValue

                            
                            tripEndDay = tripStartDay.addingTimeInterval(
                                TimeInterval((lastLegDepartMinutes ?? 0) * 60)
                            )
                        }
                    }
                    
                    if filterDay < tripStartDay || filterDay > tripEndDay {
                        if (line.isPdoFiltered as? Bool ?? false) && !checkCity {
                           
                            break
                        }
                        line.isPdoFiltered = false

                        if checkCity && city == bid.base {
                           
                        } else if !checkCity {
                           
                            continue
                        }
                    }
                }
                
                let tripComponents = utcCal.dateComponents([.year, .month, .day],
                                                           from: trip.startDate ?? Date())
                let tripStartOfDay = utcCal.date(from: tripComponents) ?? (trip.startDate ?? Date())
                
                for anyDay in trip.info?.orderedDays() ?? [] {
                    guard let dayInfo = anyDay as? BIDayInfo else { continue }

                    guard
                        let firstLegAny = dayInfo.orderedLegs.first,
                        let lastLegAny  = dayInfo.orderedLegs.last,
                        let firstLeg    = firstLegAny as? BILegInfo,
                        let lastLeg     = lastLegAny as? BILegInfo
                    else { continue }

                   
                    var legMinutes = isAtAfter
                        ? (lastLeg.arriveMinutes?.intValue ?? 0)
                        : (firstLeg.departMinutes?.intValue ?? 0)

                    var legCity = isAtAfter
                        ? (lastLeg.arriveCity ?? "")
                        : (firstLeg.departCity ?? "")

                    
                    if bid.isFABid(),
                       bid.isSecondRoundBid(),
                       trip.isReserveFa?.boolValue == true {
                        legMinutes = minutesForReserveTime(line: line, trip: trip, isAfter: isAtAfter)
                        legCity = bid.base ?? ""
                    }
                    
                    let dayStartDate = tripStartOfDay.addingTimeInterval(TimeInterval((firstLeg.departMinutes?.intValue ?? 0) * 60))

                   
                    let legDate = tripStartOfDay.addingTimeInterval(TimeInterval(legMinutes * 60))

                    let legHM = (utcCal.component(.hour, from: legDate) * 60) +
                                (utcCal.component(.minute, from: legDate))

                    
                    let startHM = (utcCal.component(.hour, from: dayStartDate) * 60) +
                                  (utcCal.component(.minute, from: dayStartDate))

                    
                    var correctedDate = legDate

                    if legHM < startHM {
                        correctedDate = utcCal.date(byAdding: .day, value: 1, to: legDate)!
                    }
                    var shifted: DateComponents
                    if bid.isFABid(),
                       bid.isSecondRoundBid(),
                       trip.isReserveFa?.boolValue == true {
                        shifted = shiftedDayComponents(for: correctedDate,
                                                           dayStartDate: dayStartDate,
                                                           calendar: utcCal)
                    }
                    else{
                        shifted = shiftedDayComponents(for: legDate,
                                                           dayStartDate: dayStartDate,
                                                           calendar: utcCal)
                    }
                    
                    let legDateMinutes = (shifted.hour ?? 0) * 60 + (shifted.minute ?? 0)
                    let legDay = shifted.day ?? 0
                    let legMonth = shifted.month ?? 0

                  
                    var dateCondition = true
                    if let fd = filterDate, checkDate {
                        var cal = Calendar(identifier: .gregorian)
                        cal.timeZone = TimeZone(abbreviation: "UTC")!

                        let filterComponents = cal.dateComponents([.day, .month], from: fd)
                        dateCondition = (legDay == filterComponents.day && legMonth == filterComponents.month)
                    }

                   
                    var cityCondition = true
                    if checkCity {
                        cityCondition = (legCity == city)
                    }

                   
                    let minutesCondition: Bool = isAtAfter
                        ? (legDateMinutes <= filterMinutes)
                        : (legDateMinutes >= filterMinutes)

                    if checkCity || checkDate {

                        if dateCondition {
                            
                            if cityCondition && minutesCondition {
                                
                                line.isPdoFiltered = false
                                lineMatched = true

                                
                                if !(trip.isRedEyeTrip) {
                                    break
                                }
                            } else {
                               
                                line.isPdoFiltered = true

                                
                                if checkDate {
                                    lineMatched = true
                                    break
                                }

                               
                                if (trip.isRedEyeTrip), isAtAfter {
                                    if let nextDay = dayInfo.nextDay,
                                       let nextFirstLegAny = nextDay.orderedLegs.first,
                                       let nextFirstLeg = nextFirstLegAny as? BILegInfo,
                                       let fd = filterDate {

                                        let nextLegDate = tripStartOfDay.addingTimeInterval(
                                            TimeInterval((nextFirstLeg.departMinutes?.intValue ?? 0) * 60)
                                        )

                                        var cal = Calendar(identifier: .gregorian)
                                        cal.timeZone = TimeZone(abbreviation: "UTC")!

                                        let legComponents = cal.dateComponents([.day, .month], from: nextLegDate)
                                        let filterComponents = cal.dateComponents([.day, .month], from: fd)

                                        if !(legComponents.day == filterComponents.day &&
                                             legComponents.month == filterComponents.month) {
                                           
                                            break
                                        }
                                    }
                                }
                            }

                        } else {
                           
                            if (line.daysOff?.intValue ?? 0) > 0,
                               checkCity,
                               !checkDate,
                               city == bid.base {
                               
                                line.isPdoFiltered = false
                            } else {
                                if trip.isRedEyeTrip {
                                    if lineMatched || (!dateCondition && cityCondition) {
                                        
                                        line.isPdoFiltered = false

                                        
                                        if !isAtAfter, !dateCondition, let fd = filterDate {
                                            let arrLegDate = tripStartOfDay.addingTimeInterval(
                                                TimeInterval((lastLeg.arriveMinutes?.intValue ?? 0) * 60)
                                            )

                                            var cal = Calendar(identifier: .gregorian)
                                            cal.timeZone = TimeZone(abbreviation: "UTC")!

                                            let legComponents = cal.dateComponents([.day, .month], from: arrLegDate)
                                            let filterComponents = cal.dateComponents([.day, .month], from: fd)

                                            if legComponents.day == filterComponents.day &&
                                                legComponents.month == filterComponents.month {
                                                line.isPdoFiltered = true
                                            }
                                        }
                                    } else {
                                        
                                        if checkCity, city == bid.base {
                                            line.isPdoFiltered = false
                                        } else {
                                            line.isPdoFiltered = true

                                            
                                            if isAtAfter, let fd = filterDate,
                                               let nextDay = dayInfo.nextDay,
                                               let nextFirstLegAny = nextDay.orderedLegs.first,
                                               let nextFirstLeg = nextFirstLegAny as? BILegInfo {

                                                let nextLegDate = tripStartOfDay.addingTimeInterval(
                                                    TimeInterval((nextFirstLeg.departMinutes?.intValue ?? 0) * 60)
                                                )

                                                var cal = Calendar(identifier: .gregorian)
                                                cal.timeZone = TimeZone(abbreviation: "UTC")!

                                                let legComponents = cal.dateComponents([.day, .month], from: nextLegDate)
                                                let filterComponents = cal.dateComponents([.day, .month], from: fd)

                                                if !(legComponents.day == filterComponents.day &&
                                                     legComponents.month == filterComponents.month) {
                                                    break
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    
                                    if checkCity, city == bid.base {
                                        line.isPdoFiltered = false
                                    } else {
                                        line.isPdoFiltered = true
                                    }
                                }
                            }
                        }

                    } else {
                        
                        if !minutesCondition {
                            allLegsMeetMinutes = false
                            break
                        }

                        
                        if (trip.isRedEyeTrip),
                           minutesCondition,
                           !isAtAfter {

                            let depLegDate = tripStartOfDay.addingTimeInterval(
                                TimeInterval((firstLeg.departMinutes?.intValue ?? 0) * 60)
                            )

                            var cal = Calendar(identifier: .gregorian)
                            cal.timeZone = TimeZone(abbreviation: "UTC")!

                            let legComponents = cal.dateComponents([.day, .month], from: depLegDate)

                            if legComponents.day == legDay {
                                allLegsMeetMinutes = true
                            } else {
                                allLegsMeetMinutes = false
                                break
                            }
                        }
                        
                        if (trip.isRedEyeTrip),
                           minutesCondition,
                           !isAtAfter {

                           
                            let depLegDateReal = tripStartOfDay.addingTimeInterval(
                                TimeInterval((firstLeg.departMinutes?.intValue ?? 0) * 60)
                            )

                            var cal = Calendar(identifier: .gregorian)
                            cal.timeZone = TimeZone(abbreviation: "UTC")!

                            let real = cal.dateComponents([.day, .month], from: depLegDateReal)

                            
                            if real.day != legDay || real.month != legMonth {
                                allLegsMeetMinutes = false
                                break
                            }
                        }

                    }
                }

               
                if (checkCity || checkDate), lineMatched {
                    break tripsLoop
                }
            }

            
            if !checkCity && !checkDate {
                line.isPdoFiltered = allLegsMeetMinutes ? false : true
            }
        }
    }

    func didSelected(itemName: String) {
        print("didSelected called with:", itemName)

        guard let filterRule = filterRule else { return }
        var vars = (filterRule.variables as? [String: Any]) ?? [:]

        
        if itemName.range(of: #"^\d{2}:\d{2}$"#, options: .regularExpression) != nil {
            let p = itemName.split(separator: ":")
            let total = (Int(p[0]) ?? 0) * 60 + (Int(p[1]) ?? 0)
            vars[BIFilterRuleValueVariablesKey] = total
            filterRule.variables = vars as NSDictionary
        }

      
        else if itemName == "at-after" || itemName == "at-before" {
            filterRule.comparison = NSNumber(value: itemName == "at-before" ? 3 : 1)
        }

      
        else if let cities = UserDefaults.standard.array(forKey: kCBAllCitiesList) as? [String],
                cities.contains(itemName) || itemName == "Any Cities" {

            
            vars["CITY"] = (itemName == "Any Cities") ? "" : itemName
            filterRule.variables = vars as NSDictionary
        }

       
        else {
           
            vars["DAY"] = (itemName == "Any Days") ? "" : itemName
            filterRule.variables = vars as NSDictionary
        }
        print("-> variables now:", filterRule.variables ?? [:], " comparison:", filterRule.comparison ?? "nil")

      
        getLinesForFilterRule()
        try? filterRule.managedObjectContext?.save()
        configurePartialDayOffCell()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }
    }


   
    @IBAction func dateSelectionAction(_ sender: UIButton) {
        guard let filterRule = filterRule else { return }
        let vc = UIStoryboard(name: "BidDocument", bundle: nil)
            .instantiateViewController(withIdentifier: "RefreshController") as! RefreshController

        vc.popOverType = .pdoValue
        vc.arrowDirection = .any
        vc.filterRule = filterRule
        vc.bidPeriod = bidPeriod ?? CBGlobalMethods.shared.selectedBidPeriod!
        vc.Delegate = self

        var list = ["Any Days"]
        if let cd = calendarData, let days = cd.calendarDays as? NSArray {
            let fmt = DateFormatter(); fmt.dateFormat = "dd-MMM"
            for i in 0..<days.count {
                if let d = cd.dateForIndex(index: i) { list.append(fmt.string(from: d)) }
            }
        }

        vc.menuItems = NSMutableArray(array: list)
        vc.arrCellParameters = NSMutableArray(array: list)
        vc.selectedValue = dayBtn.currentTitle ?? "Any Days"
        vc.modalPresentationStyle = .popover
        vc.showPopover(sourceView: sender)
    }
    
    @IBAction func timeSelectionAction(_ sender: UIButton) {
        guard let filterRule = filterRule else { return }

        let vc = UIStoryboard(name: "BidDocument", bundle: nil)
            .instantiateViewController(withIdentifier: "RefreshController") as! RefreshController

        vc.popOverType = .pdoValue
        vc.filterRule = filterRule
        vc.bidPeriod = bidPeriod ?? CBGlobalMethods.shared.selectedBidPeriod!
        vc.Delegate = self

        let s = (filterRule.variables?[BIFilterRuleRangeStartVariablesKey] as? Int) ?? 0
        let e = (filterRule.variables?[BIFilterRuleRangeEndVariablesKey] as? Int) ?? 1440
        let step = (filterRule.variables?[BIFilterRuleStepVariablesKey] as? Int) ?? 15
        let cur = (filterRule.variables?[BIFilterRuleValueVariablesKey] as? NSNumber)?.intValue ?? 0

        var menu: [String] = []
        var i = s
        while i <= e { menu.append(String(format: "%02d:%02d", i/60, i%60)); i += step }

        vc.menuItems = NSMutableArray(array: menu)
        vc.arrCellParameters = NSMutableArray(array: menu)
        vc.selectedValue = String(format: "%02d:%02d", cur/60, cur%60)
        vc.modalPresentationStyle = .popover
        vc.showPopover(sourceView: sender)
    }

   
    @IBAction func comparisonButtonSelected(_ sender: UIButton) {
        let vc = UIStoryboard(name: "BidDocument", bundle: nil)
            .instantiateViewController(withIdentifier: "RefreshController") as! RefreshController

        vc.popOverType = .pdoBeforeorAfter
        vc.filterRule = filterRule
        vc.Delegate = self
        vc.menuItems = NSMutableArray(array: ["at-after", "at-before"])
        vc.arrCellParameters = vc.menuItems
        vc.selectedValue = beforeOrAfterBtn.currentTitle ?? ""
        vc.modalPresentationStyle = .popover
        vc.showPopover(sourceView: sender)
    }

    
    @IBAction func cityButtonSelected(_ sender: UIButton) {
        let vc = UIStoryboard(name: "BidDocument", bundle: nil)
            .instantiateViewController(withIdentifier: "RefreshController") as! RefreshController

        vc.popOverType = .pdoCities
        vc.filterRule = filterRule
        vc.Delegate = self

        var cities = (UserDefaults.standard.array(forKey: kCBAllCitiesList) as? [String]) ?? []
        if !cities.contains("Any Cities") { cities.insert("Any Cities", at: 0) }

        vc.menuItems = NSMutableArray(array: cities)
        vc.arrCellParameters = vc.menuItems
        vc.selectedValue = cityBtn.currentTitle ?? ""
        vc.modalPresentationStyle = .popover
        vc.showPopover(sourceView: sender)
    }

    
    @IBAction func deleteAction(_ sender: UIButton) {
        guard let filterRule = filterRule else { return }

        if filterRule.ruleHighlightsTrips() { filterRule.deHighlightTrips() }
        CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!.delete(filterRule)
        try? bidPeriod?.managedObjectContext?.save()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }
    }
    
    func shiftedDayComponents(for date: Date,
                              dayStartDate: Date,
                              calendar: Calendar) -> DateComponents {
        
        var leg = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let start = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dayStartDate)
        
        let mins = (leg.hour ?? 0) * 60 + (leg.minute ?? 0)
        var total = mins
        
        var addNewDay = false
        
        if mins < 180 {
            addNewDay = true
        } else if let startDay = start.day, let legDay = leg.day, startDay < legDay {
            addNewDay = true
        }
        
        var yr = leg.year!
        var mo = leg.month!
        var dy = leg.day!
        
        if addNewDay {
            total += 1440
            
            if let prev = calendar.date(byAdding: .day, value: -1, to: date) {
                let p = calendar.dateComponents([.year, .month, .day], from: prev)
                yr = p.year!
                mo = p.month!
                dy = p.day!
            }
        }
        
        return DateComponents(year: yr,
                              month: mo,
                              day: dy,
                              hour: total / 60,
                              minute: total % 60)
    }

    func minutesForReserveTime(line: BILine, trip: BITrip, isAfter: Bool) -> Int {

       
        guard
            let firstDay = trip.info?.orderedDays().first,
            let firstLeg = firstDay.orderedLegs.first
        else {
            return 0
        }

    

        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US")
        calendar.timeZone = TimeZone(identifier: "US/Central")!

       
        var dateComps = calendar.dateComponents([.year, .month, .day],
                                                from: trip.startDate! as Date)

       
        let departFormatter = DateFormatter()
        departFormatter.dateFormat = "HHmm"
        departFormatter.timeZone = CBUtils.timeZone(forAirportCode: firstLeg.departCity!)

        let arriveFormatter = DateFormatter()
        arriveFormatter.dateFormat = "HHmm"
        arriveFormatter.timeZone = CBUtils.timeZone(forAirportCode: firstLeg.arriveCity!)

       
        dateComps.minute = Int(truncating: firstLeg.departMinutes!)
        let departDate = calendar.date(from: dateComps)!

      
        dateComps.minute = Int(truncating: firstLeg.arriveMinutes!)
        let arriveDate = calendar.date(from: dateComps)!

      
        let departHHMM = departFormatter.string(from: departDate)
        let arriveHHMM = arriveFormatter.string(from: arriveDate)

        
        if isAfter {
            
            let h = Int(arriveHHMM.prefix(2)) ?? 0
            let m = Int(arriveHHMM.suffix(2)) ?? 0
            return h * 60 + m
        } else {
            
            let h = Int(departHHMM.prefix(2)) ?? 0
            let m = Int(departHHMM.suffix(2)) ?? 0
            return h * 60 + m
        }
    }
    func findMissingDateAndIndexForRedEyeTrip(_ trip: BITrip?) -> (missingDate: Date?, missingIndex: Int?) {
     
        guard let trip = trip, trip.isRedEyeTrip == true else {
            return (nil, nil)
        }
     
        let calendar = Calendar(identifier: .gregorian)
        var dateComps = calendar.dateComponents([.year, .month, .day], from: trip.startDate ?? Date())
     
        let df = DateFormatter()
        df.dateFormat = "dd-MMM-yyyy"
        df.timeZone = TimeZone(identifier: "US/Central")
     
        var tripDates: [String] = []
     
        
        for dayInfo in trip.info?.orderedDays() ?? []{
            if let firstLeg = dayInfo.orderedLegs.first {
                dateComps.minute = Int(truncating: firstLeg.departMinutes ?? 0)
                if let legStartDate = calendar.date(from: dateComps) {
                    tripDates.append(df.string(from: legStartDate))
                }
            }
        }
     
        
        let uniqueDatesArray = Array(NSOrderedSet(array: tripDates)) as! [String]
     
        if uniqueDatesArray.isEmpty {
            return (nil, nil)
        }
     
       
        let dateObjects: [Date] = uniqueDatesArray.compactMap { df.date(from: $0) }
     
        
        for i in 0..<dateObjects.count - 1 {
            let currentDate = dateObjects[i]
            let nextDate = dateObjects[i + 1]
     
           
            if let expectedDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                
                if !calendar.isDate(expectedDate, inSameDayAs: nextDate) {
                    return (expectedDate, i + 1)
                }
            }
        }
     
        
        return (nil, nil)
    }
    
}
