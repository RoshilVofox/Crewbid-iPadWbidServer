//
//  CBCommutingSortCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit
import CoreData

class CBCommutingSortCell: UITableViewCell, GRButtonDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var noMidLabel: UILabel!
    @IBOutlet weak var departureMonThurs: UITextField!
    @IBOutlet weak var returnMonThurs: UITextField!
    @IBOutlet weak var departureFri: UITextField!
    @IBOutlet weak var returnFri: UITextField!
    @IBOutlet weak var departureSat: UITextField!
    @IBOutlet weak var returnSat: UITextField!
    @IBOutlet weak var departureSun: UITextField!
    @IBOutlet weak var returnSun: UITextField!
    @IBOutlet weak var noMidCheckButton: UIButton!
    @IBOutlet weak var saveDefaultsButton: UIButton!
    @IBOutlet weak var loadDefaultsButton: UIButton!
    @IBOutlet weak var calculateButton: UIButton!
    @IBOutlet weak var timeFormatLabel: UILabel!
    @IBOutlet weak var eDepLabel: UILabel!
    @IBOutlet weak var lArrLabel: UILabel!
    @IBOutlet weak var monThursLabel: UILabel!
    @IBOutlet weak var friLabel: UILabel!
    @IBOutlet weak var satLabel: UILabel!
    @IBOutlet weak var sunLabel: UILabel!
    @IBOutlet var btnNoMidInfo: UIButton!
    
    var lineSort: BILineSort!
    var bidPeriod: BIBidPeriod!
    var context = CBGlobalMethods.shared.selectedBidPeriod?.managedObjectContext
    var outsideFlag: String?
    var controllerDelegate: UIViewController!
    var activeTextfield: UITextField?
    let InternationalCityMinutes = 75;
    let CityMinutes = 60
    var isNoMidChecked: Bool = false;
    var valueArray = [Int]()
    var segmentFlag = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        departureMonThurs.delegate = self
        departureFri.delegate = self
        departureSat.delegate = self
        departureSun.delegate = self
        returnMonThurs.delegate = self
        returnFri.delegate = self
        returnSat.delegate = self
        returnSun.delegate = self
        
        saveDefaultsButton.layer.cornerRadius = 6.0
        saveDefaultsButton.layer.borderWidth = 3.0
        saveDefaultsButton.layer.borderColor = CBColor.purpleColor.cgColor
        loadDefaultsButton.layer.cornerRadius = 6.0
        loadDefaultsButton.layer.borderWidth = 3.0
        loadDefaultsButton.layer.borderColor = CBColor.purpleColor.cgColor
        calculateButton.layer.cornerRadius = 6.0
        calculateButton.layer.borderWidth = 3.0
        calculateButton.layer.borderColor = CBColor.purpleColor.cgColor
        
        if #available(iOS 13.0, *) {
            saveDefaultsButton.setTitleColor(.label, for: .normal)
            saveDefaultsButton.setTitleColor(.label, for: .selected)
            loadDefaultsButton.setTitleColor(.label, for: .normal)
            loadDefaultsButton.setTitleColor(.label, for: .selected)
            calculateButton.setTitleColor(.label, for: .normal)
            calculateButton.setTitleColor(.label, for: .selected)
        } else {
            saveDefaultsButton.titleLabel?.textColor = .black
            loadDefaultsButton.titleLabel?.textColor = .black
            calculateButton.titleLabel?.textColor = .black
        }
        
        let defaultCommuteTimes = UserDefaults.standard.array(forKey: kCBDefaultCommutingTimesKey)
        let count = defaultCommuteTimes?.count
        
        loadDefaultsButton.layer.borderColor = count ?? 0 > 0 ? CBColor.purpleColor.cgColor : UIColor.gray.cgColor
        loadDefaultsButton.alpha = count ?? 0 > 0 ? 1.0 : 0.7;
        
        noMidCheckButton.setImage(UIImage(named: "RadioButton-On"), for: .normal)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let lineSort = self.lineSort {
            var variables = NSMutableDictionary(dictionary: lineSort.variables!)
            
            if var time = variables[BISortMonThursDepartTimeVariablesKey] as? Int {
                var dict2 = [String: Any]()
                variables.forEach { dict2[$0.0 as! String] = Int(String(describing: $0.1)) }
                variables = NSMutableDictionary(dictionary: dict2)
                if time > -1  && time > 0{
                    departureMonThurs.text = String(format: "%04zd", time)
                }
                time = variables.object(forKey: BISortMonThursReturnTimeVariablesKey) as? Int ?? 0
                if time < 3000  && time > 0{
                    returnMonThurs.text = String(format: "%04zd", time)
                }
                time = variables.object(forKey: BISortFriDepartTimeVariablesKey) as? Int ?? 0
                if time > -1  && time > 0{
                    departureFri.text = String(format: "%04zd", time)
                }
                time = variables.object(forKey: BISortFriReturnTimeVariablesKey) as? Int ?? 0
                if time < 3000  && time > 0{
                    returnFri.text = String(format: "%04zd", time)
                }
                time = variables.object(forKey: BISortSatDepartTimeVariablesKey) as? Int ?? 0
                if time > -1  && time > 0{
                    departureSat.text = String(format: "%04zd", time)
                }
                time = variables.object(forKey: BISortSatReturnTimeVariablesKey) as? Int ?? 0
                if time < 3000  && time > 0{
                    returnSat.text = String(format: "%04zd", time)
                }
                time = variables.object(forKey: BISortSunDepartTimeVariablesKey) as? Int ?? 0
                if time > -1  && time > 0{
                    departureSun.text = String(format: "%04zd", time)
                }
                time = variables.object(forKey: BISortSunReturnTimeVariablesKey) as? Int ?? 0
                if time < 3000  && time > 0{
                    returnSun.text = String(format: "%04zd", time)
                }
            }
            else {
                var time = Int(variables[BISortMonThursDepartTimeVariablesKey] as? String ?? "0")!
                if time > -1  && time > 0{
                    departureMonThurs.text = String(format: "%04zd", time)
                } else {
                    departureMonThurs.text = ""
                }
                time = Int(variables.object(forKey: BISortMonThursReturnTimeVariablesKey) as? String ?? "0")!
                if time < 3000  && time > 0{
                    returnMonThurs.text = String(format: "%04zd", time)
                } else {
                    returnMonThurs.text = ""
                }
                time = Int(variables.object(forKey: BISortFriDepartTimeVariablesKey) as? String ?? "0")!
                if time > -1  && time > 0{
                    departureFri.text = String(format: "%04zd", time)
                } else {
                    departureFri.text = ""
                }
                time = Int(variables.object(forKey: BISortFriReturnTimeVariablesKey) as? String ?? "0")!
                if time < 3000  && time > 0{
                    returnFri.text = String(format: "%04zd", time)
                } else {
                    returnFri.text = ""
                }
                time = Int(variables.object(forKey: BISortSatDepartTimeVariablesKey) as? String ?? "0")!
                if time > -1  && time > 0{
                    departureSat.text = String(format: "%04zd", time)
                } else {
                    departureSat.text = ""
                }
                time = Int(variables.object(forKey: BISortSatReturnTimeVariablesKey) as? String ?? "0")!
                if time < 3000  && time > 0{
                    returnSat.text = String(format: "%04zd", time)
                } else {
                    returnSat.text = ""
                }
                time = Int(variables.object(forKey: BISortSunDepartTimeVariablesKey) as? String ?? "0")!
                if time > -1  && time > 0{
                    departureSun.text = String(format: "%04zd", time)
                } else {
                    departureSun.text = ""
                }
                time = Int(variables.object(forKey: BISortSunReturnTimeVariablesKey) as? String ?? "0")!
                if time < 3000  && time > 0{
                    returnSun.text = String(format: "%04zd", time)
                } else {
                    returnSun.text = ""
                }
            }
            var checksate = variables.object(forKey: BISortNoMidCheckStateVariablesKey) as? Bool ?? false
            if segmentFlag == 0 {
                if checksate {
                    noMidCheckButton.setImage(UIImage(named: "RadioButton-On"), for: .normal)
                }
                else {
                    noMidCheckButton.setImage(UIImage(named: "radioButton-Off"), for: .normal)
                }
            }
            else {
                if segmentFlag == 1 {
                    noMidCheckButton.setImage(UIImage(named: "RadioButton-On"), for: .normal)
                    checksate = true
                    segmentFlag = 0
                }
                else{
                    noMidCheckButton.setImage(UIImage(named: "radioButton-Off"), for: .normal)
                    checksate = false
                    segmentFlag = 0
                }
            }
            if lineSort.ascending?.boolValue ?? false {
                self.segmentedControl.selectedSegmentIndex = 0
            }
            else{
                self.segmentedControl.selectedSegmentIndex = 1
            }
            isNoMidChecked = checksate
        }
        saveDefaultsButton.layer.cornerRadius = 6.0
        saveDefaultsButton.layer.borderWidth = 3.0
        saveDefaultsButton.layer.borderColor = CBColor.purpleColor.cgColor
        let defaultCommuteTimes = UserDefaults.standard.array(forKey: kCBDefaultCommutingTimesKey)
        let count = defaultCommuteTimes?.count
        loadDefaultsButton.layer.borderColor = count ?? 0 > 0 ? CBColor.purpleColor.cgColor : UIColor.gray.cgColor
        loadDefaultsButton.alpha = count ?? 0 > 0 ? 1.0 : 0.7;
        // Added due to iOS 7 bug of the alpha not trickling down to the titleLabel
        loadDefaultsButton.titleLabel?.alpha = count ?? 0 > 0 ? 1.0 : 0.7;
        calculateButton.isSelected = true
        saveDefaultsButton.isSelected = true
        loadDefaultsButton.isSelected = true
    }
    
    //This function will call initialy from cell for row at indexPath
    func CalculateCommutingManualSort() {
        let reslutsSort = (CBGlobalMethods.shared.selectedBidPeriod!.lineSorts!.allObjects as NSArray).filtered(using: NSPredicate(format: "category == 4")) as! [BILineSort]
        
        if reslutsSort.count > 0 {
            let sort = reslutsSort[0]
            // setting the segment control accoeding to coredata values
            let bool = !sort.ascending!.boolValue
            self.segmentedControl.selectedSegmentIndex = bool.intValue
            do {
                let resultsFilter = (CBGlobalMethods.shared.selectedBidPeriod!.lineFilters!.allObjects as NSArray).filtered(using: NSPredicate(format: "category == 12")) as! [BIFilterRule]
                if resultsFilter.count > 0 {
                    let rule = resultsFilter[0]
                    var variables = NSDictionary(dictionary: rule.variables!) as! [String: Any]
                    var time = variables[BIFilterRuleMonThursDepartTimeVariablesKey] as! Int
                    if let NoMidCheckState = variables[BISortNoMidCheckStateVariablesKey] as? Bool {
                        self.noMidCheckButton.isSelected = NoMidCheckState
                    }
                    if time > -1 && time != 0 {
                        departureMonThurs.text = "\(time)"
                        variables[BISortMonThursDepartTimeVariablesKey] = NSNumber(integerLiteral: time)
                    } else {
                        variables[BISortMonThursDepartTimeVariablesKey] = NSNumber(integerLiteral: -1)
                    }
                    time = variables[BIFilterRuleMonThursReturnTimeVariablesKey] as? Int ?? 3000
                    if time < 3000 && time != 0 {
                        returnMonThurs.text = "\(time)"
                        variables[BISortMonThursReturnTimeVariablesKey] = NSNumber(integerLiteral: time)
                    } else {
                        variables[BISortMonThursReturnTimeVariablesKey] = NSNumber(integerLiteral: 3000)
                    }
                    // Fri
                    time = variables[BIFilterRuleFriDepartTimeVariablesKey]as? Int ?? -1
                    if time > -1 && time != 0 {
                        departureFri.text = "\(time)" //%04zd
                        variables[BISortFriDepartTimeVariablesKey] = NSNumber(integerLiteral: time)
                    } else {
                        variables[BISortFriDepartTimeVariablesKey] = NSNumber(integerLiteral: -1)
                    }
                    
                    time = variables[BIFilterRuleFriReturnTimeVariablesKey] as? Int ?? 3000
                    if time < 3000 && time != 0 {
                        returnFri.text = "\(time)"
                        variables[BISortFriReturnTimeVariablesKey] = NSNumber(integerLiteral: time)
                    } else {
                        variables[BISortFriReturnTimeVariablesKey] = NSNumber(integerLiteral: 3000)
                    }
                    // Sat
                    time = variables[BIFilterRuleSatDepartTimeVariablesKey] as? Int ?? -1
                    if time > -1  && time != 0{
                        departureSat.text = "\(time)"
                        variables[BISortSatDepartTimeVariablesKey] = NSNumber(integerLiteral: time)
                    } else {
                        variables[BISortSatDepartTimeVariablesKey] = NSNumber(integerLiteral: -1)
                    }
                    
                    time = variables[BIFilterRuleSatReturnTimeVariablesKey] as? Int ?? 3000
                    if time < 3000 && time != 0 {
                        returnSat.text = "\(time)"
                        variables[BISortSatReturnTimeVariablesKey] = NSNumber(integerLiteral: time)
                    } else {
                        variables[BISortSatReturnTimeVariablesKey] = NSNumber(integerLiteral: 3000)
                    }
                    // Sun
                    time = variables[BIFilterRuleSunDepartTimeVariablesKey] as? Int ?? -1
                    if time > -1  && time != 0{
                        departureSun.text = "\(time)"
                        variables[BISortSunDepartTimeVariablesKey] = NSNumber(integerLiteral: time)
                    } else {
                        variables[BISortSunDepartTimeVariablesKey] = NSNumber(integerLiteral: -1)
                    }
                    
                    time = variables[BIFilterRuleSunReturnTimeVariablesKey] as? Int ?? 3000
                    if time < 3000  && time != 0{
                        returnSun.text = "\(time)"
                        variables[BISortSunReturnTimeVariablesKey] = NSNumber(integerLiteral: time)
                    } else {
                        variables[BISortSunReturnTimeVariablesKey] = NSNumber(integerLiteral: 3000)
                    }
                    
                    let checksate = variables[BIFilterRuleNoMidCheckStateVariablesKey] as? Bool ?? false
                    variables[BISortNoMidCheckStateVariablesKey] = NSNumber(booleanLiteral: checksate)
                    self.lineSort!.variables = variables as NSDictionary
                    let selected = NSNumber(integerLiteral: segmentedControl.selectedSegmentIndex)
                    
                    switch selected.intValue {
                    case 0:
                        self.lineSort!.keyPath = "commutabilityOverall"
                        self.lineSort!.ascending = NSNumber(booleanLiteral: true)
                        break
                    case 1:
                        self.lineSort!.keyPath = "commutabilityOverall"
                        self.lineSort!.ascending = NSNumber(booleanLiteral: false)
                        break
                    default:
                        break
                    }
                    try self.lineSort?.managedObjectContext?.save()
                    try? self.context!.save()
                }
            } catch {
                print(error)
            }
        }
    }
    
    @objc func CalculateCommuteFrom() {
        let variables = lineSort!.variables! as! [String : Any]
        let resultFilter = (CBGlobalMethods.shared.selectedBidPeriod!.lineFilters!.allObjects as NSArray).filtered(using: NSPredicate(format: "category == 12")) as! [BIFilterRule]
        if resultFilter.count > 0 {
            let rule = resultFilter[0]
            var filteVrs = rule.variables! as! [String : Any]
            filteVrs["MON_THURS_RETURN"] = variables["MON_THURS_RETURN"] as! Int
            filteVrs["MON_THURS_DEPART"] = variables["MON_THURS_DEPART"] as! Int
            filteVrs["SAT_DEPART"] = variables["SAT_DEPART"] as! Int
            filteVrs["SAT_RETURN"] = variables["SAT_RETURN"] as! Int
            filteVrs["FRI_DEPART"] = variables["FRI_DEPART"] as! Int
            filteVrs["FRI_RETURN"] = variables["FRI_RETURN"] as! Int
            filteVrs["SUN_DEPART"] = variables["SUN_DEPART"] as! Int
            filteVrs["SUN_RETURN"] = variables["SUN_RETURN"] as! Int
            filteVrs["NoMidCheckState"] = (variables["NoMidCheckState"] as! NSNumber).boolValue
            rule.variables = filteVrs as NSDictionary
            try? self.bidPeriod.managedObjectContext?.save()
        }
        self.calculateSortWith(variables: variables)
    }
    
    func calculateSortWith(variables: [String: Any]) {
        self.lineSort!.variables = variables as NSDictionary
        let checkState = (variables[BIFilterRuleNoMidCheckStateVariablesKey] as! NSNumber).boolValue
        self.isNoMidChecked = checkState
        for line in self.bidPeriod.lines?.allObjects as! [BILine] {
            for trip in line.orderedTrips as! [BITrip] {
                trip.info?.isFullyCommutable = NSNumber(booleanLiteral: false)
                trip.highlightCount = 0
            }
        }
        try? self.context?.save()
        self.lineSort!.keyPath = "commutabilityOverall"
        if lineSort.ascending == nil {
            self.lineSort.ascending = NSNumber(booleanLiteral: true)
        }
        try? self.lineSort!.managedObjectContext?.save()
        if setCommuteTimeForDays() {
            let obj = CBCommutingCellHelper()
            let depMonThurs : String = (variables["MON_THURS_DEPART"] as? Int ?? -1) == -1 ? "" : "\(variables["MON_THURS_DEPART"] as! Int)"
            let returnMonThurs : String = (variables["MON_THURS_RETURN"] as? Int ?? 3000) == 3000 ? "" : "\(variables["MON_THURS_RETURN"] as! Int)"
            let depFriday : String = (variables["FRI_DEPART"] as? Int ?? -1) == -1 ? "" : "\(variables["FRI_DEPART"] as! Int)"
            let returnFriday : String = (variables["FRI_RETURN"] as? Int ?? 3000) == 3000 ? "" : "\(variables["FRI_RETURN"] as! Int)"
            let depSat : String = (variables["SAT_DEPART"] as? Int ?? -1) == -1 ? "" : "\(variables["SAT_DEPART"] as! Int)"
            let returnSat : String = (variables["SAT_RETURN"] as? Int ?? 3000) == 3000 ? "" : "\(variables["SAT_RETURN"] as! Int)"
            let depSun : String = (variables["SUN_DEPART"] as? Int ?? -1) == -1 ? "" : "\(variables["SUN_DEPART"] as! Int)"
            let returnSun : String = (variables["SUN_RETURN"] as? Int ?? 3000) == 3000 ? "" : "\(variables["SUN_RETURN"] as! Int)"
            let NoMidCheckState : Bool = (variables["NoMidCheckState"] as? NSNumber ?? 0).boolValue
            
            if NoMidCheckState == true {
                obj.calculateCommuteLinePropertiesForWorkblock(withDepartureMonThursText: depMonThurs, departureFriText: depFriday, departureSatText: depSat, departureSunText: depSun, returnMonThursText: returnMonThurs, returnSunText: returnSun, returnSatText: returnSat, returnFriText: returnFriday, bidPeriod: bidPeriod)
            }
            else {
                obj.calculateCommuteLinePropertiesForManualTrips(withDepartureMonThursText: depMonThurs, departureFriText: depFriday, departureSatText: depSat, departureSunText: depSun, returnMonThursText: returnMonThurs, returnSunText: returnSun, returnSatText: returnSat, returnFriText: returnFriday, bidPeriod: bidPeriod)
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }

    @IBAction func btnCloseAction(_ sender: Any) {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        isNoMidChecked = false
        
        // Set all text fields to nil
        departureMonThurs.text = nil
        returnMonThurs.text = nil
        departureFri.text = nil
        returnFri.text = nil
        departureSat.text = nil
        returnSat.text = nil
        departureSun.text = nil
        returnSun.text = nil
        
        let resultsFilter = (CBGlobalMethods.shared.selectedBidPeriod!.lineFilters!.allObjects as NSArray).filtered(using: NSPredicate(format: "category == 12")) as! [BIFilterRule]
        if (resultsFilter.count == 0) {
            for line in CBGlobalMethods.shared.selectedBidPeriod!.orderedLines() {
                line.totalCommutes = NSNumber(integerLiteral: 0)
                line.commutableBacks = NSNumber(integerLiteral: 0)
                line.commutableFronts = NSNumber(integerLiteral: 0)
                line.commutabilityBack = NSNumber(integerLiteral: 0)
                line.commutabilityFront = NSNumber(integerLiteral: 0)
                line.commutabilityOverall = NSNumber(integerLiteral: 0)
                for trip in line.orderedTrips as! [BITrip] {
                    trip.info?.isFullyCommutable = NSNumber(booleanLiteral: false)
                    trip.highlightCount = NSNumber(integerLiteral: 0)
                }
            }
            try? self.context?.save()
            let result = CBGlobalMethods.shared.selectedBidPeriod?.commuteTime?.allObjects
            for basket in result! {
                self.context?.delete(basket as! NSManagedObject)
            }
            do {
                try self.context?.save()
                let variables = NSMutableDictionary(dictionary: lineSort!.variables ?? [:])
                variables[BISortMonThursDepartTimeVariablesKey] = NSNumber(integerLiteral: -1)
                variables[BISortMonThursReturnTimeVariablesKey] = NSNumber(integerLiteral: 3000)
                variables[BISortFriDepartTimeVariablesKey] = NSNumber(integerLiteral: -1)
                variables[BISortFriReturnTimeVariablesKey] = NSNumber(integerLiteral: 3000)
                variables[BISortSatDepartTimeVariablesKey] = NSNumber(integerLiteral: -1)
                variables[BISortSatReturnTimeVariablesKey] = NSNumber(integerLiteral: 3000)
                variables[BISortSunDepartTimeVariablesKey] = NSNumber(integerLiteral: -1)
                variables[BISortSunReturnTimeVariablesKey] = NSNumber(integerLiteral: 3000)
                self.lineSort.variables = variables
            }
            catch {
                print("\(error.localizedDescription)")
            }
        }
        else {
            let objResults = CBGlobalMethods.shared.selectedBidPeriod!.lines?.allObjects as! [BILine]
            for line in objResults {
                for trip in line.orderedTrips as! [BITrip] {
                    trip.highlightCount = NSNumber(integerLiteral: 0)
                }
            }
            do {
                try self.context?.save()
            }
            catch {
                print("error saving : \(error.localizedDescription)")
            }
        }
        self.lineSort.managedObjectContext?.delete(self.lineSort!)
        try? self.lineSort?.managedObjectContext?.save()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }
    }
    
    func setCommuteTimeForDays() -> Bool  {
            let context = self.bidPeriod?.managedObjectContext
            let result = CBGlobalMethods.shared.selectedBidPeriod!.commuteTime?.allObjects
            for basket in result! {
                context?.delete(basket as! NSManagedObject)
            }
            let startDate = self.startOfMonth()
            let dateFormat = DateFormatter()
            var endDate = self.endOfMonth()
            let daysToAdd = 4
            endDate = endDate.addingTimeInterval(TimeInterval(60 * 60 * 24 * daysToAdd))
            
            let minDateString = "01/01/0001 00:00:00"
            
            dateFormat.timeZone = TimeZone(secondsFromGMT: 0)
            dateFormat.locale = Locale.current
            dateFormat.dateFormat = "MM/dd/yyyy hh:mm:ss"
            
            let minDate = dateFormat.date(from: minDateString)
            var oneWeek = DateComponents()
            oneWeek.day = 1
            oneWeek.hour = 1
            //
            var TempStartDate = startDate
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd"
            
            let dateFormatterForDayname = DateFormatter()
            dateFormatterForDayname.timeZone = TimeZone(secondsFromGMT: 0)
            dateFormatterForDayname.dateFormat = "EEEE"

            while TempStartDate.compare(endDate) == .orderedAscending || TempStartDate.compare(endDate) == .orderedSame {
                //Set WorkBlock Details
                let CommuteEntity = NSEntityDescription.entity(forEntityName: "CommuteTime", in: (context!))
                var ObjcommuteTime: CommuteTime? = nil
                ObjcommuteTime = CommuteTime(entity: CommuteEntity!, insertInto: (bidPeriod?.managedObjectContext)!)
                ObjcommuteTime?.commutable = bidPeriod
                let date = formatter.string(from: TempStartDate)
                ObjcommuteTime?.bidDay = TempStartDate as NSDate? as Date?
                ObjcommuteTime?.bidDayStringValue = date
                ObjcommuteTime?.earliestArrivel = minDate as Date?
                ObjcommuteTime?.latestDeparture = minDate as Date?
                let dayName = dateFormatterForDayname.string(from: TempStartDate)
                
                let variables = self.lineSort!.variables! as NSDictionary
                var depMonThurs1 : String = (variables["MON_THURS_DEPART"] as? Int ?? -1) == -1 ? "" : "\(variables["MON_THURS_DEPART"] as! Int)"
                var returnMonThurs1 : String = (variables["MON_THURS_RETURN"] as? Int ?? 3000) == 3000 ? "" : "\(variables["MON_THURS_RETURN"] as! Int)"
                var depFriday1 : String = (variables["FRI_DEPART"] as? Int ?? -1) == -1 ? "" : "\(variables["FRI_DEPART"] as! Int)"
                var returnFriday1 : String = (variables["FRI_RETURN"] as? Int ?? 3000) == 3000 ? "" : "\(variables["FRI_RETURN"] as! Int)"
                var depSat1 : String = (variables["SAT_DEPART"] as? Int ?? -1) == -1 ? "" : "\(variables["SAT_DEPART"] as! Int)"
                var returnSat1 : String = (variables["SAT_RETURN"] as? Int ?? 3000) == 3000 ? "" : "\(variables["SAT_RETURN"] as! Int)"
                var depSun1 : String = (variables["SUN_DEPART"] as? Int ?? -1) == -1 ? "" : "\(variables["SUN_DEPART"] as! Int)"
                var returnSun1 : String = (variables["SUN_RETURN"] as? Int ?? 3000) == 3000 ? "" : "\(variables["SUN_RETURN"] as! Int)"
         
                depMonThurs1 = self.getCompleteTime(timeString: depMonThurs1)
                returnMonThurs1 = self.getCompleteTime(timeString: returnMonThurs1)
                depFriday1 = self.getCompleteTime(timeString: depFriday1)
                returnFriday1 = self.getCompleteTime(timeString: returnFriday1)
                depSat1 = self.getCompleteTime(timeString: depSat1)
                returnSat1 = self.getCompleteTime(timeString: returnSat1)
                depSun1 = self.getCompleteTime(timeString: depSun1)
                returnSun1 = self.getCompleteTime(timeString: returnSun1)
                
                
                
                if depMonThurs1.length > 0 {
                    if dayName == "Monday" || dayName == "Tuesday" || dayName == "Wednesday" || dayName == "Thursday" {
                        ObjcommuteTime?.earliestArrivel = addMinuteWithDates(currentDate: TempStartDate, Minutes: depMonThurs1)
                    }
                }
                if returnMonThurs1.length > 0 {
                    if dayName == "Monday" || dayName == "Tuesday" || dayName == "Wednesday" || dayName == "Thursday" {
                        ObjcommuteTime?.latestDeparture = self.addMinuteWithDates(currentDate: TempStartDate, Minutes: returnMonThurs1)
                    }
                }
                if depFriday1.length > 0 {
                    if dayName == "Friday" {
                        ObjcommuteTime?.earliestArrivel = self.addMinuteWithDates(currentDate: TempStartDate, Minutes: depFriday1)
                    }
                }
                if returnFriday1.length > 0 {
                    if dayName == "Friday" {
                        ObjcommuteTime?.latestDeparture = self.addMinuteWithDates(currentDate: TempStartDate, Minutes: returnFriday1)
                    }
                }
                if depSat1.length > 0 {
                    if dayName == "Saturday" {
                        ObjcommuteTime?.earliestArrivel = self.addMinuteWithDates(currentDate: TempStartDate, Minutes: depSat1)
                    }
                }
                if returnSat1.length > 0 {
                    if dayName == "Saturday" {
                        ObjcommuteTime?.latestDeparture = self.addMinuteWithDates(currentDate: TempStartDate, Minutes: returnSat1)
                    }
                }
                if depSun1.length > 0 {
                    if dayName == "Sunday" {
                        ObjcommuteTime?.earliestArrivel = self.addMinuteWithDates(currentDate: TempStartDate, Minutes: depSun1)
                    }
                }
                if returnSun1.length > 0 {
                    if dayName == "Sunday" {
                        ObjcommuteTime?.latestDeparture = self.addMinuteWithDates(currentDate: TempStartDate, Minutes: returnSun1)
                    }
                }
                
                ObjcommuteTime?.type = 0
                let tempdate = Calendar.current.date(byAdding: oneWeek, to: TempStartDate)
                var cal = Calendar(identifier: .gregorian)
                cal.timeZone = TimeZone(secondsFromGMT: 0)!
                var comps: DateComponents = cal.dateComponents([.year, .month, .day], from: tempdate!)
                comps.hour = 0
                comps.minute = 0
                comps.second = 0
                TempStartDate = cal.date(from: comps)!
                
                
                if TempStartDate.compare(endDate) == .orderedSame {
                    try? self.context!.save()
                    return true
                }
            }
            try? self.context!.save()
            return false
        }
    
    func startOfMonth() -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let day: NSNumber!
        let month: NSNumber!
        let year: NSNumber!
        var components = DateComponents()
        if (self.bidPeriod.isFABid() == true && self.bidPeriod!.month?.intValue == 2) {
            day = NSNumber(integerLiteral: 31)
            month = NSNumber(integerLiteral: 1)
            year = self.bidPeriod!.year
        }
        else if (self.bidPeriod.isFABid() == true && self.bidPeriod!.month?.intValue == 3) {
            day = NSNumber(integerLiteral: 2)
            month = self.bidPeriod!.month
            year = self.bidPeriod!.year
        }
        else {
            day = NSNumber(integerLiteral: 1)
            month = self.bidPeriod!.month
            year = self.bidPeriod!.year
        }
        components.day = day.intValue
        components.month = month.intValue
        components.year = year.intValue
        components.minute = 0
        components.hour = 0
        components.second = 0
        return calendar.date(from: components)!
    }
    
    func endOfMonth() -> Date {
        var daysToAdd = 1
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        var components = DateComponents()
        let day = NSNumber(integerLiteral: 1)
        let month = self.bidPeriod!.month!
        let year = self.bidPeriod!.year!
        components.day = day.intValue
        components.month = month.intValue
        components.year = year.intValue
        components.hour = 0
        components.minute = 0
        components.second = 0
//        components.isLeapMonth = true
        
        var dateComponents = DateComponents()
        dateComponents.day = -1
        dateComponents.month = 1
        var lastDayOfMonth = calendar.date(byAdding: dateComponents, to: calendar.date(from: components)!)
        
        //in case of februaury month for FA the last date should be march 1.
        if self.bidPeriod.isFABid() == true && self.bidPeriod.month?.intValue == 2 {
            lastDayOfMonth = lastDayOfMonth?.addingTimeInterval(TimeInterval(60 * 60 * 24 * daysToAdd))
            return lastDayOfMonth!
        }
        //in case of January month for FA the last date should be january 30.
        else if self.bidPeriod.isFABid() == true &&  self.bidPeriod.month?.intValue == 1 {
            daysToAdd = -1
            lastDayOfMonth = lastDayOfMonth?.addingTimeInterval(TimeInterval(daysToAdd * 24 * 60 * 60))
            return lastDayOfMonth!
        }
        //for all remaining months the last date should be corresponding last dates of the month for FA.
        else {
            return lastDayOfMonth!
        }
    }
    
    func getCompleteTime(timeString: String) -> String {
        if (timeString == "-1" || timeString == "3000") {
            return ""
        }
        var timeStr = timeString
        while timeStr.length < 4 {
            timeStr = "0\(timeStr)"
        }
        return timeStr
    }
    
    func addMinuteWithDates(currentDate: Date, Minutes mns: String) -> Date {
        var temp = ""
        if mns.count == 4 {
            temp = mns
        }
        else if mns.count == 3 {
            temp = "0\(mns)"
        }
        else if mns.count == 2 {
            temp = "00\(mns)"
        }
        else if mns.count == 1 {
            temp = "000\(mns)"
        }
        else {
            temp = "0000"
        }
        var hours = Int(temp.substring(to: 2))!
        let mins = Int(temp.substring(with: 2..<2))!
        hours = (hours * 60) + mins
        let modifiedDate = currentDate.addingTimeInterval(TimeInterval(hours * 60))
        return modifiedDate
    }
    
    func didChangeState(state: Bool) {
        let variables = NSMutableDictionary(dictionary: self.lineSort!.variables!)
        if noMidCheckButton.imageView?.image == UIImage(named: "RadioButton-On") {
            isNoMidChecked = true
        }
        else {
            isNoMidChecked = false
        }
        variables.setObject(isNoMidChecked, forKey: BISortNoMidCheckStateVariablesKey as NSCopying)
        self.lineSort!.variables = variables
        NotificationCenter.default.post(name: NSNotification.Name("ReloadFilterTable"), object: self)
    }
    
    @IBAction func btnInfoNoMidTapped(_ sender: Any) {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        let storybIard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storybIard.instantiateViewController(withIdentifier: "RefreshController") as! RefreshController
        vc.popOverType = PopoverViewType.CommutingManualNoMidInfoSort
        vc.bidPeriod = self.bidPeriod
        vc.selectedValue = (sender as! UIButton).currentTitle ?? ""
        vc.modalPresentationStyle = .popover
        vc.showPopover(sourceView: self, sourceRect: self.btnNoMidInfo.frame)
    }
    
    @IBAction func btnNoMidActionSelection(sender: UIButton) {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        let variables = NSMutableDictionary(dictionary: self.lineSort!.variables!)
        if noMidCheckButton.imageView?.image == UIImage(named: "radioButton-Off") {
            sender.setImage(UIImage(named: "RadioButton-On"), for: .normal)
            isNoMidChecked = true
        }
        else {
            sender.setImage(UIImage(named: "radioButton-Off"), for: .normal)
            isNoMidChecked = false
        }
        variables.setObject(isNoMidChecked, forKey: BISortNoMidCheckStateVariablesKey as NSCopying)
        self.lineSort!.variables = variables
        NotificationCenter.default.post(name: NSNotification.Name("ReloadFilterTable"), object: self)
    }
    
    @IBAction func loadDefaults(_ sender: Any) {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        loadDefaults()
    }
    
    func loadDefaults() {
        var defaultCommuteTimes = NSArray()
        if UserDefaults.standard.value(forKey: kCBDefaultCommutingTimesKey) != nil {
            defaultCommuteTimes = (UserDefaults.standard.value(forKey: kCBDefaultCommutingTimesKey) as? NSArray)!
        }
        calculateButton.isSelected = true
        saveDefaultsButton.isSelected = true
        loadDefaultsButton.isSelected = true
        
        let state: Bool = UserDefaults.standard.bool(forKey: "NoMidCheckStateCommute")
        self.noMidCheckButton.isSelected = state
        if state {
            noMidCheckButton.setImage(UIImage(named: "RadioButton-On"), for: .normal)
        }
        else {
            noMidCheckButton.setImage(UIImage(named: "radioButton-Off"), for: .normal)
        }
        if defaultCommuteTimes.count > 0 {
            let monThursDept = (defaultCommuteTimes[0] as! NSNumber).intValue
            let monThursRet = (defaultCommuteTimes[1] as! NSNumber).intValue
            let friDept = (defaultCommuteTimes[2] as! NSNumber).intValue
            let friRet = (defaultCommuteTimes[3] as! NSNumber).intValue
            let satDept = (defaultCommuteTimes[4] as! NSNumber).intValue
            let SatRet = (defaultCommuteTimes[5] as! NSNumber).intValue
            let SunDept = (defaultCommuteTimes[6] as! NSNumber).intValue
            let SunRet = (defaultCommuteTimes[7] as! NSNumber).intValue
            
            if monThursDept > -1 {
                departureMonThurs.text = String(format: "%04zd", monThursDept)
            }
            else {
                departureMonThurs.text = nil
            }
            if monThursRet < 3000 {
                returnMonThurs.text = String(format: "%04zd", monThursRet)
            }
            else {
                returnMonThurs.text = nil
            }
            if friDept > -1 {
                departureFri.text = String(format: "%04zd", friDept)
            }
            else {
                departureFri.text = nil
            }
            if friRet < 3000 {
                returnFri.text = String(format: "%04zd", friRet)
            }
            else {
                returnFri.text = nil
            }
            if satDept > -1 {
                departureSat.text = String(format: "%04zd", satDept)
            }
            else {
                departureSat.text = nil
            }
            if SatRet < 3000 {
                returnSat.text = String(format: "%04zd", SatRet)
            }
            else {
                returnSat.text = nil
            }
            if SunDept > -1 {
                departureSun.text = String(format: "%04zd", SunDept)
            }
            else {
                departureSun.text = nil
            }
            if SunRet < 3000 {
                returnSun.text = String(format: "%04zd", SunRet)
            }
            else {
                returnSun.text = nil
            }
            
            var variables = NSMutableDictionary(dictionary: self.lineSort!.variables!)
            if departureMonThurs.text!.length > 0 {
                variables[BISortMonThursDepartTimeVariablesKey] = NSNumber(integerLiteral: Int(departureMonThurs!.text!)!)
            }
            else {
                variables[BISortMonThursDepartTimeVariablesKey] = NSNumber(integerLiteral: -1)
            }
            if returnMonThurs.text!.length > 0 {
                variables[BISortMonThursReturnTimeVariablesKey] = NSNumber(integerLiteral: Int(returnMonThurs.text!)!)
            }
            else {
                variables[BISortMonThursReturnTimeVariablesKey] = NSNumber(integerLiteral: 3000)
            }
            if departureFri.text!.length > 0 {
                variables[BISortFriDepartTimeVariablesKey] = NSNumber(integerLiteral: Int(departureFri!.text!)!)
            }
            else {
                variables[BISortFriDepartTimeVariablesKey] = NSNumber(integerLiteral: -1)
            }
            if returnFri.text!.length > 0 {
                variables[BISortFriReturnTimeVariablesKey] = NSNumber(integerLiteral: Int(returnFri.text!)!)
            }
            else {
                variables[BISortFriReturnTimeVariablesKey] = NSNumber(integerLiteral: 3000)
            }
            if departureSat.text!.length > 0 {
                variables[BISortSatDepartTimeVariablesKey] = NSNumber(integerLiteral: Int(departureSat!.text!)!)
            }
            else {
                variables[BISortSatDepartTimeVariablesKey] = NSNumber(integerLiteral: -1)
            }
            if returnSat.text!.length > 0 {
                variables[BISortSatReturnTimeVariablesKey] = NSNumber(integerLiteral: Int(returnSat.text!)!)
            }
            else {
                variables[BISortSatReturnTimeVariablesKey] = NSNumber(integerLiteral: 3000)
            }
            if departureSun.text!.length > 0 {
                variables[BISortSunDepartTimeVariablesKey] = NSNumber(integerLiteral: Int(departureSun!.text!)!)
            }
            else {
                variables[BISortSunDepartTimeVariablesKey] = NSNumber(integerLiteral: -1)
            }
            if returnSun.text!.length > 0 {
                variables[BISortSunReturnTimeVariablesKey] = NSNumber(integerLiteral: Int(returnSun.text!)!)
            }
            else {
                variables[BISortSunReturnTimeVariablesKey] = NSNumber(integerLiteral: 3000)
            }
            self.lineSort.variables = variables
        }
        else {
            AlertService.showAlertForTopVC(title: "No saved defaults exist.", message: "")
        }
    }
    
    @IBAction func saveCurrentValuesAsDefaults(_ sender: Any) {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod!.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod!.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        saveDefaultsButton.isSelected = true
        calculateButton.isSelected = true
        if noMidCheckButton.imageView?.image == UIImage(named: "RadioButton-On") {
            UserDefaults.standard.set(true, forKey: "NoMidCheckStateCommute")
        }
        else {
            UserDefaults.standard.set(true, forKey: "NoMidCheckStateCommute")
        }
        let defaultTimes = NSMutableArray(capacity: 8)
        
        if (departureMonThurs.text?.length)! > 0 {
            let timeDepartureMonThurs: Int? = Int(departureMonThurs.text!)!
            if timeDepartureMonThurs! > -1 {
                defaultTimes.add(Int(departureMonThurs.text!)!)
            }
            else {
                defaultTimes.add(-1)
            }
        }
        else {
            defaultTimes.add(-1)
        }
        if (returnMonThurs.text?.length)! > 0 {
            let timeReturnMonThurs: Int? = Int(returnMonThurs.text!)!
            if timeReturnMonThurs! < 3000 {
                defaultTimes.add(Int(returnMonThurs.text!)!)
            }
            else {
                defaultTimes.add(3000)
            }
        }
        else {
            defaultTimes.add(3000)
        }
        if (departureFri.text?.length)! > 0 {
            let timeDepartureFri: Int? = Int(departureFri.text!)!
            if timeDepartureFri! > -1 {
                defaultTimes.add(Int(departureFri.text!)!)
            }
            else {
                defaultTimes.add(-1)
            }
        }
        else {
            defaultTimes.add(-1)
        }
        if (returnFri.text?.length)! > 0 {
            let timeReturnFri: Int? = Int(returnFri.text!)!
            if timeReturnFri! < 3000 {
                defaultTimes.add(Int(returnFri.text!)!)
            }
            else {
                defaultTimes.add(3000)
            }
        }
        else {
            defaultTimes.add(3000)
        }
        if (departureSat.text?.length)! > 0 {
            let timeDepartureSat: Int? = Int(departureSat.text!)!
            if timeDepartureSat! > -1 {
                defaultTimes.add(Int(departureSat.text!)!)
            }
            else {
                defaultTimes.add(-1)
            }
        }
        else {
            defaultTimes.add(-1)
        }
        if (returnSat.text?.length)! > 0 {
            let timeReturnSat: Int? = Int(returnSat.text!)!
            if timeReturnSat! < 3000 {
                defaultTimes.add(Int(returnSat.text!)!)
            }
            else {
                defaultTimes.add(3000)
            }
        }
        else {
            defaultTimes.add(3000)
        }
        if (departureSun.text?.length)! > 0 {
            let timeDepartureSun: Int? = Int(departureSun.text!)!
            if timeDepartureSun! > -1 {
                defaultTimes.add(Int(departureSun.text!)!)
            }
            else {
                defaultTimes.add(-1)
            }
        }
        else {
            defaultTimes.add(-1)
        }
        if (returnSun.text?.length)! > 0 {
            let timeReturnSun: Int? = Int(returnSun.text!)!
            if timeReturnSun! < 3000 {
                defaultTimes.add(Int(returnSun.text!)!)
            }
            else {
                defaultTimes.add(3000)
            }
        }
        else {
            defaultTimes.add(3000)
        }
        UserDefaults.standard.set(defaultTimes, forKey: kCBDefaultCommutingTimesKey)
        calculateButton.isSelected = true
        if noMidCheckButton.imageView?.image == UIImage(named: "RadioButton-On") {
            UserDefaults.standard.set("1", forKey: kCBDefaultsCommutingNoMidKey)
        }
        else {
            UserDefaults.standard.set("1", forKey: kCBDefaultsCommutingNoMidKey)
        }
        setNeedsLayout()
        AlertService.showAlertForTopVC(title: "Commuting Defaults Saved!", message: "")
    }
    
    @IBAction func segementedControlAction(_ sender: UISegmentedControl) {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        activeTextfield?.resignFirstResponder()
        let selected = NSNumber(integerLiteral: sender.selectedSegmentIndex)
        try? context?.save()
        switch selected.intValue {
        case 0:
            self.lineSort!.keyPath = "commutabilityOverall";
            self.lineSort.ascending = NSNumber(booleanLiteral: true)
            break
        case 1:
            self.lineSort!.keyPath = "commutabilityOverall";
            self.lineSort.ascending = NSNumber(booleanLiteral: false)
            break
        default:
            break
        }
        if noMidCheckButton.imageView?.image == UIImage(named: "RadioButton-On") {
            segmentFlag = 1
        }
        else {
            segmentFlag = 2
        }
        try? self.lineSort?.managedObjectContext?.save()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }
    }
    
    @IBAction func calculateCommutingSort(_ sender: Any) {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        calculateButton.isSelected = true
        saveDefaultsButton.isSelected = true
        loadDefaultsButton.isSelected = true
        if (activeTextfield != nil) {
            let _ = textFieldShouldReturn(activeTextfield!)
        }
        self.updateSortVariableswithInputData()
        CBGlobalMethods.shared.showCustomActivityIndicator(message: "Calculating...", bgcolor: .purple, height: 100)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
            self.CalculateCommuteFrom()
            CBGlobalMethods.shared.hideCustomActivityIndicator()
        }
    }
    
    func calculateSortAfterVacationLoading() {
        
    }
}

