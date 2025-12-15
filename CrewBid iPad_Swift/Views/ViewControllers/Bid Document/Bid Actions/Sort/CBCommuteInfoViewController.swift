//
//  CBCommuteInfoViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 17/04/25.
//

import UIKit
import CoreData

class CBCommuteInfoViewController: UIViewController, KUIPopOverUsable, CityNameViewControllerDelegate {
   
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var _btnDoneSettings: UIButton!
    @IBOutlet weak var _btnViewCommuteTimes: UIButton!
    @IBOutlet weak var _btnBacktoBase: UIButton!
    @IBOutlet weak var _btnCheckIn: UIButton!
    @IBOutlet weak var _btnConnectTime: UIButton!
    @IBOutlet weak var _btnCommuteCity: UIButton!
    @IBOutlet weak var _btnCancel: UIButton!
    @IBOutlet weak var nonStopCheckButton: CheckBox!
    @IBOutlet weak var nonStopCheckView: UIView!

    var bidPeriod: BIBidPeriod?
    var commutabilityType: CommutabilityType = .filter
    var lineSort: BILineSort?
    var commutability: CBCommutability?
    var arrowDirection: UIPopoverArrowDirection = UIPopoverArrowDirection.none
    var context = CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext
    
    var connectTimeFromSync: String = "00:30"
    var backToBaseFromSync: String = "00:10"
    var checkInFromSync: String = "01:00"
    var isNonStop: Bool = false
    var isFromSync: Bool = false
    var commuteCityFromSync: String!
    var KeyPathFromSync = "commutabilityOverall"
    
    var type: NSNumber = 1  //Less that or equal
    var secondCellValue: NSNumber = 1 // NoMiddle
    var thirdCellValue: NSNumber = 3  //Overallb
    var value: NSNumber = 100 // Percentage
    
    var contentSize: CGSize {
        return CGSize(width: 320.0, height: 320)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        self.viewInitialization()
    }
    
    func setupUI() {
        var borderColor = UIColor.gray.cgColor
        if #available(iOS 13.0, *) {
            borderColor = UIColor.label.withAlphaComponent(0.5).cgColor
        }
        
        _btnCommuteCity.layer.borderColor = borderColor
        _btnCommuteCity.layer.borderWidth = 1.0
        //
        _btnCheckIn.layer.borderColor = borderColor
        _btnCheckIn.layer.borderWidth = 1.0
        //
        _btnConnectTime.layer.borderColor = borderColor
        _btnConnectTime.layer.borderWidth = 1.0
        //
        _btnBacktoBase.layer.borderColor = borderColor
        _btnBacktoBase.layer.borderWidth = 1.0
        
        
        nonStopCheckButton.layer.borderColor = borderColor
        nonStopCheckButton.layer.borderWidth = 3.0
        nonStopCheckButton.layer.cornerRadius = nonStopCheckButton.frame.size.width / 2
        nonStopCheckButton.layer.masksToBounds = true
        nonStopCheckButton.backgroundColor = UIColor.white
        
