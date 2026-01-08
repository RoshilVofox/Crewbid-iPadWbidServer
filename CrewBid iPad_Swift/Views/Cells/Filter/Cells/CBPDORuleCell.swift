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
    var lastUpdatedDayValue: String?
    var lastUpdatedCityValue: String?
    
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
        if ((lastUpdatedDayValue == "Any Days" || lastUpdatedDayValue == "")  && (lastUpdatedCityValue == "Any Cities" || lastUpdatedCityValue == "")) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                NotificationCenter.default.post(name: NSNotification.Name("updateScrthPad"), object: nil)
            }
        }
    }
    
    func getLinesForFilterRule() {
        guard let rule = filterRule, let bid = bidPeriod else { return }
        
        for lineAny in bid.orderedLines() {
            if let line = lineAny as? BILine {
                line.isPdoFiltered = false
            }
        }
        
        let vars = rule.variables ?? [:]
        let dayValue = vars["DAY"] as? String ?? "Any Days"
        let city = vars[BIFilterRuleCityVariablesKey] as? String ?? "Any Cities"
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
            df.locale = Locale(identifier: "en_US_POSIX")
            df.timeZone = TimeZone(abbreviation: "UTC")
            filterDate = df.date(from: "\(dayValue)-\(year)")
        }
        
        let isAnyDay = dayValue.length == 0 || dayValue == "Any Days"
        let isAnyCity = city.length == 0 || city == "Any Cities"
        
        let isAtAfter: Bool
        if let comp = comparison?.intValue {
            isAtAfter = (comp == 1)
        } else {
            isAtAfter = true
        }
        
        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(abbreviation: "UTC")!
        
        for case let line as BILine in bid.lines! {
            
            //            filter out blank lines
            if ((!isAnyDay || !isAnyCity) && !bid.isFABid() && line.trips?.count == 0) {
                line.isPdoFiltered = true
                continue
            }
            
            var status = false
            var lineMatched = false // will be set YES if line satisfies filters
            
            for case let trip as BITrip in line.orderedTrips {
                let filterComp = utcCal.dateComponents([.year, .month, .day], from: filterDate ?? Calendar(identifier: .gregorian).date(from: DateComponents(year: 1997, month: 1, day: 1))!)
                let startComp = utcCal.dateComponents([.year, .month, .day], from: trip.startDate ?? Date())
                let endComp = utcCal.dateComponents([.year, .month, .day], from: trip.endDate ?? Date())
                
                let filterDay = utcCal.date(from: filterComp)
                let tripStartDay = utcCal.date(from: startComp)
                let tripEndDay = utcCal.date(from: endComp)
                
                var dayIndex = 0
                
                for dayInfo in trip.info!.orderedDays() {
                    let firstLeg = dayInfo.firstLeg
                    let lastLeg = dayInfo.orderedLegs.last
                    
                    let dayStartDate = tripStartDay?.addingTimeInterval(TimeInterval((firstLeg?.departMinutes?.intValue ?? 0) * 60))
                    let dayStartDateComp = utcCal.dateComponents([.year, .month, .day], from: dayStartDate ?? Date())
                    let tripComponents = utcCal.dateComponents([.year, .month, .day], from: trip.startDate ?? Date())
                    let tripStartOfDay = utcCal.date(from: tripComponents)
                    
                    let legDepartDate = tripStartOfDay?.addingTimeInterval(TimeInterval((firstLeg?.departMinutes?.intValue ?? 0) * 60))
                    let legArriveDate = tripStartOfDay?.addingTimeInterval(TimeInterval((lastLeg?.arriveMinutes?.intValue ?? 0) * 60))
                    
                    let dateCompArr = utcCal.dateComponents([.year, .month, .day, .hour, .minute], from: legArriveDate!)
                    let dateCompDep = utcCal.dateComponents([.year, .month, .day, .hour, .minute], from: legDepartDate!)
                    
                    var depMins = (dateCompDep.hour ?? 0) * 60 + (dateCompDep.minute ?? 0)
                    var arrMins = (dateCompArr.hour ?? 0) * 60 + (dateCompArr.minute ?? 0)
                    
                    var depCity = firstLeg?.departCity
                    var arrCity = lastLeg?.arriveCity
                    
                    if bid.isFABid() && bid.isSecondRoundBid() && trip.isReserveFa?.boolValue == true {
                        depMins = self.minutesForReserveTime(line: line, trip: trip, isAfter: false)
                        arrMins = self.minutesForReserveTime(line: line, trip: trip, isAfter: true)
                        depCity = bid.base
                        arrCity = bid.base
                    }
                    if isAnyDay {
                        if isAnyCity {
                            if !isAtAfter {
                                if (!trip.isRedEyeTrip && depMins < 180) {
                                    depMins = depMins + 1440
                                }
                                if depMins < filterMinutes {
                                    status = true
                                    lineMatched = true
                                    break
                                }
                            }
                            else if isAtAfter {
                                if depMins > arrMins {
                                    arrMins = arrMins + 1440
                                }
                                if arrMins > filterMinutes {
                                    status = true
                                    lineMatched = true
                                    break
                                }
                            }
                        }
                        else {
                            status = true
                            let isBaseCity = (city == bid.base)
                            if !isAtAfter {
                                let cityMatch = depCity == city
                                let timeMatch = depMins >= filterMinutes
                                
                                if ((isBaseCity && (cityMatch || timeMatch)) || (!isBaseCity && ( cityMatch && timeMatch))) {
                                    status = false
                                    lineMatched = true
                                    break
                                }
                            }
                            else if isAtAfter {
                                if depMins > arrMins {
                                    arrMins = arrMins + 1440
                                }
                                let cityMatch = arrCity == city
                                let timeMatch = arrMins <= filterMinutes
                                
                                if ((isBaseCity && (cityMatch || timeMatch)) || (!isBaseCity && ( cityMatch && timeMatch))) {
                                    status = false
                                    lineMatched = true
                                    break
                                }
                            }
                        }
                    }
                    else {
                        // Check Filter Date Condition
                        if (filterDate == nil) {
                            line.isPdoFiltered = true
                            continue
                        }
                        if filterDay?.compare(tripStartDay!) == .orderedAscending || filterDay?.compare(tripEndDay!) == .orderedDescending {
                            if (isAnyCity || (!isAnyCity && city == bid.base)) {
                                line.isPdoFiltered = false
                                continue
                            }
                        }
                        if trip.orderedDays.count == 1 && filterDay?.compare(tripStartDay!) != .orderedSame {
                            if (isAnyCity || (!isAnyCity && city == bid.base)) {
                                line.isPdoFiltered = false
                                continue
                            }
                        }
                        status = true
                        
                        let sameDay = (filterComp.year == dayStartDateComp.year && filterComp.month == dayStartDateComp.month  && filterComp.day == dayStartDateComp.day)
                        
                        if isAnyCity {
                            if !isAtAfter {
                                if (sameDay && (depMins >= filterMinutes)) {
                                    status = false
                                    lineMatched = true
                                    break
                                }
                            }
                            else if isAtAfter {
                                if (sameDay && (arrMins <= filterMinutes)) {
                                    if depMins > arrMins {
                                        arrMins = arrMins+1440
                                        
                                        if arrMins <= filterMinutes {
                                            //                                            condition for break the loop
                                            if trip.isRedEyeTrip {
                                                let nextLegDate = tripStartDay?.addingTimeInterval(TimeInterval((dayInfo.nextDay?.firstLeg?.departMinutes?.intValue ?? 0) * 60))
                                                let legComponents = utcCal.dateComponents([.month, .day], from: nextLegDate!)
                                                let filterComponents = utcCal.dateComponents([.month, .day], from: filterDate!)
                                                
                                                if legComponents.day == filterComponents.day && legComponents.month == filterComponents.month {
                                                    status = true
                                                }
                                                else {
                                                    status = false
                                                    lineMatched = true
                                                    break
                                                }
                                            }
                                            else {
                                                status = false
                                                lineMatched = true
                                                break
                                            }
                                        }
                                    }
                                    else {
                                        //                                        condition for break the loop
                                        if trip.isRedEyeTrip {
                                            let nextLegDate = tripStartOfDay?.addingTimeInterval(TimeInterval((dayInfo.nextDay?.firstLeg?.departMinutes?.intValue ?? 0) * 60))
                                            let legComponents = utcCal.dateComponents([.month, .day], from: nextLegDate!)
                                            let filterComponents = utcCal.dateComponents([.month, .day], from: filterDate!)
                                            if legComponents.day == filterComponents.day && legComponents.month == filterComponents.month {
                                                status = true
                                            }
                                            else {
                                                status = false
                                                lineMatched = true
                                                break
                                            }
                                        }
                                        else {
                                            status = false
                                            lineMatched = true
                                            break
                                        }
                                    }
                                }
                            }
                            
                            if (dayIndex == trip.info!.orderedDays().count - 1 && trip.isRedEyeTrip) {
                                let missingRedEyeDate = CBUtils.findMissingDate(forRedEyeTrip: trip)
                                if missingRedEyeDate != nil {
                                    let missingDayComponents = utcCal.dateComponents([.day, .month], from: missingRedEyeDate!)
                                    if missingDayComponents.day == filterComp.day && missingDayComponents.month == filterComp.month {
                                        if (isAnyCity || city == lastLeg?.arriveCity) {
                                            status = false
                                            lineMatched = true
                                            break
                                        }
                                    }
                                }
                            }
                        }
                        else {
                            if !isAtAfter {
                                let cityMach = depCity == city
                                let timeMatch = depMins >= filterMinutes
                                
                                if (sameDay && cityMach && timeMatch) {
                                    status = false
                                    lineMatched = true
                                    break
                                }
                            }
                            else if isAtAfter {
                                let cityMach = arrCity == city
                                if depMins > arrMins {
                                    arrMins = arrMins + 1440
                                }
                                let timeMatch = arrMins <= filterMinutes
                                
                                if sameDay && cityMach && timeMatch {
                                    if trip.isRedEyeTrip {
                                        let nextLegDate = tripStartOfDay?.addingTimeInterval(TimeInterval((dayInfo.nextDay?.firstLeg?.departMinutes?.intValue ?? 0) * 60))
                                        let legComponents = utcCal.dateComponents([.day, .month], from: nextLegDate!)
                                        let filterComponents = utcCal.dateComponents([.day, .month], from: filterDate!)
                                        
                                        if legComponents.day == filterComponents.day && legComponents.month == filterComponents.month {
                                            status = true
                                        }
                                        else {
                                            status = false
                                            lineMatched = true
                                            break
                                        }
                                    }
                                    else {
                                        status = false
                                        lineMatched = true
                                        break
                                    }
                                }
                            }
                        }
                    }
                    dayIndex += 1
                }
                line.isPdoFiltered = status as NSNumber
                if lineMatched == true {
                    break
                }
            }
        }
        lastUpdatedDayValue = dayValue
        lastUpdatedCityValue = city
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
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
//        }
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
        cities.removeAll { $0.caseInsensitiveCompare("Any Cities") == .orderedSame }
        cities.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        // Insert "Any Cities" at the first position
        cities.insert("Any Cities", at: 0)
        
        vc.menuItems = NSMutableArray(array: cities)
        vc.arrCellParameters = vc.menuItems
        vc.selectedValue = cityBtn.currentTitle ?? ""
        vc.modalPresentationStyle = .popover
        vc.showPopover(sourceView: sender)
    }

    
    @IBAction func deleteAction(_ sender: UIButton) {
        guard let filterRule = filterRule else { return }
        CBGlobalMethods.shared.selectedBidPeriod?.loadedPresetIdentifier = nil
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
        let timeZoneStr = CBUtils.rawTimeZoneString(forAirportCode: self.bidPeriod!.base!)
        
        if isAfter {
            let arriveHHMM = BITrip.staticTimeForReserveType(trip: trip, line: line, key: "arrive", timeZone: timeZoneStr!)
            if arriveHHMM != nil {
                let hourString = arriveHHMM?.substring(to: 2)
                let minuteString = arriveHHMM?.substring(to: 2)
                let hour = Int(hourString!)
                let minute = Int(minuteString!)
                
                let arriveMinutes = hour! * 60 + minute!
                return arriveMinutes
            }
        }
        else {
            let departHHMM = BITrip.staticTimeForReserveType(trip: trip, line: line, key: "arrive", timeZone: timeZoneStr!)
            if departHHMM != nil {
                let hourString = departHHMM?.substring(to: 2)
                let minuteString = departHHMM?.substring(to: 2)
                let hour = Int(hourString!)
                let minute = Int(minuteString!)
                
                let departMinutes = hour! * 60 + minute!
                return departMinutes
            }
        }
        return 0
    }
    