extension CBCommutingSortCell: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField.text?.count ?? 0) != 0 {
            // Check to make sure the user didn't enter in a value greater than 60 for the minutes
            // or greater than 28 for the hours
            var minVal: Int = 0
            let timeVal = Int(textField.text ?? "") ?? 0
            let hundred: Int = timeVal / 100
            minVal = timeVal - (hundred * 100)
            if minVal > 59 || hundred > 28 {
                let alert = UIAlertController(title: "Invalid input.", message: "Please input 28 or less for the hours and 59 for less for the minutes.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler:{ (UIAlertAction)in
                }))
                UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                textField.text = ""
                return false
            } else {
                textField.text = String(format: "%04zd", Int(textField.text ?? "") ?? 0)
                textField.resignFirstResponder()
                activeTextfield = nil
                return true
            }
        } else {
            textField.resignFirstResponder()
            activeTextfield = nil
            return true
        }
    }
    
    func updateSortVariableswithInputData(){
        var variables = NSMutableDictionary(dictionary: self.lineSort!.variables!)
        if self.departureMonThurs.text!.length > 0 {
            variables[BISortMonThursDepartTimeVariablesKey] = NSNumber(integerLiteral: Int(departureMonThurs.text!)!)
        }
        else {
            variables[BISortMonThursDepartTimeVariablesKey] = NSNumber(integerLiteral: -1)
        }
        if self.returnMonThurs.text!.length > 0 {
            variables[BISortMonThursReturnTimeVariablesKey] = NSNumber(integerLiteral: Int(returnMonThurs.text!)!)
        }
        else {
            variables[BISortMonThursReturnTimeVariablesKey] = NSNumber(integerLiteral: 3000)
        }
        if self.departureFri.text!.length > 0 {
            variables[BISortFriDepartTimeVariablesKey] = NSNumber(integerLiteral: Int(departureFri.text!)!)
        }
        else {
            variables[BISortFriDepartTimeVariablesKey] = NSNumber(integerLiteral: -1)
        }
        if self.returnFri.text!.length > 0 {
            variables[BISortFriReturnTimeVariablesKey] = NSNumber(integerLiteral: Int(returnFri.text!)!)
        }
        else {
            variables[BISortFriReturnTimeVariablesKey] = NSNumber(integerLiteral: 3000)
        }
        if self.departureSat.text!.length > 0 {
            variables[BISortSatDepartTimeVariablesKey] = NSNumber(integerLiteral: Int(departureSat.text!)!)
        }
        else {
            variables[BISortSatDepartTimeVariablesKey] = NSNumber(integerLiteral: -1)
        }
        if self.returnSat.text!.length > 0 {
            variables[BISortSatReturnTimeVariablesKey] = NSNumber(integerLiteral: Int(returnSat.text!)!)
        }
        else {
            variables[BISortSatReturnTimeVariablesKey] = NSNumber(integerLiteral: 3000)
        }
        if self.departureSun.text!.length > 0 {
            variables[BISortSunDepartTimeVariablesKey] = NSNumber(integerLiteral: Int(departureSun.text!)!)
        }
        else {
            variables[BISortSunDepartTimeVariablesKey] = NSNumber(integerLiteral: -1)
        }
        if self.returnSun.text!.length > 0 {
            variables[BISortSunReturnTimeVariablesKey] = NSNumber(integerLiteral: Int(returnSun.text!)!)
        }
        else {
            variables[BISortSunReturnTimeVariablesKey] = NSNumber(integerLiteral: 3000)
        }
        
        var checkState: Int = 0
        if noMidCheckButton.imageView?.image == UIImage(named: "RadioButton-On") {
            checkState = 1
        }
        variables[BIFilterRuleNoMidCheckStateVariablesKey] = checkState
        lineSort.variables = variables
        try? self.context?.save()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextfield = textField;
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if (activeTextfield != nil) {
            let _ = self.textFieldShouldReturn(textField)
            activeTextfield = nil
        }
        updateSortVariableswithInputData()
        NotificationCenter.default.post(name: NSNotification.Name("ReloadFilterTable"), object: self)
    }
}
