//
//  CBReportReleaseCollectionViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 17/04/25.
//

import UIKit

class CBReportReleaseCollectionViewController: UIViewController, KUIPopOverUsable, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var calendarCollectionView: UICollectionView!
    
    var bidPeriod: BIBidPeriod?
    var filterRule: BIFilterRule?
    var calendarData: BICalendarData?
    var arrDatesSelected: NSMutableArray = NSMutableArray()
    var arrSelectedItemsCompare: NSMutableArray = NSMutableArray()
    var isPreviousMonth: Bool = true
    var rptRlsType: BIReportReleaseType = .specific
    var context = CBGlobalMethods.shared.selectedBidPeriod?.managedObjectContext
    override func viewDidLoad() {
        super.viewDidLoad()
        self.calendarCollectionView.delegate = self
        self.calendarCollectionView.dataSource = self
        self.calendarCollectionView.layer.borderWidth = 2.0
        self.calendarCollectionView.layer.borderColor = UIColor.black.cgColor
        isPreviousMonth = true
        
        // Remove any old redSelectedBubbles
        for i in 0..<(self.calendarData?.calendarDays.count)!{
            let viewTag = i + 500
            let viewToRemove = self.calendarCollectionView.viewWithTag(viewTag)
            if viewToRemove != nil {
                viewToRemove?.removeFromSuperview()
            }
        }
        self.calendarCollectionView.reloadData()
        var variables = self.filterRule?.variables
        let arrDates = variables?.object(forKey: BIFilterRuleSelectedDaysVariablesKey) as? NSArray
        if (!(arrDates?.count ?? 0 > 0)) {
            arrDatesSelected = NSMutableArray()
        }
        else {
            arrDatesSelected = (variables?.object(forKey: BIFilterRuleSelectedDaysVariablesKey) as? NSMutableArray)!
        }
        if arrDatesSelected.count > 0 {
            arrSelectedItemsCompare = NSMutableArray(array: arrDatesSelected)
        }
        
        let headerHeight: CGFloat = 15.0
        let headerWidth = calendarCollectionView.frame.size.width + 6.0
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: headerWidth, height: headerHeight))
        headerView.backgroundColor = CBColor.cellBackgroundColorVar
        headerView.alpha = 0.75

        let label = UILabel(frame: headerView.frame)
        label.backgroundColor = .clear
        label.frame.origin.y = 1.0
        label.font = UIFont(name: "Helvetica-Bold", size: 20)
        label.textColor = .black
        label.textAlignment = .center
        label.text = "S      M      T     W      T      F      S"

        headerView.addSubview(label)
        self.view.addSubview(headerView)

    }
    
    var contentSize: CGSize {
        return CGSize(width: 400.0, height: 250)
    }
    
    
    @IBAction func btnCloseAction(_ sender: Any) {
        var ischangedDays = false
        let variables = self.filterRule?.variables
        let arrDates = variables?.object(forKey: BIFilterRuleSelectedDaysVariablesKey) as? NSArray
        if !(arrDates!.count > 0) {
            arrDatesSelected.removeAllObjects()
        }
        if arrSelectedItemsCompare.count > 0 {
            let set1 = Set(arrDatesSelected as! [AnyHashable])
            let set2 = Set(arrSelectedItemsCompare as! [AnyHashable])
            
            if !(set1 == set2) {
                ischangedDays = true
                for case let line as BILine in self.bidPeriod!.lines! {
                    line.rlsGreaterThanEntered = NSNumber(value: false)
                    line.rptLessThanentered = NSNumber(value: false)
                }
                try? context?.save()
                arrSelectedItemsCompare.removeAllObjects()
            }
            else {
               ischangedDays = false
            }
            
        }
        let userInfo: [String: Any] = ["rptrlsType": self.rptRlsType, "ischangedDays": ischangedDays]
        NotificationCenter.default.post(name: NSNotification.Name("ReloadReportCollectionView"), object: nil, userInfo: userInfo)
//        print("ia, here")
        self.dismissPopover(animated: true)
    }
    
    @IBAction func btnClearAction(_ sender: Any) {
        // Remove any old redSelectedBubbles
        self.rptRlsType = .specific
        for view in calendarCollectionView.subviews {
            if view.tag > 499 {
                view.removeFromSuperview()
            }
        }
//        Remove the sorting by the days of the month
        var monthBits: UInt64 = self.filterRule!.variables!["MONTH_BITS"] as? UInt64 ?? 0
        monthBits = 0
        let MONTH_BITS = NSNumber(value: monthBits)
        
        self.filterRule?.variables = ["MONTH_BITS": MONTH_BITS]
        let variables = NSMutableDictionary(dictionary: filterRule!.variables!)
        var arrDates = variables[BIFilterRuleSelectedDaysVariablesKey] as? [Any]
        arrDates = []
        variables[BIFilterRuleSelectedDaysVariablesKey] = arrDates
        variables["isSelectedAll"] = 0
        variables["isCalendar"] = 1

        self.filterRule?.variables = variables

        arrDatesSelected.removeAllObjects()

    }
    
    @IBAction func btnSelectAllAction(_ sender: Any) {
        self.arrDatesSelected.removeAllObjects()
        self.rptRlsType = .all
        for i in 0..<(self.calendarData?.calendarDays.count)!{
            var strDay = ""
            let index = i
            let viewTag = index + 500
            let day: BICalendarDay = (self.calendarData?.calendarDays[i] as? BICalendarDay)!
            
            if (day.text == "31" && self.bidPeriod?.month?.intValue == 2 && self.bidPeriod?.positionType?.intValue == BICrewPositionType.FlightAttendant.rawValue) {
                day.isPreviousMonth = false
            }
            if (day.text == "4" && self.bidPeriod?.month?.intValue == 2 && self.bidPeriod?.positionType?.intValue == BICrewPositionType.FlightAttendant.rawValue) {
                day.isNextMonth = false
            }
            if (day.isNextMonth && (day.text == "1" || day.text == "2" || day.text == "3")) {
                day.isNextMonth = false
            }
            if day.isPreviousMonth || day.isNextMonth {
                continue
            }
            else {
                self.addRedBubble(viewTag: viewTag, index: index)
                self.configureMonthDayFilter(index: index, addDay: true)
                if (!day.isCurrentMonth) {
                    if self.bidPeriod?.month?.intValue == 12 {
                        let month = 1
                        let year = (self.bidPeriod!.year!.intValue) + 1
                        strDay = "\(day.text)-\(month)-\(year)"
                    }
                }
                else {
                    strDay = "\(day.text)-\(String(describing: self.bidPeriod!.month!))-\(String(describing: self.bidPeriod!.year!))"
                }
                arrDatesSelected.add(strDay)
            }
        }
        let variables = NSMutableDictionary(dictionary: filterRule!.variables!)
        variables.setValue(arrDatesSelected, forKey: BIFilterRuleSelectedDaysVariablesKey)
        variables.setValue(1, forKey: "isSelectedAll")
        variables.setValue(0, forKey: "isCalendar")
        self.filterRule?.variables = variables
    }
    
    func allDaysOptionButton() {
        self.arrDatesSelected.removeAllObjects()
        self.rptRlsType = .all
        for i in 0..<(self.calendarData?.calendarDays.count)!{
            var strDay = ""
            let index = i
            let viewTag = index + 500
            let day: BICalendarDay = (self.calendarData?.calendarDays[i] as? BICalendarDay)!
            
            if day.text == "1" {
//                print()
            }
            if (day.text == "31" && self.bidPeriod?.month?.intValue == 2 && self.bidPeriod?.positionType?.intValue == BICrewPositionType.FlightAttendant.rawValue) {
                day.isPreviousMonth = false
            }
            if (day.text == "4" && self.bidPeriod?.month?.intValue == 2 && self.bidPeriod?.positionType?.intValue == BICrewPositionType.FlightAttendant.rawValue) {
                day.isNextMonth = false
            }
            if (day.isNextMonth && (day.text == "1" || day.text == "2" || day.text == "3")) {
                day.isNextMonth = false
            }
            if day.isPreviousMonth || day.isNextMonth {
                continue
            }
            else {
                self.addRedBubble(viewTag: viewTag, index: index)
                self.configureMonthDayFilter(index: index, addDay: true)
                if (!day.isCurrentMonth) {
                    if self.bidPeriod?.month?.intValue == 12 {
                        let month = 1
                        let year = (self.bidPeriod?.year!.intValue)! + 1
                        strDay = "\(day.text)-\(month)-\(year)"
                    }
                    else {
                        strDay = "\(day.text)-\(self.bidPeriod!.month!.intValue + 1)-\(self.bidPeriod!.year!)"
                    }
                }
                else {
                    strDay = "\(day.text)-\(String(describing: self.bidPeriod!.month!))-\(String(describing: self.bidPeriod!.year!))"
                }
                arrDatesSelected.add(strDay)
            }
        }
        let variables = NSMutableDictionary(dictionary: filterRule!.variables!)
        variables.setValue(arrDatesSelected, forKey: BIFilterRuleSelectedDaysVariablesKey)
        variables.setValue(1, forKey: "isSelectedAll")
        variables.setValue(1, forKey: "isCalendar")
        self.filterRule?.variables = variables
    }
    
    func tripOrWorkBlockOptionButton() {
        self.arrDatesSelected.removeAllObjects()
        self.rptRlsType = .all
        for i in 0..<(self.calendarData?.calendarDays.count)!{
            var strDay = ""
            let index = i
            let viewTag = index + 500
            let day: BICalendarDay = (self.calendarData?.calendarDays[i] as? BICalendarDay)!
            
            if (day.text == "31" && self.bidPeriod?.month?.intValue == 2 && self.bidPeriod?.positionType?.intValue == BICrewPositionType.FlightAttendant.rawValue) {
                day.isPreviousMonth = false
            }
            if (day.text == "4" && self.bidPeriod?.month?.intValue == 2 && self.bidPeriod?.positionType?.intValue == BICrewPositionType.FlightAttendant.rawValue) {
                day.isNextMonth = false
            }
            if (day.isNextMonth && (day.text == "1" || day.text == "2" || day.text == "3")) {
                day.isNextMonth = false
            }
            if day.isPreviousMonth || day.isNextMonth {
                continue
            }
            else {
                self.addRedBubble(viewTag: viewTag, index: index)
                self.configureMonthDayFilter(index: index, addDay: true)
                if (!day.isCurrentMonth) {
                    if self.bidPeriod?.month?.intValue == 12 {
                        let month = 1
                        let year = (self.bidPeriod?.year!.intValue)! + 1
                        strDay = "\(day.text)-\(month)-\(year)"
                    }
                    else {
                        strDay = "\(day.text)-\(self.bidPeriod!.month!.intValue + 1)-\(self.bidPeriod!.year!)"
                    }
                }
                else {
                    strDay = "\(day.text)-\(String(describing: self.bidPeriod!.month!))-\(String(describing: self.bidPeriod!.year!))"
                }
                arrDatesSelected.add(strDay)
            }
        }
        let variables = NSMutableDictionary(dictionary: filterRule!.variables!)
        variables.setValue(arrDatesSelected, forKey: BIFilterRuleSelectedDaysVariablesKey)
        variables.setValue(0, forKey: "isSelectedAll")
        variables.setValue(0, forKey: "isCalendar")
        self.filterRule?.variables = variables
    }
    
    func addRedBubble(viewTag: Int, index: Int) {
        if calendarCollectionView == nil {
            return
        }

        let flowLayout = calendarCollectionView.collectionViewLayout as? UICollectionViewFlowLayout
        let itemSize: CGSize? = flowLayout?.itemSize
        let hInset: CGFloat = (itemSize?.height ?? 0.0) / 2.0
        let wInset: CGFloat = (itemSize?.width ?? 0.0) / 2.0
        let insets: UIEdgeInsets = UIEdgeInsets(top: hInset, left: wInset, bottom: hInset, right: wInset)
        var greenSelectedFrame = CGRect(x: 0.0, y: 0.0, width: itemSize?.width ?? 0.0, height: itemSize?.height ?? 0.0)
        var greenImageView: UIImage? = nil
        var greenSelected: UIImageView? = nil
        let layout: UICollectionViewLayoutAttributes? = flowLayout?.layoutAttributesForItem(at: IndexPath(item: index, section: 0))
        greenSelectedFrame.origin.x = layout?.frame.origin.x ?? 0.0
        greenSelectedFrame.origin.y = layout?.frame.origin.y ?? 0.0
        greenSelected = UIImageView(frame: greenSelectedFrame)
        greenSelected?.tag = viewTag
        
        // Add the day number
        let labelFrame: CGRect = greenSelected!.bounds
        let label = UILabel(frame: labelFrame)
        greenImageView = UIImage(named: "TripButton-rounded-both-green")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
        if let aSize = UIFont(name: "ZapfDingbatsITC", size: 20.0) {
            label.font = aSize
        }
        label.text = "✔"
        greenSelected?.image = greenImageView
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.backgroundColor = UIColor.clear
        greenSelected?.addSubview(label)
        calendarCollectionView.addSubview(greenSelected!)
    }

    func configureMonthDayFilter(index: Int, addDay shouldAdd: Bool) {
        var mask: UInt64 = 0
        var monthBits: UInt64 = filterRule!.variables?["MONTH_BITS"] as! UInt64
        
        let one: UInt64 = 1
        
        mask = UInt64(bitPattern: Int64(one << index))
     
        if shouldAdd {
            
            // Set bit.
            monthBits |= mask
        } else {
            // Clear bit.
            monthBits &= ~mask
        }

        // Update the variables dictionary
        let variables = NSMutableDictionary(dictionary: filterRule!.variables!)
        variables.setValue(NSNumber(value: monthBits), forKey: "MONTH_BITS")
        variables.setValue(1, forKey: "isCalendar")

        self.filterRule?.variables = variables
    }


    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (self.calendarData?.calendarDays.count)!
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let kDayCellIdentifier = "CellDay"
        let kDayLabelTag = 300
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kDayCellIdentifier, for: indexPath)
        let day: BICalendarDay = self.calendarData!.calendarDays[indexPath.row] as! BICalendarDay
        
        let dayLabel = cell.viewWithTag(kDayLabelTag) as? UILabel
        dayLabel!.text = day.text
        dayLabel!.textColor = day.isCurrentMonth ? .gray : .lightGray
        if day.isPreviousMonth {
            isPreviousMonth = false
        }
        if (day.text == "31" && self.bidPeriod?.month?.intValue == 2 && self.bidPeriod?.positionType?.intValue == BICrewPositionType.FlightAttendant.rawValue) {
            day.isPreviousMonth = false
        }
        
        if isPreviousMonth {
            cell.isUserInteractionEnabled = false
        }
        else {
            cell.isUserInteractionEnabled = true
        }
        var monthBits = filterRule?.variables!["MONTH_BITS"] as? UInt64 ?? 0
        let one: UInt64 = 1
        var mask: UInt64 = 0

        mask = one << indexPath.row
        if (monthBits & mask) != 0 {
            let viewTag = indexPath.row + 500
            let viewToAdd = calendarCollectionView.viewWithTag(viewTag)
            if viewToAdd == nil {
                addRedBubble(viewTag: viewTag, index: indexPath.row)
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var strDay = ""
        let index = indexPath.row
        let viewTag = index + 500
        let viewToRemove = calendarCollectionView.viewWithTag(viewTag)
        if viewToRemove != nil {
            self.rptRlsType = .specific
            self.configureMonthDayFilter(index: index, addDay: false)
            viewToRemove?.removeFromSuperview()
            let day: BICalendarDay = self.calendarData?.calendarDays[indexPath.row] as! BICalendarDay
            if !(day.isCurrentMonth) {
                if self.bidPeriod?.month?.intValue == 12 {
                    let month = 1
                    let year = (self.bidPeriod!.year!.intValue) + 1
                    strDay = "\(day.text)-\(month)-\(year)"
                }
                else {
                    strDay = "\(day.text)-\(String(describing: (self.bidPeriod!.month!.intValue) + 1))-\(String(describing: self.bidPeriod!.year!))"
                }
            }
            else {
                strDay = "\(day.text)-\(String(describing: self.bidPeriod!.month!))-\(String(describing: self.bidPeriod!.year!))"
            }
            arrDatesSelected.remove(strDay)
            let variables = NSMutableDictionary(dictionary: filterRule!.variables!)
            variables.setValue(arrDatesSelected, forKey: BIFilterRuleSelectedDaysVariablesKey)
            variables.setValue(0, forKey: "isSelectedAll")
            variables.setValue(1, forKey: "isCalendar")
            self.filterRule?.variables = variables
        }
        else {
            self.addRedBubble(viewTag: viewTag, index: index)
            self.configureMonthDayFilter(index: index, addDay: true)
            let day: BICalendarDay = self.calendarData?.calendarDays[indexPath.row] as! BICalendarDay
            if !(day.isCurrentMonth) {
                if self.bidPeriod?.month?.intValue == 12 {
                    let month = 1
                    let year = (self.bidPeriod!.year!.intValue) + 1
                    strDay = "\(day.text)-\(month)-\(year)"
                }
                else {
                    strDay = "\(day.text)-\(String(describing: (self.bidPeriod!.month!.intValue) + 1))-\(String(describing: self.bidPeriod!.year!))"
                }
            }
            else {
                strDay = "\(day.text)-\(String(describing: self.bidPeriod!.month!))-\(String(describing: self.bidPeriod!.year!))"
            }
            arrDatesSelected.add(strDay)
            let variables = NSMutableDictionary(dictionary: filterRule!.variables!)
            variables.setValue(arrDatesSelected, forKey: BIFilterRuleSelectedDaysVariablesKey)
            variables.setValue(1, forKey: "isCalendar")
            self.filterRule?.variables = variables
        }
    }
}