//    func findMissingDateAndIndexForRedEyeTrip(_ trip: BITrip?) -> (missingDate: Date?, missingIndex: Int?) {
//     
//        guard let trip = trip, trip.isRedEyeTrip == true else {
//            return (nil, nil)
//        }
//     
//        let calendar = Calendar(identifier: .gregorian)
//        var dateComps = calendar.dateComponents([.year, .month, .day], from: trip.startDate ?? Date())
//     
//        let df = DateFormatter()
//        df.dateFormat = "dd-MMM-yyyy"
//        df.timeZone = TimeZone(identifier: "US/Central")
//     
//        var tripDates: [String] = []
//     
//        
//        for dayInfo in trip.info?.orderedDays() ?? []{
//            if let firstLeg = dayInfo.orderedLegs.first {
//                dateComps.minute = Int(truncating: firstLeg.departMinutes ?? 0)
//                if let legStartDate = calendar.date(from: dateComps) {
//                    tripDates.append(df.string(from: legStartDate))
//                }
//            }
//        }
//     
//        
//        let uniqueDatesArray = Array(NSOrderedSet(array: tripDates)) as! [String]
//     
//        if uniqueDatesArray.isEmpty {
//            return (nil, nil)
//        }
//     
//       
//        let dateObjects: [Date] = uniqueDatesArray.compactMap { df.date(from: $0) }
//     
//        
//        for i in 0..<dateObjects.count - 1 {
//            let currentDate = dateObjects[i]
//            let nextDate = dateObjects[i + 1]
//     
//           
//            if let expectedDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
//                
//                if !calendar.isDate(expectedDate, inSameDayAs: nextDate) {
//                    return (expectedDate, i + 1)
//                }
//            }
//        }
//     
//        
//        return (nil, nil)
//    }
    
}