        nonStopCheckView.layer.cornerRadius = nonStopCheckView.frame.size.width / 2
        nonStopCheckView.layer.masksToBounds = true
        nonStopCheckView.isHidden = true
    }
    
    @IBAction func nonStopCheckBtnTapped(_ sender: Any) {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        
        if nonStopCheckView.isHidden {
            nonStopCheckView.isHidden = false
            self._btnConnectTime.setTitle("-:-", for: .normal)
            connectTimeFromSync = "00:00"
            self.isNonStop = true
        }
        else {
            nonStopCheckView.isHidden = true
            _btnConnectTime.setTitle("00:30", for: .normal)
            self.isNonStop = false
        }
        let commuteTimes = self.bidPeriod!.commuteTime?.allObjects as? [CommuteTime] ?? []
        if commuteTimes.count == 0 || self.commuteCityFromSync == nil {
            return
        }
        CBGlobalMethods.shared.showActivityIndicator(bgColor: .purple)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
            let cityObj = CommuteCityViewController()
            cityObj.bidPeriod = self.bidPeriod!
            cityObj.isNonStopOnly = self.isNonStop
            let arrConnectTime = Array(self.connectTimeFromSync.components(separatedBy: ":")) as NSArray
            let connectTime: Int = Int(arrConnectTime.object(at: 1) as! String) ?? 0 + (Int(arrConnectTime.object(at: 0) as! String)! * 60)
            cityObj.connectTime = connectTime
            let (status, city) = cityObj.commutabilityCalculationWithForSync(city: self.commuteCityFromSync, isNonStop: self.isNonStop, connectTimeFromPreset: connectTime)
            print(status, city)
            self.calculateCommuteLineProperties()
        }
    }
    
    func setCityName(_ cityName: String?) {
        _btnCommuteCity.setTitle(cityName, for: .normal)
        commuteCityFromSync = cityName
        if !(cityName == "Select") {
            _btnViewCommuteTimes.isUserInteractionEnabled = true
            _btnViewCommuteTimes.alpha = 1
            _btnDoneSettings.isUserInteractionEnabled = true
            _btnDoneSettings.alpha = 1
        }
    }
    
    func disableButtonsForNoConnection() {
        _btnCommuteCity.setTitle("Select", for: .normal)
        _btnViewCommuteTimes.isUserInteractionEnabled = false
        _btnViewCommuteTimes.alpha = 0.7
        _btnDoneSettings.isUserInteractionEnabled = false
        _btnDoneSettings.alpha = 0.7
    }
    
    func calculateCommuteLineProperties() {
        let minDateString = "01/01/0001 00:00:00"
        let dateFormater = DateFormatter()
        dateFormater.timeZone = TimeZone(secondsFromGMT: 0)!
        dateFormater.locale = Locale.current
        dateFormater.dateFormat = "MM/dd/yyyy hh:mm:ss"
        let minDate = dateFormater.date(from: minDateString)
        
        self.commutability = CBCommutability()
        
//        backtobase time
        let arrBackTobase = Array(self.backToBaseFromSync.components(separatedBy: ":")) as NSArray
        var backToBase: Int = 0
        if arrBackTobase.count == 2 {
            backToBase = Int(arrBackTobase.object(at: 1) as! String)! + Int(arrBackTobase.object(at: 0) as! String)! * 60
        }
        else {
            backToBase = Int(arrBackTobase.object(at: 0) as! String)!
        }
        self.commutability?.baseTime = backToBase
        
//        check in time
        let arrCheckIntTime = Array(checkInFromSync.components(separatedBy: ":")) as NSArray
        var checkInTime: Int = 0
        if arrCheckIntTime.count == 2 {
            checkInTime = Int(arrCheckIntTime.object(at: 1) as! String)! + Int(arrCheckIntTime.object(at: 0) as! String)! * 60
        }
        else {
            checkInTime = Int(arrCheckIntTime.object(at: 0) as! String)!
        }
        self.commutability?.checkInTime = checkInTime
        
//        connect time
        let arrConnectTime = Array(connectTimeFromSync.components(separatedBy: ":")) as NSArray
        var connectTime: Int = 0
        if arrConnectTime.count == 2 {
            connectTime = Int(arrConnectTime.object(at: 1) as! String)! + Int(arrConnectTime.object(at: 0) as! String)! * 60
        }
        else {
            connectTime = Int(arrConnectTime.object(at: 0) as! String)!
        }
        self.commutability?.connectTime = connectTime
        
        let commuteList = fetchCommuteTime()
        let formatterDate = DateFormatter()
        if let timeZone = TimeZone(secondsFromGMT: 0) {
            formatterDate.timeZone = timeZone as TimeZone
        }
        formatterDate.dateFormat = "yyyy-MM-dd"
        
        for line in self.bidPeriod!.orderedLines() {
            line.commutableBacks = 0
            line.commutableFronts = 0
            line.commutabilityFront = 0
            line.commutabilityBack = 0
            line.commutabilityOverall = 0
            
            for case let workBlock as WorkBlockList in line.orderedWorkBlocks {
                var isCommuteFrontEnd = false
                var isCommuteBackEnd = false
                
                var filteredStart: [CommuteTime] = []
                if let aTime = workBlock.startDateTime {
                    let predicate = NSPredicate(format: "bidDayStringValue == %@", "\(formatterDate.string(from: aTime as Date))")
                    filteredStart = commuteList.filter { predicate.evaluate(with: $0)}
//                    MARK: check value of orderedNoVacDays because it is not available in crewbid Ipad
                    let days = workBlock.orderedNoVacDays() as! [BIDay]
                    if filteredStart.count > 0 && (days.first?.displayType == BIDayDisplayType.normal.rawValue.asNSNumber) {
                        let objCommuteTime = filteredStart[0]
                        let startTime = workBlock.startDateTakeOffTime!
                        let value: Int = commutability!.checkInTime
                        let requiredStartTime = objCommuteTime.earliestArrivel!.addingTimeInterval(TimeInterval(value * 60))
                        if startTime >= requiredStartTime && objCommuteTime.earliestArrivel! != minDate{
                            isCommuteFrontEnd  = true
                            line.commutableFronts = (((line.commutableFronts?.doubleValue ?? 0)  +  1)) as NSNumber
                        }
                    }
                }
                
//                correct calculation
                var filteredEnd: [CommuteTime] = []
                if let aTime = workBlock.endDateOnly {
                    let predicate = NSPredicate(format: "bidDayStringValue == %@", "\(formatterDate.string(from: aTime as Date))")
                    filteredEnd = commuteList.filter { predicate.evaluate(with: $0) }
                    let days = workBlock.orderedNoVacDays() as! [BIDay]
                    if filteredEnd.count > 0 && (days.last?.displayType == BIDayDisplayType.normal.rawValue.asNSNumber) {
                        let objCommuteTime = filteredEnd[0]
                        var endTime = workBlock.endDateTime!
                        if line.faReserveLineType == 2 || line.faReserveLineType == 3 {
                            endTime = workBlock.endDateOnly!
                        }
                        let value: Int = commutability!.baseTime
                        let requiredEndTime = objCommuteTime.latestDeparture!.addingTimeInterval(TimeInterval((-(value * 60))))
                        if endTime <= requiredEndTime && objCommuteTime.latestDeparture! != minDate{
                            line.commutableBacks = (((line.commutableBacks?.doubleValue ?? 0)  +  1)) as NSNumber
                            isCommuteBackEnd = true
                        }
                    }
                }
                
                if isCommuteBackEnd && isCommuteFrontEnd {
                    self.calculateIsTripFullyCommutable(line: line, and: workBlock)

                }
            }
            
            var totalCommutes = 0
            for case let block as WorkBlockList in line.orderedWorkBlocks {
                var isCountable = false
                for case let day as BIDay in block.orderedDays {
                    if day.displayType == BIDayDisplayType.normal.rawValue.asNSNumber {
                        isCountable = true
                    }
                }
                if isCountable {
                    totalCommutes = totalCommutes + 1
                }
            }
            
            line.totalCommutes = NSNumber(value: totalCommutes)
            line.commutabilityFront = NSNumber(value:  (line.commutableFronts!.doubleValue / line.totalCommutes!.doubleValue) * 100)
            line.commutabilityBack = NSNumber(value:  (line.commutableBacks!.doubleValue / line.totalCommutes!.doubleValue) * 100)
            line.commutabilityOverall = NSNumber(value:  (line.commutabilityFront!.doubleValue + line.commutabilityBack!.doubleValue) / 2)
        }
        
        self.saveCommutablity()
    }
    
    func fetchCommuteTime() -> [CommuteTime] {
        let fetchedObjects = (bidPeriod?.commuteTime?.allObjects ?? []) as! [CommuteTime]
        return fetchedObjects
    }
    
    func calculateIsTripFullyCommutable(line : BILine, and workBlock: WorkBlockList) {
        var tripStartDate = Date()
        var workBlockStartDate = Date()
        var dateStatus = false
        
        for case let trip as BITrip in line.orderedTrips {
            tripStartDate = self.getOnlyStartDateOfTrip(trip: trip)
            workBlockStartDate = self.getOnlyStartDateOfWorkBlock(date: workBlock.startDateTime! as Date)
            dateStatus = self.daydateCheck(beginDate: tripStartDate, inBetweenDate: workBlockStartDate, endDate: workBlock.endDateOnly! as Date)
            if dateStatus {
                trip.info?.isFullyCommutable = NSNumber(booleanLiteral: true)
                trip.highlightCount = NSNumber(integerLiteral: (trip.highlightCount!.intValue + 1))
            }
        }
    }
    
    func getOnlyStartDateOfTrip(trip: BITrip) -> Date {
        var startDate = Date()
        var calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        calendar.locale = Locale.current
        calendar.timeZone = TimeZone(abbreviation: "GMT")!
        let dateComps = calendar.dateComponents([.year,.month, .day], from: trip.startDate! as Date)
        startDate = calendar.date(from: dateComps)!
        return startDate
    }
    
    func getOnlyStartDateOfWorkBlock(date: Date) -> Date {
        var startDate = Date()
        var calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        calendar.locale = Locale.current
        calendar.timeZone = TimeZone(abbreviation: "GMT")!
        let dateComps = calendar.dateComponents([.year,.month, .day], from: date)
        startDate = calendar.date(from: dateComps)!
        return startDate
    }
    
    func daydateCheck(beginDate: Date, inBetweenDate: Date, endDate: Date) -> Bool {
        if beginDate.compare(inBetweenDate) == .orderedAscending {
            return false
        }
        if beginDate.compare(endDate) == .orderedDescending {
            return false
        }
        return true
    }
    
    func saveCommutablity() {
        switch commutabilityType {
        case .filter:
            saveCommutabilityFilter()
        case .sort:
            saveCommutabilitySort()
        default:
            break
        }
    }
    
    func saveCommutabilitySort() {
//        added sort fetching to include bidPeriod check with commutable
        let fetchSortRequest: NSFetchRequest<BILineSort> = BILineSort.fetchRequest()
        let predicate1 = NSPredicate(format: "bidPeriod == %@", bidPeriod!)
        let predicate2 = NSPredicate(format: "category == 9")
        let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate1, predicate2])
        fetchSortRequest.predicate = combinedPredicate
        let fetchedSortObjects: [BILineSort] = (try? self.context!.fetch(fetchSortRequest)) ?? []
        
        let fetchRequest: NSFetchRequest<Commutability> = Commutability.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "commutableType == 1")
        let fetchedObjects: [Commutability] = (try? self.context!.fetch(fetchRequest)) ?? []
        let objCommutablity: Commutability?
        if fetchedObjects.count > 0 && fetchedSortObjects.count > 0 {
            objCommutablity = fetchedObjects[0]
            updateCommutabilityFilter()
            fetchCommutabilitydetails()
            if (self.bidPeriod!.isBidListSortOn?.boolValue ?? false){
                lineSort?.isBidListSort = NSNumber(value: true)
            }else {
                lineSort?.isBidListSort = NSNumber(value: false)
            }
        }
        else {
            //Set WorkBlock Details
            
            objCommutablity = Commutability(context: context!)
            objCommutablity?.thirdCellValue = thirdCellValue
            objCommutablity?.type = type
            objCommutablity?.secondCellValue = secondCellValue // no middle
            objCommutablity?.value = value // percentage
            objCommutablity?.isNonStop = NSNumber(value: self.isNonStop)
            objCommutablity?.commutableType = 1
            try? self.context!.save()
            
            lineSort = BILineSort(context: context!)
            lineSort?.bidPeriod = self.bidPeriod
            lineSort?.abbreviation = "CmAuto"
            lineSort?.category = 9
            lineSort?.type = 1
            lineSort?.name = "Commuting - Auto"
            lineSort?.keyPath = KeyPathFromSync
            lineSort?.isMutable = 1
            lineSort?.ascending = 0
            let dicVariables = NSMutableDictionary()
            dicVariables["nMid"] = 0
            dicVariables["cmts"] = 0
            dicVariables["cmtBa"] = 0
            dicVariables["cmtFr"] = 0
            dicVariables["cmtInFr"] = 0
            dicVariables["cmtInBa"] = 0
            dicVariables["cmtOv"] = 0
            lineSort?.variables = dicVariables
            if (self.bidPeriod!.isBidListSortOn?.boolValue ?? false){
                lineSort?.isBidListSort = NSNumber(value: true)
            }else {
                lineSort?.isBidListSort = NSNumber(value: false)
            }
        }
        
        objCommutablity?.city =  commuteCityFromSync!
        let strCheckInTime : [String] = checkInFromSync.components(separatedBy: ":")
        let strBackTobase : [String] = backToBaseFromSync.components(separatedBy: ":")
        objCommutablity?.isNonStop = NSNumber(value: self.isNonStop)
        
        
        let arrCheckInTime = Array(strCheckInTime) as NSArray
        let CheckIntime:Int = Int(arrCheckInTime.object(at: 1) as! String)! + (Int(arrCheckInTime.object(at: 0) as! String)! * 60)
        objCommutablity?.checkInTime = CheckIntime as NSNumber
        
        let StrConnectTime = connectTimeFromSync.components(separatedBy: ":")
        let arrConnectTime = Array(StrConnectTime) as NSArray
        let ConnectTime:Int = Int(arrConnectTime.object(at: 1) as! String) ?? 0 + (Int(arrConnectTime.object(at: 0) as! String) ?? 0 * 60)
        objCommutablity?.connectTime = ConnectTime as NSNumber
        
        let arrBackTobase = Array(strBackTobase) as NSArray
        let BackTobace:Int = Int(arrBackTobase.object(at: 1) as! String)! + (Int(arrBackTobase.object(at: 0) as! String)! * 60)
        objCommutablity?.baseTime = BackTobace as NSNumber
        try? self.context!.save()
        dismiss(animated: true)
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
    
    func updateCommutabilityFilter() {
        let fetchRequest: NSFetchRequest<Commutability> = Commutability.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "commutableType == 0")
        let fetchedObjects: [Commutability] = (try? self.context!.fetch(fetchRequest)) ?? []
        var objCommutabilityFiler: Commutability?
        if fetchedObjects.count > 0 {
            objCommutabilityFiler = fetchedObjects[0]
            let strCheckInTime: [String] = checkInFromSync.components(separatedBy: ":")
            objCommutabilityFiler?.city = self.commuteCityFromSync!
            objCommutabilityFiler?.isNonStop = NSNumber(booleanLiteral: self.isNonStop)
            let arrCheckInTime = Array(strCheckInTime) as NSArray
            let checkInTime: Int = Int(arrCheckInTime.object(at: 1) as! String)! + (Int(arrCheckInTime.object(at: 0) as! String)! * 60)
            objCommutabilityFiler?.checkInTime = checkInTime as NSNumber
            let strConnectTime = connectTimeFromSync.components(separatedBy: ":")
            let arrConnectTime = Array(strConnectTime) as NSArray
            var connectTime: Int?
            if arrConnectTime.count == 2 {
                connectTime = Int(arrConnectTime.object(at: 1) as! String) ?? 0 + (Int(arrConnectTime.object(at: 0) as! String) ?? 0 * 60)
            }
            else {
                connectTime = Int(arrConnectTime.object(at: 0) as! String)
            }
            if let connectTime = connectTime {
                let strBackToBase = backToBaseFromSync.components(separatedBy: ":")
                let arrBackToBase = Array(strBackToBase) as NSArray
                let backToBase: Int = Int(arrBackToBase.object(at: 1) as! String)! + (Int(arrBackToBase.object(at: 0) as! String)! * 60)
                objCommutabilityFiler?.baseTime = backToBase as NSNumber
                try? self.context?.save()
            }
        }
    }
    
    func fetchCommutabilitydetails() {
        let fetchRequest: NSFetchRequest<BILineSort> = BILineSort.fetchRequest()
        let predicate1 = NSPredicate(format: "bidPeriod == %@", bidPeriod!)
        let predicate2 = NSPredicate(format: "category == 9")
        let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate1, predicate2])
        fetchRequest.predicate = combinedPredicate
        
        let fetchedObjects: [BILineSort] = (try? self.context!.fetch(fetchRequest)) ?? []
        if fetchedObjects.count > 0 {
            lineSort = fetchedObjects[0]
        }
    }
    
    func saveCommutabilityFilter() {
//                added filter fetching to include bidPeriod check with commutable
        let fetchFilterRequest: NSFetchRequest<BIFilterRule> = BIFilterRule.fetchRequest()
        let predicate1 = NSPredicate(format: "bidPeriod == %@", bidPeriod!)
        let predicate2 = NSPredicate(format: "category == 33")
        let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate1, predicate2])
        fetchFilterRequest.predicate = combinedPredicate
        let fetchedFilterObjects: [BIFilterRule] = (try? self.context!.fetch(fetchFilterRequest)) ?? []
        
        let fetchRequest: NSFetchRequest<Commutability> = Commutability.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "commutableType == 0")
        let fetchedObjects: [Commutability] = (try? self.context!.fetch(fetchRequest)) ?? []
        var objCommutablity: Commutability?
        if fetchedObjects.count > 0 && fetchedFilterObjects.count > 0{
            objCommutablity = fetchedObjects[0]
            updateCommutabilitySort()
        }
        else {
            //Set WorkBlock Details
            objCommutablity = Commutability(context: self.context!)
            objCommutablity?.isNonStop = NSNumber(value: self.isNonStop)
            objCommutablity?.type = type
            objCommutablity?.secondCellValue = secondCellValue // No Middle
            objCommutablity?.thirdCellValue = thirdCellValue //Overall
            objCommutablity?.value = value // Percentage
            objCommutablity?.commutableType = 0
            
            let rule = BIFilterRule(context: self.context!)
            rule.bidPeriod = bidPeriod
            rule.abbreviation = "CmAuto"
            rule.category = 33
            rule.type = 0
            rule.name = "Commuting - Auto"
            rule.keyPath = ""
            rule.comparison = 1
            let dicVariables = NSMutableDictionary()
            dicVariables["nMid"] = 0
            dicVariables["cmts"] = 0
            dicVariables["cmtBa"] = 0
            dicVariables["cmtFr"] = 0
            dicVariables["cmtInFr"] = 0
            dicVariables["cmtInBa"] = 0
            dicVariables["cmtOv"] = 0
            rule.variables = dicVariables
        }
        
        objCommutablity?.city = commuteCityFromSync
        let strCheckInTime = self.checkInFromSync.components(separatedBy: ":")
        objCommutablity?.isNonStop = NSNumber(value: self.isNonStop)
        
        let arrCheckIntime = Array(strCheckInTime) as NSArray
        var checkInTime = 0
        if arrCheckIntime.count == 2 {
            checkInTime = Int(arrCheckIntime.object(at: 1) as! String)! + (Int(arrCheckIntime.object(at: 0) as! String)! * 60)
        }
        else {
            checkInTime = Int(arrCheckIntime.object(at: 0) as! String) ?? 0
        }
        objCommutablity?.checkInTime = checkInTime as NSNumber
        
        let strConnectTime = connectTimeFromSync.components(separatedBy: ":")
        let arrConnectTime = Array(strConnectTime) as NSArray
        var connectTime = 0
        if arrConnectTime.count == 2 {
            connectTime = Int(arrConnectTime.object(at: 1) as! String) ?? 0 + (Int(arrConnectTime.object(at: 0) as! String) ?? 0 * 60)
        }
        else {
            connectTime = Int(arrConnectTime.object(at: 0) as! String) ?? 0
        }
        objCommutablity?.connectTime = connectTime as NSNumber
        
        let strBackToBase = self.backToBaseFromSync.components(separatedBy: ":")
        let arrBackToBase = Array(strBackToBase) as NSArray
        var backToBase = 0
        if arrBackToBase.count == 2 {
            backToBase = Int(arrBackToBase.object(at: 1) as! String)! + (Int(arrBackToBase.object(at: 0) as! String)! * 60)
        }
        else {
            backToBase = Int(arrBackToBase.object(at: 0) as! String) ?? 0
        }
        objCommutablity?.baseTime = backToBase as NSNumber
        try? self.context!.save()
        dismiss(animated: true)
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
    
    func updateCommutabilitySort() {
        let fetchRequest: NSFetchRequest<Commutability> = Commutability.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "commutableType == 1")
        let fetchedObjects: [Commutability] = (try? self.context!.fetch(fetchRequest)) ?? []
        let objCommutablityFilter: Commutability?
        if fetchedObjects.count > 0 {
            objCommutablityFilter = fetchedObjects[0]
            objCommutablityFilter?.city = self.commuteCityFromSync
            
            let strCheckInTime = self.checkInFromSync.components(separatedBy: ":")
            let arrCheckIntime = Array(strCheckInTime) as NSArray
            let checkInTime = Int(arrCheckIntime.object(at: 1) as! String)! + (Int(arrCheckIntime.object(at: 0) as! String)! * 60)
            objCommutablityFilter?.checkInTime = checkInTime as NSNumber
            
            let strConnectTime = self.connectTimeFromSync.components(separatedBy: ":")
            let arrConnectTime = Array(strConnectTime) as NSArray
            var connectTime: Int?
            if arrConnectTime.count == 2 {
                connectTime = Int(arrConnectTime.object(at: 1) as! String) ?? 0 + (Int(arrConnectTime.object(at: 0) as! String) ?? 0 * 60)
            }
            else {
                connectTime = Int(arrConnectTime.object(at: 0) as! String) ?? 0
            }
            if let connectTime = connectTime {
                objCommutablityFilter?.connectTime = connectTime as NSNumber
                let strBackToBase = self.backToBaseFromSync.components(separatedBy: ":")
                let arrBackToBase = Array(strBackToBase) as NSArray
                let backToBase = Int(arrBackToBase.object(at: 1) as! String)! + (Int(arrBackToBase.object(at: 0) as! String)! * 60)
                objCommutablityFilter?.baseTime = backToBase as NSNumber
                try? self.context!.save()
            }
        }
    }
    
    @IBAction func btnDoneSettingActn(_ sender: Any) {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod!.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod!.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        var currentVersionString = ""
        if let value = UserDefaults.standard.value(forKey: "FlightDataVersion") {
            currentVersionString = "\(value)"
        }
        let domicil = bidPeriod!.base!
        let month = "\(bidPeriod!.month!)"
        let round = "\(bidPeriod!.round!)"
        let pos = "\(bidPeriod!.positionType!)"
        let key = "\(currentVersionString)\(domicil)\(month)\(round)\(pos)"
        UserDefaults.standard.removeObject(forKey: key)
        if let _ = _btnBacktoBase ,let _ = _btnConnectTime , let _ = _btnCheckIn{
            handleCommuteDetails()
        }
        self.calculateCommuteLineProperties()
    }
    
    func handleCommuteDetails(){
        backToBaseFromSync = _btnBacktoBase.titleLabel?.text ?? "00:10"
        connectTimeFromSync = _btnConnectTime.titleLabel?.text ?? "00:30"
        checkInFromSync = _btnCheckIn.titleLabel?.text ?? "01:00"
    }
    
    @IBAction func btnViewCommuteActn(_ sender: Any) {
        let storyBoard = UIStoryboard(name: "BidDocument", bundle: nil)
        let lineValueController = storyBoard.instantiateViewController(withIdentifier: "CommutableTimeView") as! CommutableTimeViewController
        lineValueController.preferredContentSize = CGSize(width: 400, height: 450)
        lineValueController.commuteCityValue = (self._btnCommuteCity.titleLabel?.text)!
        lineValueController.bidPeriod = self.bidPeriod
        lineValueController.modalPresentationStyle = .popover
        lineValueController.isNonStop = self.nonStopCheckButton.isChecked
        let frame = CGRect(x: self._btnViewCommuteTimes.frame.maxX - 10, y: self._btnViewCommuteTimes.frame.origin.y + 40, width: 10, height: 10)
        lineValueController.showPopover(sourceView: self.backView, sourceRect: frame)
    }
    
    @IBAction func btnBacktoBaseActn(_ sender: Any) {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        let backToBaseArray = [
            "00:05","00:10","00:15","00:20","00:25","00:30",
            "00:35","00:40","00:45","00:50","00:55","01:00"
        ]

        // Build the actions array
        let actions: [(title: String, style: UIAlertAction.Style, handler: ((UIAlertAction) -> Void)?)] =
            backToBaseArray.map { time in
                return (
                    title: time,
                    style: .default,
                    handler: { (action: UIAlertAction) in
                        // Instead of inline logic, call your existing handler
                        self.backTobaseTapped(action: action)
                    }
                )
            }

        // Add Cancel action
        let cancelAction: (title: String, style: UIAlertAction.Style, handler: ((UIAlertAction) -> Void)?) =
            (title: "Cancel", style: .cancel, handler: nil)

        // Show alert
        AlertService.showAlertForTopVC(
            title: nil,
            message: nil,
            actions: actions + [cancelAction]
        )

    }
    
    func backTobaseTapped(action: UIAlertAction) {
       _btnBacktoBase.setTitle(action.title, for: .normal)
        backToBaseFromSync = action.title!
      // nonStopCheckView.isHidden = true
   }
    
    @IBAction func btnCheckinActn(_ sender: Any) {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        let checkInArray = [
            "00:05","00:10","00:15","00:20","00:25","00:30",
            "00:35","00:40","00:45","00:50","00:55","01:00",
            "01:05","01:10","01:15","01:20","01:25","01:30",
            "01:35","01:40","01:45","01:50","01:55","02:00",
            "02:05","02:10","02:15","02:20","02:25","02:30",
            "02:35","02:40","02:45","02:50","02:55","03:00"
        ]

        let actions: [(title: String, style: UIAlertAction.Style, handler: ((UIAlertAction) -> Void)?)] =
            checkInArray.map { time in
                return (
                    title: time,
                    style: .default,
                    handler: { (action: UIAlertAction) in
                        self.checkInTapped(action: action)
                    }
                )
            }

        // Add Cancel action
        let cancelAction: (title: String, style: UIAlertAction.Style, handler: ((UIAlertAction) -> Void)?) =
            (title: "Cancel", style: .cancel, handler: nil)

        // Call your helper
        AlertService.showAlertForTopVC(
            title: nil,
            message: nil,
            actions: actions + [cancelAction]
        )

    }
    
    @IBAction func btnConnectTimeActn(_ sender: Any) {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        let connectTimeArray = [
            "00:05","00:10","00:15","00:20","00:25","00:30",
            "00:35","00:40","00:45","00:50","00:55","01:00"
        ]

        // Build the list of actions
        let actions: [(title: String, style: UIAlertAction.Style, handler: ((UIAlertAction) -> Void)?)] =
            connectTimeArray.map { time in
                return (
                    title: time,
                    style: .default,
                    handler: { (action: UIAlertAction) in
                        // Call your original handler function instead of print
                        self.connectTimeTapped(action: action)
                    }
                )
            }

        // Add Cancel action
        let cancelAction: (title: String, style: UIAlertAction.Style, handler: ((UIAlertAction) -> Void)?) =
            (title: "Cancel", style: .cancel, handler: nil)

        // Show alert using your helper
        AlertService.showAlertForTopVC(
            title: nil,
            message: nil,
            actions: actions + [cancelAction]
        )

    }
    
    func checkInTapped(action: UIAlertAction) {
        _btnCheckIn.setTitle(action.title, for: .normal)
        checkInFromSync = action.title!
        let takeOffTime = action.title?.components(separatedBy: ":")
        let min = takeOffTime![0]
        if Int(min)! < 1 {
            AlertService.showAlertForTopVC(title: "CrewBid 2", message: "You are setting the Report pad to less than 1:00, you may not meet the contractual requirement to take a flight that arrives 1 hours before check-in")
        }
    }
    
    func connectTimeTapped(action: UIAlertAction) {
        if let title = action.title {
            connectTimeFromSync = title
            nonStopCheckView.isHidden = true
           _btnConnectTime.setTitle(title, for: .normal)
        }
       
    }
    
    func getMinutesFrom(hours : String) -> NSNumber {
        let array = hours.components(separatedBy: ":")
        if array.first! == "-"{
            return NSNumber(integerLiteral: 30)
        }
        let hour = Int(array.first!)!
        let mins = Int(array.last!)!
        let minutes = (hour * 60) + mins
        return NSNumber(integerLiteral: minutes)
    }
    
    @IBAction func btnCommuteCityActn(_ sender: Any) {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let lineValuesController = storyboard.instantiateViewController(withIdentifier: "CommuteCityView") as! CommuteCityViewController
        lineValuesController.connectTime = Int(truncating: self.getMinutesFrom(hours: (_btnConnectTime.titleLabel!.text!)))
        lineValuesController.delegate = self
        lineValuesController.isNonStopOnly = self.isNonStop
        lineValuesController.bidPeriod = self.bidPeriod
        lineValuesController.modalPresentationStyle = .popover
        lineValuesController.arrowDirection = .left
        lineValuesController.showPopover(withNavigationController: self.view)
    }
    
    @IBAction func btnCancelActn(_ sender: Any) {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        self.dismiss(animated: true, completion: nil)
    }
    
    func viewInitialization() {
        let fetchRequest: NSFetchRequest<Commutability> = Commutability.fetchRequest()
        let fetchedObjects: [Commutability] = (try? self.context!.fetch(fetchRequest)) ?? []
        let objCommutability: Commutability?
        if fetchedObjects.count > 0 {
            objCommutability = fetchedObjects[0]
            
            if objCommutability!.isNonStop != nil {
                if objCommutability!.isNonStop!.boolValue {
                    nonStopCheckView.isHidden = false
                    nonStopCheckButton.isChecked = objCommutability!.isNonStop!.boolValue
                    isNonStop = objCommutability!.isNonStop!.boolValue
                }
                else {
                    nonStopCheckView.isHidden = true
                }
            }
            let filterFetchRequest: NSFetchRequest<Commutability> = Commutability.fetchRequest()
            filterFetchRequest.predicate = NSPredicate(format: "commutableType == %d", CommutabilityType.filter.rawValue)
            let filterFetchObjects = (try? self.context!.fetch(filterFetchRequest)) ?? []
            
            let sortFetchRequest: NSFetchRequest<Commutability> = Commutability.fetchRequest()
            sortFetchRequest.predicate = NSPredicate(format: "commutableType == %d", CommutabilityType.sort.rawValue)
            let sortFetchObjects = (try? self.context!.fetch(sortFetchRequest)) ?? []
            
            if sortFetchObjects.count > 0 && filterFetchObjects.count == 0 {
                self.commuteCityFromSync = "Select"
                _btnCommuteCity.setTitle("Select", for: .normal)
            }
            else {
                if objCommutability!.city != nil {
                    self.commuteCityFromSync = objCommutability!.city!
                    _btnCommuteCity.setTitle(objCommutability!.city, for: .normal)
                }
            }
            
            if objCommutability!.checkInTime != nil {
                let minutes: Int = (objCommutability!.checkInTime!.intValue) / 60
                let seconds: Int = (objCommutability!.checkInTime!.intValue) % 60
                let time = String(format: "%02d:%02d", minutes, seconds)
                _btnCheckIn.setTitle(time, for: .normal)
            }
            
            if objCommutability!.baseTime != nil {
                let minutes: Int = (objCommutability!.baseTime!.intValue) / 60
                let seconds: Int = (objCommutability!.baseTime!.intValue) % 60
                let time = String(format: "%02d:%02d", minutes, seconds)
                _btnBacktoBase.setTitle(time, for: .normal)
            }
            
            if objCommutability!.connectTime != nil {
                let minutes: Int = (objCommutability!.connectTime!.intValue) / 60
                let seconds: Int = (objCommutability!.connectTime!.intValue) % 60
                let time = String(format: "%02d:%02d", minutes, seconds)
                if time == "00:00" {
                    _btnConnectTime.setTitle("-:-", for: .normal)
                }
                else {
                    _btnConnectTime.setTitle(time, for: .normal)
                }
            }
        }
        
        if _btnCommuteCity.titleLabel?.text == "Select" {
            _btnViewCommuteTimes.isUserInteractionEnabled = false
            _btnViewCommuteTimes.alpha = 0.7
            _btnDoneSettings.isUserInteractionEnabled = false
            _btnDoneSettings.alpha = 0.7
        }
        else {
            _btnViewCommuteTimes.isUserInteractionEnabled = true
            _btnViewCommuteTimes.alpha = 1
            _btnDoneSettings.isUserInteractionEnabled = true
            _btnDoneSettings.alpha = 1
        }
    }
    
    func calculateCommuteFromSyncandPreset(){
        let cityObj = CommuteCityViewController()
        cityObj.bidPeriod = self.bidPeriod!
        cityObj.isNonStopOnly = self.isNonStop
        let arrConnectTime = Array(connectTimeFromSync.components(separatedBy: ":")) as NSArray
        let connectTime:Int = Int(arrConnectTime.object(at: 1) as! String) ?? 0 + (Int(arrConnectTime.object(at: 0) as! String)! * 60)
        cityObj.connectTime = connectTime
        let (status, city) = cityObj.commutabilityCalculationWithForSync(city: self.commuteCityFromSync, isNonStop: self.isNonStop, connectTimeFromPreset: connectTime)
        print(status, city)
        self.calculateCommuteLineProperties()
    }
}
