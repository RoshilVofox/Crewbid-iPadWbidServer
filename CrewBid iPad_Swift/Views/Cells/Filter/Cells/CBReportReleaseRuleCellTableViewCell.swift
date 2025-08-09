//
//  CBReportReleaseRuleCellTableViewCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//736,1036,868

import UIKit
import CoreData

enum BIReportReleaseType: Int {
    case specific
    case all
}

//852, 862, 1857

let NUMBERS_ONLY = "1234567890"
let CHARACTER_LIMIT = 4

class CBReportReleaseRuleCellTableViewCell: UITableViewCell,UITextFieldDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var txtReport: UITextField!
    @IBOutlet weak var txtRelease: UITextField!
    @IBOutlet weak var btnCalculate: CBBorderToggleButton!
    @IBOutlet weak var btnChooseDate: CBBorderToggleButton!
    @IBOutlet weak var btnDelete: UIButton!
    @IBOutlet weak var viewAllDays: UIView!
    @IBOutlet weak var viewTripOrWorkDays: UIView!
    @IBOutlet weak var viewDates: UIView!
    @IBOutlet weak var allDaysCheckButton: UIButton!
    
    @IBOutlet weak var tripWorkBlkButton: UIButton!
    @IBOutlet weak var tripFirstButton: UIButton!
    @IBOutlet weak var tripLastButton: UIButton!
    @IBOutlet weak var noMidButton: UIButton!
    
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var calendarCollectionView: UICollectionView!
    
    var bidPeriod: BIBidPeriod?
    var filterRule: BIFilterRule?
    var calendarData: BICalendarData?
    var managedObjectContext: NSManagedObjectContext?
    var rptRlsType: BIReportReleaseType?
    let context = CBGlobalMethods.shared.selectedBidPeriod?.managedObjectContext
    var timeZoneStr: String?
    var reportReleaseArray: NSMutableArray?
    var isPreviousMonth: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.calendarCollectionView.delegate = self
        self.calendarCollectionView.dataSource = self
        self.calendarCollectionView.layer.cornerRadius = 3.0
        self.calendarCollectionView.layer.borderWidth = 0.5
        self.calendarCollectionView.layer.borderColor = UIColor.lightGray.cgColor
        lblTitle.layer.borderWidth = 1.0
        lblTitle.layer.borderColor = UIColor.black.cgColor
        txtRelease.tag = 11
        txtReport.delegate = self
        txtRelease.delegate = self
        txtReport.keyboardType = .numberPad
        txtRelease.keyboardType = .numberPad
        btnCalculate.isSelected = true
        bidPeriod = CBGlobalMethods.shared.selectedBidPeriod
        
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTapGesture(_:)))
        self.calendarCollectionView.addGestureRecognizer(tapGesture)
        self.timeZoneStr = CBUtils.rawTimeZoneString(forAirportCode: self.bidPeriod!.base!)
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @IBAction func deleteCellRow(_ sender: Any) {
        for case let line as BILine in self.bidPeriod!.lines! {
            line.rlsGreaterThanEntered = NSNumber(value: false)
            line.rptLessThanentered = NSNumber(value: false)
        }
        try? context?.save()
        txtReport.text = ""
        txtRelease.text = ""
        if (self.filterRule?.ruleHighlightsTrips() == true) {
            self.filterRule?.deHighlightTrips()
        }
        context?.delete(self.filterRule!)
//        if (self.allDaysCheckButton.isSelected) {
//            self.multiplReportReleaseAllDays()
//        }
//        else if (dateButton.isSelected) {
//            self.multiplReportReleaseDates()
//        }
//        else {
//            self.multiplReportRelease()
//        }
        try? context?.save()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }
    }
    
    func handleExistingCases() {
        let variables = NSMutableDictionary(dictionary: filterRule!.variables!)
        let strReport = variables[BIFilterRuleReportVariablesKey] as? String ?? ""
        let strRelease = variables[BIFilterRuleReleaseVariablesKey] as? String ?? ""
        let isFirstChecked = (variables[BIFilterRuleCheckStateIsFirstVariablesKey] as? Bool)
        let isLastChecked = (variables[BIFilterRuleCheckstateIsLastVariablesKey] as? Bool)
        let isNoMidChecked = (variables[BIFilterRuleCheckstateIsNoMidVariablesKey] as? Bool)
        let isAllDays = (variables["isAllDays"] as? Bool)
        let isCalendar = (variables["isCalendar"] as? Bool)
        if strReport.count > 1 {
            txtReport.text = strReport
        }
        if strRelease.count > 1 {
            txtRelease.text = strRelease
        }
        if isAllDays == true {
            rptRlsType = BIReportReleaseType.all
            self.selectAllDays()
        }
        else if isCalendar == true {
            self.selectDates()
        }
        else {
            rptRlsType = BIReportReleaseType.specific
            self.selectTripOrWorkBlock()
        }
        if isFirstChecked == true {
            self.tripFirstButton.isSelected = true
        }
        else {
            self.tripFirstButton.isSelected = false
        }
        if isLastChecked == true {
            self.tripLastButton.isSelected = true
        }
        else {
            self.tripLastButton.isSelected = false
        }
        if isNoMidChecked == true {
            self.noMidButton.isSelected = true
        }
        else {
            self.noMidButton.isSelected = false
        }
        if (self.bidPeriod?.isReportReleaseFilterApplied?.boolValue == true) {
            var textField = UITextField()
            if txtReport.text?.count == 4 && txtRelease.text?.count == 4 {
                textField = txtReport
                if (self.allDaysCheckButton.isSelected == true) {
                    self.multiplReportReleaseAllDays()
                }
                else {
                    self.multiplReportRelease()
                }
                self.bidPeriod?.isReportReleaseFilterApplied = false
            }
            else if txtReport.text?.count == 4 {
                textField = txtReport
                if (self.allDaysCheckButton.isSelected == true) {
                    self.multiplReportReleaseAllDays()
                }
                else {
                    self.multiplReportRelease()
                }
                self.bidPeriod?.isReportReleaseFilterApplied = false
            }
            else if txtRelease.text?.count == 4 {
                textField = txtRelease
                if (self.allDaysCheckButton.isSelected == true) {
                    self.multiplReportReleaseAllDays()
                }
                else {
                    self.multiplReportRelease()
                }
                self.bidPeriod?.isReportReleaseFilterApplied = false
            }
        }
    }
    
    func selectAllDays() {
        self.allDaysCheckButton.isSelected = true
        self.tripWorkBlkButton.isSelected = false
        self.tripFirstButton.isSelected = false
        self.tripLastButton.isSelected = false
        self.dateButton.isSelected = false
        self.btnChooseDate.isSelected = false
        self.noMidButton.isSelected = false
        self.collectionViewSetEnabled(enabled: false)
    }
    
    func selectDates() {
        self.allDaysCheckButton.isSelected = false
        self.tripWorkBlkButton.isSelected = false
        self.tripFirstButton.isSelected = false
        self.tripLastButton.isSelected = false
        self.dateButton.isSelected = true
        self.btnChooseDate.isSelected = true
        self.noMidButton.isSelected = false
        self.collectionViewSetEnabled(enabled: true)
    }
    
    func selectTripOrWorkBlock() {
        self.allDaysCheckButton.isSelected = false
        self.tripWorkBlkButton.isSelected = true
        self.tripFirstButton.isSelected = true
        self.tripLastButton.isSelected = true
        self.dateButton.isSelected = false
        self.btnChooseDate.isSelected = false
        self.noMidButton.isSelected = true
        self.collectionViewSetEnabled(enabled: false)
    }
    
    func collectionViewSetEnabled(enabled: Bool) {
        if enabled == true {
            self.calendarCollectionView.alpha = 1
            self.calendarCollectionView.isUserInteractionEnabled = true
        }
        else {
            self.calendarCollectionView.alpha = 0.5
            self.calendarCollectionView.isUserInteractionEnabled = false
        }
    }
    
    @IBAction func noMidBtnTapped(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        let variables = NSMutableDictionary(dictionary: filterRule!.variables!)
        variables["isNoMid"] = sender.isSelected
        variables["isCalendar"] = 0
        self.filterRule?.variables = variables
        try? context!.save()
    }
    
    @IBAction func tripLastBtnTapped(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        let variables = NSMutableDictionary(dictionary: filterRule!.variables!)
        variables["isCalendar"] = 0
        variables["isLast"] = sender.isSelected
        variables["isAllDays"] = 0
        self.filterRule?.variables = variables
        try? context!.save()
    }
    
    @IBAction func tripFirstBtnTapped(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        let variables = NSMutableDictionary(dictionary: filterRule!.variables!)
        variables["isCalendar"] = 0
        variables["isFirst"] = sender.isSelected
        variables["isAllDays"] = 0
        self.filterRule?.variables = variables
        try? context!.save()
    }
    
    @IBAction func tripWorkBlkBtnTapped(_ sender: UIButton) {
        self.selectTripOrWorkBlock()
        let variables = NSMutableDictionary(dictionary: filterRule!.variables!)
        variables["isCalendar"] = 0
        variables["isSelectedAll"] = 0
        variables["isAllDays"] = 0
        self.filterRule?.variables = variables
        try? context!.save()
    }
    
    @IBAction func allDaysBtnTapped(_ sender: UIButton) {
        self.selectAllDays()
        let variables = NSMutableDictionary(dictionary: filterRule!.variables!)
        variables["isCalendar"] = 1
        variables["isSelectedAll"] = 1
        variables["isAllDays"] = 0
        self.filterRule?.variables = variables
        try? context!.save()
    }
    
    @IBAction func dateBtnTapped(_ sender: UIButton) {
        self.selectDates()
        let variables = NSMutableDictionary(dictionary: filterRule!.variables!)
        variables["isCalendar"] = 1
        variables["isSelectedAll"] = 0
        variables["isAllDays"] = 0
        self.filterRule?.variables = variables
        try? context!.save()
    }
    
    
    func reportTimeForDay(day: BIDay, trip: BITrip, line: BILine) -> String {
        var report = String(format: "%04d", day.info!.reportTime!.intValue)
        if (self.bidPeriod?.isFABid() == true && self.bidPeriod!.isSecondRoundBid() && trip.isReserve) {
            report = BITrip.staticTimeForFAReserveType(trip: trip, line: line, key: "depart", timeZone: self.timeZoneStr!)!
        }
        return report
    }
    
    func releaseTimeForDay(day: BIDay, trip: BITrip, line: BILine) -> String {
        var release = String(format: "%04d", day.info!.releaseTime!.intValue)
        if (self.bidPeriod?.isFABid() == true && self.bidPeriod!.isSecondRoundBid() && trip.isReserve) {
            release = BITrip.staticTimeForFAReserveType(trip: trip, line: line, key: "arrive", timeZone: self.timeZoneStr!)!
        }
        return release
    }
    
    func compareReportTimeEntered(report: String, reportEntered: String) -> Bool {
        var isGreater = false
        var strReportHour = report
        strReportHour.insert(":", at: strReportHour.index(strReportHour.startIndex, offsetBy: 2))

        var strReportHourEntered = reportEntered
        strReportHourEntered.insert(":", at: strReportHourEntered.index(strReportHourEntered.startIndex, offsetBy: 2))
        let time1 = strReportHour
        let time2 = strReportHourEntered
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let date1 = formatter.date(from: time1)!
        let date2 = formatter.date(from: time2)!
        let result = date1.compare(date2)
        
        if result == .orderedDescending {
            isGreater = false
        }
        else if result == .orderedAscending {
            isGreater = true
        }
        else {
            isGreater = false
        }
        return isGreater
    }
    
    func compareReleaseTimeEntered(release: String, releaseEntered: String) -> Bool {
        var isGreater = false

        var strReleaseHour = release
        strReleaseHour.insert(":", at: strReleaseHour.index(strReleaseHour.startIndex, offsetBy: 2))

        var strReleaseHourEntered = releaseEntered
        strReleaseHourEntered.insert(":", at: strReleaseHourEntered.index(strReleaseHourEntered.startIndex, offsetBy: 2))

        let time1 = strReleaseHour
        var time2 = strReleaseHourEntered

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        let strGetReleaseHour = String(strReleaseHour.prefix(2))

        var date1 = formatter.date(from: time1)
        var date2 = formatter.date(from: time2)

        if let releaseValue = Int(release), releaseValue > 2400 {
            let strReleaseMinute = String(strReleaseHour.suffix(2))
            if let hour = Int(strGetReleaseHour) {
                let exactHour = hour - 24
                let exactDateTime = String(format: "%02d:%@", exactHour, strReleaseMinute)
                date1 = formatter.date(from: exactDateTime)

                if let date1Unwrapped = date1 {
                    date1 = Calendar.current.date(byAdding: .day, value: 1, to: date1Unwrapped)
                }
            }
        }

        if ["00", "01", "02", "03"].contains(strGetReleaseHour) {
            if let date1Unwrapped = date1 {
                date1 = Calendar.current.date(byAdding: .day, value: 1, to: date1Unwrapped)
            }
        }

        if let releaseEnteredValue = Int(releaseEntered) {
            if releaseEnteredValue >= 2400 && releaseEnteredValue < 2500 {
                strReleaseHourEntered.removeFirst(2)
                strReleaseHourEntered.insert(contentsOf: "00", at: strReleaseHourEntered.startIndex)
            } else if releaseEnteredValue >= 2500 && releaseEnteredValue < 2600 {
                strReleaseHourEntered.removeFirst(2)
                strReleaseHourEntered.insert(contentsOf: "01", at: strReleaseHourEntered.startIndex)
            } else if releaseEnteredValue >= 2600 && releaseEnteredValue < 2700 {
                strReleaseHourEntered.removeFirst(2)
                strReleaseHourEntered.insert(contentsOf: "02", at: strReleaseHourEntered.startIndex)
            } else if releaseEnteredValue == 2700 {
                strReleaseHourEntered.removeFirst(2)
                strReleaseHourEntered.insert(contentsOf: "03", at: strReleaseHourEntered.startIndex)
            }

            time2 = strReleaseHourEntered
            date2 = formatter.date(from: time2)

            if let date2Unwrapped = date2 {
                date2 = Calendar.current.date(byAdding: .day, value: 1, to: date2Unwrapped)
            }
        }

        if let d1 = date1, let d2 = date2 {
            let result = d1.compare(d2)
            if result == .orderedDescending {
                isGreater = true
            } else {
                isGreater = false
            }
        }

        return isGreater
    }

    func compareDates(firstDate: Date, secondDate: Date, trip: BITrip?) -> Bool {
        var missingRedEyeDate: Date?
        if trip?.isRedEyeTrip == true {
            missingRedEyeDate = CBUtils.findMissingDate(forRedEyeTrip: trip!)!
        }
        var isEqual = false
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        let strDate1 = formatter.string(from: firstDate)
        let strDate2 = formatter.string(from: secondDate)
        if strDate1 == strDate2 {
            isEqual = true
            if missingRedEyeDate != nil {
                let strDate3 = formatter.string(from: missingRedEyeDate!)
                if strDate1 == strDate3 {
                    isEqual = false
                }
            }
        }
        else {
            isEqual = false
        }
        return isEqual
    }
    
    @IBAction func buttonAction(_ sender: CBBorderToggleButton) {
        NotificationCenter.default.addObserver(self, selector: #selector(ReloadReportCollectionView(_:)), name: Notification.Name("ReloadReportCollectionView"), object: nil)
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let reportReleaseInformation = storyboard.instantiateViewController(withIdentifier: "CBReportReleaseCollectionViewController") as! CBReportReleaseCollectionViewController
        reportReleaseInformation.calendarData = self.calendarData
        reportReleaseInformation.filterRule = self.filterRule
        reportReleaseInformation.bidPeriod = self.bidPeriod
        reportReleaseInformation.modalPresentationStyle = .popover
        reportReleaseInformation.isModalInPresentation = true
        reportReleaseInformation.showPopover(sourceView: btnChooseDate)
        btnChooseDate.isSelected = true
        btnChooseDate.backgroundColor = UIColor.white
        btnChooseDate.tintColor = UIColor.white
    }
    
    @objc func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        NotificationCenter.default.addObserver(self, selector: #selector(ReloadReportCollectionView(_:)), name: Notification.Name("ReloadReportCollectionView"), object: nil)
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let reportReleaseInformation = storyboard.instantiateViewController(withIdentifier: "CBReportReleaseCollectionViewController") as! CBReportReleaseCollectionViewController
        reportReleaseInformation.calendarData = self.calendarData
        reportReleaseInformation.filterRule = self.filterRule
        reportReleaseInformation.bidPeriod = self.bidPeriod
        reportReleaseInformation.modalPresentationStyle = .popover
        reportReleaseInformation.isModalInPresentation = true
        reportReleaseInformation.showPopover(sourceView: btnChooseDate)
    }

//    notification handling
    @objc func ReloadReportCollectionView(_ notification: Notification) {
        let userInfo = notification.userInfo as! [String: Any]
        let value = userInfo["rptrlsType"] as? NSNumber
        if value?.intValue == 0 {
            self.rptRlsType = .specific
        }
        else {
            self.rptRlsType = .all
        }
        self.calendarCollectionView.reloadData()
        let variables = self.filterRule?.variables
        let arrDates = variables![BIFilterRuleSelectedDaysVariablesKey] as? NSArray
        if (arrDates!.count > 0) {
            for case let line as BILine in self.bidPeriod!.lines! {
                line.rlsGreaterThanEntered = NSNumber(value: false)
                line.rptLessThanentered = NSNumber(value: false)
            }
        }
        NotificationCenter.default.removeObserver(self, name: Notification.Name("ReloadReportCollectionView"), object: nil)
    }

    @IBAction func calculate(_ sender: UIButton) {
        if (txtReport.text?.count == 4 || txtRelease.text?.count == 4) {
            if (self.allDaysCheckButton.isSelected) {
                self.multiplReportReleaseAllDays()
            }
            else if (self.tripWorkBlkButton.isSelected) {
                self.multiplReportRelease()
            }
            else if (self.dateButton.isSelected) {
                self.multiplReportReleaseDates()
            }
        }
        else {
            AlertService.showAlertForTopVC(title: "Warning", message: "Enter the time in HHMM format")
            btnCalculate.isSelected = true
            btnCalculate.backgroundColor = UIColor.white
        }
    }
    
    func multiplReportReleaseDates() {
        for case let line as BILine in self.bidPeriod!.lines! {
            line.rlsGreaterThanEntered = NSNumber(value: false)
            line.rptLessThanentered = NSNumber(value: false)
        }
        let variables = NSMutableDictionary(dictionary: filterRule!.variables!)
        variables.setValue(self.txtReport.text, forKey: "reportValue")
        variables.setValue(self.txtRelease.text, forKey: "releaseValue")
        self.filterRule?.variables = variables
        let fetchRequest: NSFetchRequest<BIFilterRule> = BIFilterRule.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "category == 37")
        let fetchedObjects = try? context?.fetch(fetchRequest) ?? []
        if fetchedObjects!.count == 0 {
            
        }
        reportReleaseArray = NSMutableArray()
        for i in 0..<fetchedObjects!.count {
            if (fetchedObjects![i]).value(forKey: "variables") != nil {
                let variables = (fetchedObjects![i]).value(forKey: "variables") as? NSDictionary
                if variables?.value(forKey: "SELECTED_DATES") != nil {
                    let selectedDates = variables?.value(forKey: "SELECTED_DATES") as? NSArray
                    for j in 0..<selectedDates!.count {
                        var dict1 = [String: Any]()
                        dict1["date"] = selectedDates![j]
                        if variables?.object(forKey: "releaseValue") != nil {
                            dict1["releaseValue"] = variables?.object(forKey: "releaseValue")
                        }
                        if variables?.object(forKey: "reportValue") != nil {
                            dict1["reportValue"] = variables?.object(forKey: "reportValue")
                        }
                        self.reportReleaseArray!.add(dict1)
                    }
                }
            }
        }
//        calculate report release
        self.showActivityIndicator(color: CBColor.orange)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            var report = ""
            var release = ""
            for i in self.reportReleaseArray! {
                for case let line as BILine in self.bidPeriod!.lines! {
                    autoreleasepool {
                        if line.rptLessThanentered!.boolValue == false && line.rlsGreaterThanEntered!.boolValue == false {
                            for case let trip as BITrip in line.orderedTrips{
                                for day in trip.orderedDays {
                                    if (day.displayType!.intValue == BIDayDisplayType.fullPay.rawValue || day.displayType!.intValue == BIDayDisplayType.partialPay.rawValue || day.displayType!.intValue == BIDayDisplayType.noPay.rawValue) {
                                    }
                                    else {
                                        let dateString = "\((i as! NSDictionary).value(forKey: "date") ?? "") 12:53:58 +0000"
                                        let dateFormatter = DateFormatter()
                                        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss Z"
                                        guard let dateFromString = dateFormatter.date(from: dateString) else { return }

                                        let isSame = self.compareDates(firstDate: day.date!, secondDate: dateFromString, trip: trip)

                                        // check for report release available
                                        report = self.reportTimeForDay(day: day, trip: trip, line: line)
                                        release = self.releaseTimeForDay(day: day, trip: trip, line: line)

                                        if isSame {
                                            if !((i as! NSDictionary).value(forKey: "reportValue") as! String == "") {
                                                let isLesser = self.compareReportTimeEntered(report: report, reportEntered: (i as! NSDictionary).value(forKey: "reportValue") as! String)
                                                if isLesser {
                                                    line.rptLessThanentered = NSNumber(value: true)
                                                }
                                            }
                                            if !((i as! NSDictionary).value(forKey: "releaseValue") as! String == "") {
                                                if report > release {
                                                    line.rlsGreaterThanEntered = NSNumber(value: true)
                                                }
                                                else {
                                                    let isGreater = self.compareReportTimeEntered(report: release, reportEntered: (i as! NSDictionary).value(forKey: "releaseValue") as! String)
                                                    if isGreater {
                                                        line.rlsGreaterThanEntered = NSNumber(value: true)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            try? self.context?.save()
                        }
                    }
                }
                
            }
            self.hideActivityIndicator()
        }

    }
    
    
    func multiplReportRelease() {
        var reportReleaseInformation = CBReportReleaseCollectionViewController()
        reportReleaseInformation.calendarData = self.calendarData
        reportReleaseInformation.filterRule = self.filterRule
        reportReleaseInformation.bidPeriod = self.bidPeriod
        reportReleaseInformation.arrDatesSelected = NSMutableArray()
        reportReleaseInformation.tripOrWorkBlockOptionButton()
        
        for case let line as BILine in self.bidPeriod!.lines! {
            line.rlsGreaterThanEntered = NSNumber(value: false)
            line.rptLessThanentered = NSNumber(value: false)
        }
//        fetch all data for Report Release
        let fetchRequest: NSFetchRequest<BIFilterRule> = BIFilterRule.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "category == 37")
        let fetchedObjects = try? context?.fetch(fetchRequest) ?? []
        if fetchedObjects!.count == 0 {
            
        }
        reportReleaseArray = NSMutableArray()
        for i in 0..<fetchedObjects!.count {
            if (fetchedObjects![i]).value(forKey: "variables") != nil {
                let variables = (fetchedObjects![i]).value(forKey: "variables") as? NSDictionary
                if variables?.value(forKey: "SELECTED_DATES") != nil {
                    let selectedDates = variables?.value(forKey: "SELECTED_DATES") as? NSArray
                    for j in 0..<selectedDates!.count {
                        var dict1 = [String: Any]()
                        dict1["date"] = selectedDates![j]
                        if variables?.object(forKey: "releaseValue") != nil {
                            if (self.tripLastButton.isSelected) {
                                dict1["releaseValue"] = variables?.object(forKey: "releaseValue")
                            }
                            else {
                                dict1["releaseValue"] = ""
                            }
                        }
                        if variables?.object(forKey: "reportValue") != nil {
                            if (self.tripFirstButton.isSelected) {
                                dict1["reportValue"] = variables?.object(forKey: "reportValue")
                            }
                            else {
                                dict1["reportValue"] = ""
                            }
                        }
                        self.reportReleaseArray!.add(dict1)
                    }
                }
            }
        }
//        calculate report release
        self.showActivityIndicator(color: CBColor.orange)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            var report = ""
            var release = ""
            var reportValue = ""
            var releaseValue = ""
            if (self.reportReleaseArray?.count == 0) {
                reportValue = ""
                reportValue = ""
            }
            else {
                reportValue = ((self.reportReleaseArray![0]) as AnyObject).value(forKey: "reportValue") as! String
                releaseValue = ((self.reportReleaseArray![0]) as AnyObject).value(forKey: "releaseValue") as! String
            }
            for case let line as BILine in self.bidPeriod!.lines! {
                autoreleasepool {
                    let variables = NSMutableDictionary(dictionary: self.filterRule!.variables!)
                    variables.setValue(0, forKey: "isSelectedAll")
                    if (self.tripFirstButton.isSelected) {
                        variables.setValue(1, forKey: "isFirst")
                    }
                    else {
                        variables.setValue(0, forKey: "isFirst")
                    }
                    if (self.tripLastButton.isSelected) {
                        variables.setValue(1, forKey: "isLast")
                    }
                    else {
                        variables.setValue(0, forKey: "isLast")
                    }
                    
                    if line.rptLessThanentered?.boolValue == false && line.rlsGreaterThanEntered?.boolValue == false {
                        if (self.noMidButton.isSelected) {
                            variables.setValue(1, forKey: "isNoMid")
                            for case let workBlock as WorkBlockList in line.orderedWorkBlocks {
                                for case let day as BIDay in workBlock.orderedDays {
                                    if day.displayType?.intValue == BIDayDisplayType.fullPay.rawValue || day.displayType?.intValue == BIDayDisplayType.partialPay.rawValue || day.displayType?.intValue == BIDayDisplayType.noPay.rawValue {
                                    }
                                    else {
                                        let dateFormatter = DateFormatter()
                                        dateFormatter.dateFormat = "d-M-yyyy"
                                        dateFormatter.timeZone = TimeZone(identifier: "UTC")

                                        var dateStringReport = dateFormatter.string(from: workBlock.startDateTime!)
                                        var dateStringRelease = dateFormatter.string(from: workBlock.endDateOnly!)
                                        // Append the time string to each date string
                                        dateStringReport.append(" 12:53:58 +0000")
                                        dateStringRelease.append(" 12:53:58 +0000")

                                        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss Z"
                                        let dateFromStringReport: Date = dateFormatter.date(from: dateStringReport)!
                                        let dateFromStringRelease: Date = dateFormatter.date(from: dateStringRelease)!
                                        
                                        let isSameForReport = self.compareDates(firstDate: day.date!, secondDate: dateFromStringReport, trip: nil)
                                        let isSameForRelaese = self.compareDates(firstDate: day.date!, secondDate: dateFromStringRelease, trip: nil)
                                        
                                        report = self.reportTimeForDay(day: day, trip: day.trip!, line: line)
                                        release = self.releaseTimeForDay(day: day, trip: day.trip!, line: line)
                                        
                                        if isSameForReport {
                                            if !(reportValue == "") {
                                                let isLesser = self.compareReportTimeEntered(report: report, reportEntered: reportValue)
                                                if isLesser {
                                                    line.rptLessThanentered = NSNumber(value: true)
                                                }
                                            }
                                        }
                                        if isSameForRelaese {
                                            if !(releaseValue == "") {
                                                let isGreater = self.compareReleaseTimeEntered(release: release, releaseEntered: releaseValue)
                                                if isGreater {
                                                    line.rlsGreaterThanEntered = NSNumber(value: true)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        else {
                            variables.setValue(0, forKey: "isNoMid")
                            for case let trip as BITrip in line.orderedTrips {
                                for day in trip.orderedDays {
                                    if day.displayType?.intValue == BIDayDisplayType.fullPay.rawValue || day.displayType?.intValue == BIDayDisplayType.partialPay.rawValue || day.displayType?.intValue == BIDayDisplayType.noPay.rawValue {
                                    }
                                    else {
                                        let dateFormatter = DateFormatter()
                                        dateFormatter.dateFormat = "d-M-yyyy"
//                                        dateFormatter.timeZone = TimeZone(identifier: "UTC")
                                        
                                        var dateStringReport = dateFormatter.string(from: trip.startDate!)
                                        var dateStringRelease = dateFormatter.string(from: trip.endDate!)
                                        // Append the time string to each date string
                                        dateStringReport.append(" 12:53:58 +0000")
                                        dateStringRelease.append(" 12:53:58 +0000")
                                        
                                        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss Z"
                                        let dateFromStringReport: Date = dateFormatter.date(from: dateStringReport)!
                                        let dateFromStringRelease: Date = dateFormatter.date(from: dateStringRelease)!
                                        
                                        let isSameForReport = self.compareDates(firstDate: day.date!, secondDate: dateFromStringReport, trip: trip)
                                        let isSameForRelaese = self.compareDates(firstDate: day.date!, secondDate: dateFromStringRelease, trip: trip)
                                        
                                        report = self.reportTimeForDay(day: day, trip: trip, line: line)
                                        release = self.releaseTimeForDay(day: day, trip: trip, line: line)
                                        
                                        if isSameForReport {
                                            if !(reportValue == "") {
                                                let isLesser = self.compareReportTimeEntered(report: report, reportEntered: reportValue)
                                                if isLesser {
                                                    line.rptLessThanentered = NSNumber(value: true)
                                                }
                                            }
                                        }
                                        if isSameForRelaese {
                                            if !(releaseValue == "") {
                                                let isGreater = self.compareReleaseTimeEntered(release: release, releaseEntered: releaseValue)
                                                if isGreater {
                                                    line.rlsGreaterThanEntered = NSNumber(value: true)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        self.filterRule?.variables = variables
                        try? self.context!.save()
                    }
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
                self.hideActivityIndicator()
                self.calendarCollectionView.reloadData()
            }
        }
        
    }
    
    func multiplReportReleaseAllDays() {
        var reportReleaseInformation = CBReportReleaseCollectionViewController()
        reportReleaseInformation.calendarData = self.calendarData
        reportReleaseInformation.filterRule = self.filterRule
        reportReleaseInformation.bidPeriod = self.bidPeriod
        reportReleaseInformation.arrDatesSelected = NSMutableArray()
        reportReleaseInformation.allDaysOptionButton()
        
        for case let line as BILine in self.bidPeriod!.lines! {
            line.rlsGreaterThanEntered = NSNumber(value: false)
            line.rptLessThanentered = NSNumber(value: false)
        }
//        fetch all data for Report Release
        let fetchRequest: NSFetchRequest<BIFilterRule> = BIFilterRule.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "category == 37")
        let fetchedObjects = try? context?.fetch(fetchRequest) ?? []
        if fetchedObjects!.count == 0 {
            
        }
        reportReleaseArray = NSMutableArray()
        for i in 0..<fetchedObjects!.count {
            if (fetchedObjects![i]).value(forKey: "variables") != nil {
                let variables = (fetchedObjects![i]).value(forKey: "variables") as? NSDictionary
                if variables?.value(forKey: "SELECTED_DATES") != nil {
                    let selectedDates = variables?.value(forKey: "SELECTED_DATES") as? NSArray
                    for j in 0..<selectedDates!.count {
                        var dict1 = [String: Any]()
                        dict1["date"] = selectedDates![j]
                        if variables?.object(forKey: "releaseValue") != nil {
//                            if (self.tripLastButton.isSelected) {
                                dict1["releaseValue"] = variables?.object(forKey: "releaseValue")
                            }
                            else {
                                dict1["releaseValue"] = ""
//                            }
                        }
                        if variables?.object(forKey: "reportValue") != nil {
//                            if (self.tripFirstButton.isSelected) {
                                dict1["reportValue"] = variables?.object(forKey: "reportValue")
                            }
                            else {
                                dict1["reportValue"] = ""
//                            }
                        }
                        self.reportReleaseArray!.add(dict1)
                    }
                }
            }
        }
        // calculate report release
        self.showActivityIndicator(color: CBColor.orange)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
         var report = ""
            var release = ""
            for i in self.reportReleaseArray! {
                for case let line as BILine in self.bidPeriod!.lines! {
                    autoreleasepool {
                        if line.rptLessThanentered == false && line.rlsGreaterThanEntered == false {
                            for case let trip as BITrip in line.orderedTrips {
                                for day in trip.orderedDays {
                                    if (day.displayType!.intValue == BIDayDisplayType.fullPay.rawValue || day.displayType!.intValue == BIDayDisplayType.partialPay.rawValue || day.displayType!.intValue == BIDayDisplayType.noPay.rawValue) {
                                    }
                                    else {
                                        let dateFormatter = DateFormatter()
                                        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss Z"
                                        dateFormatter.timeZone = TimeZone(identifier: "UTC")
                                        let dateStr = (i as AnyObject).value(forKey: "date") as! String
                                        let dateString = dateStr + " 12:53:58 +0000"
                                        let dateFromString = dateFormatter.date(from: dateString)
                                        let isSame = self.compareDates(firstDate: day.date!, secondDate: dateFromString!, trip: trip)
//                                         check for report release available
                                        report = self.reportTimeForDay(day: day, trip: trip, line: line)
                                        release = self.releaseTimeForDay(day: day, trip: trip, line: line)
                                        
                                        if isSame {
                                            if !((i as AnyObject).value(forKey: "reportValue") as! String == "") {
                                                let isLesser = self.compareReportTimeEntered(report: report, reportEntered: ((i as AnyObject).value(forKey: "reportValue") as? String)!)
                                                if isLesser {
                                                    line.rptLessThanentered = NSNumber(value: true)
                                                }
                                            }
                                            if !((i as AnyObject).value(forKey: "releaseValue") as! String == "") {
                                                let isGreater = self.compareReleaseTimeEntered(release: release, releaseEntered: ((i as AnyObject).value(forKey: "releaseValue") as? String)!)
                                                if isGreater {
                                                    line.rlsGreaterThanEntered = NSNumber(value: true)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            let variables = NSMutableDictionary(dictionary: self.filterRule!.variables!)
            variables.setValue(1, forKey: "isSelectedAll")
            variables.setValue(0, forKey: "isFirst")
            variables.setValue(0, forKey: "isLast")
            variables.setValue(0, forKey: "isNoMid")
            self.filterRule?.variables = variables
            try? self.context!.save()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
                self.hideActivityIndicator()
                self.calendarCollectionView.reloadData()
            }
            
        }
    }
    
//    MARK: - Collection View Data Source
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.calendarData!.calendarDays.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let kDayCellIdentifer = "MiniCalendarCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kDayCellIdentifer, for: indexPath)
        let day: BICalendarDay = self.calendarData!.calendarDays[indexPath.row] as! BICalendarDay
        if day.isCurrentMonth {
            self.isPreviousMonth = false
        }
        if (day.text == "31" && self.bidPeriod?.month?.intValue == 2 && self.bidPeriod?.positionType?.intValue == BICrewPositionType.FlightAttendant.rawValue) {
            self.isPreviousMonth = false
        }
        if isPreviousMonth {
            cell.isUserInteractionEnabled = false
        }
        else {
            cell.isUserInteractionEnabled = true
        }
        let monthBits = (self.filterRule!.variables!["MONTH_BITS"] as? NSNumber)?.uint64Value
        let one: UInt64 = 1
        let mask = one << indexPath.row
        
        let viewTag = indexPath.row + 500
        let viewToAdd = calendarCollectionView.viewWithTag(viewTag)
        
        if (monthBits! & mask) != 0 {
            if viewToAdd == nil {
                self.addRedBubble(viewTag: viewTag, index: indexPath.row)
            }
        } else {
            if let viewToRemove = viewToAdd {
                self.configureMonthDayFilter(index: indexPath.row, addDay: false)
                viewToRemove.removeFromSuperview()
            }
        }
     return cell
    }
    
    func addRedBubble(viewTag: Int, index: Int) {
        guard let flowLayout = calendarCollectionView.collectionViewLayout as? UICollectionViewFlowLayout,
              let layoutAttributes = flowLayout.layoutAttributesForItem(at: IndexPath(item: index, section: 0)) else {
            return
        }

        let itemSize = flowLayout.itemSize
        let hInset = itemSize.height / 2.0
        let wInset = itemSize.width / 2.0
        let insets = UIEdgeInsets(top: hInset, left: wInset, bottom: hInset, right: wInset)

        let redSelectedFrame = CGRect(origin: layoutAttributes.frame.origin, size: itemSize)

        let redSelected = UIImageView(frame: redSelectedFrame)
        redSelected.tag = viewTag
        redSelected.layer.cornerRadius = 5.0
        redSelected.clipsToBounds = true
        redSelected.backgroundColor = UIColor(red: 24.0/255.0, green: 158.0/255.0, blue: 124.0/255.0, alpha: 1.0)

        let label = UILabel(frame: redSelected.bounds)
        label.textAlignment = .center
        label.textColor = .white
        label.backgroundColor = .clear

        redSelected.addSubview(label)

        // Optional image setup (not used directly in the view here):
        let buttonImage = UIImage(named: "TripButton-rounded-both-green")?.resizableImage(
            withCapInsets: insets,
            resizingMode: .stretch
        )

        // If needed, you could set this image to redSelected.image or backgroundView, etc.

        calendarCollectionView.addSubview(redSelected)
    }

    func configureMonthDayFilter(index: Int, addDay shouldAdd: Bool) {
        guard var monthBits = (self.filterRule!.variables!["MONTH_BITS"] as? NSNumber)?.uint64Value else {
            return
        }

        let one: UInt64 = 1
        let mask = one << index

        if shouldAdd {
            // Set bit
            monthBits |= mask
        } else {
            // Clear bit
            monthBits &= ~mask
        }
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
            
            // Calculate new length
            let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: string)
            
            // Define allowed character set (NUMBERS_ONLY)
            let allowedCharacters = CharacterSet(charactersIn: NUMBERS_ONLY)
            let characterSet = CharacterSet(charactersIn: string)
            
            return allowedCharacters.isSuperset(of: characterSet) && prospectiveText.count <= CHARACTER_LIMIT
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if !(textField.text == "") {
            if textField.text?.count == 4 {
                let variables = NSMutableDictionary(dictionary: self.filterRule!.variables!)
                if dateButton.isSelected {
                    let arrDates = variables[BIFilterRuleSelectedDaysVariablesKey]as? NSArray
                    if arrDates?.count == 0 {
                        textField.text = ""
                        AlertService.showAlertForTopVC(title: "Warning", message: "Please select the days from the calendar")
                        return
                    }
                }
//                try? context?.save()
                variables.setValue(txtReport.text, forKey: "reportValue")
                variables.setValue(txtRelease.text, forKey: "releaseValue")
                self.filterRule?.variables = variables
                try? context?.save()
            }
            else {
                AlertService.showAlertForTopVC(title: "Warning", message: "Enter the time in HHMM format")
            }
        }
    }
}
