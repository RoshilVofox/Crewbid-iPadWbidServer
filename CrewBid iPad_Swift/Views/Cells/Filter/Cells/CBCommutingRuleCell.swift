//
//  CBCommutingRuleCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit
import CoreData

class CBCommutingRuleCell: UITableViewCell, CommutingManualRuleCellDelegate, GRButtonDelegate, UITextFieldDelegate {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var saveDefaultsButton: UIButton!
    @IBOutlet weak var loadDefaultsButton: UIButton!
    @IBOutlet weak var calculateButton: UIButton!
    @IBOutlet weak var monThursLabel: UILabel!
    @IBOutlet weak var friLabel: UILabel!
    @IBOutlet weak var satLabel: UILabel!
    @IBOutlet weak var sunLabel: UILabel!
    @IBOutlet weak var timeFormatLabel: UILabel!
    @IBOutlet weak var departureMonThurs: UITextField!
    @IBOutlet weak var departureFri: UITextField!
    @IBOutlet weak var departureSat: UITextField!
    @IBOutlet weak var departureSun: UITextField!
    @IBOutlet weak var returnMonThurs: UITextField!
    @IBOutlet weak var returnFri: UITextField!
    @IBOutlet weak var returnSat: UITextField!
    @IBOutlet weak var returnSun: UITextField!
    @IBOutlet weak var btnCheckNoMid: UIButton!
    @IBOutlet weak var noMidCheckButton: UIButton!
    @IBOutlet weak var eDepLabel: UILabel!
    @IBOutlet weak var lArrLabel: UILabel!
    
    var bidPeriod: BIBidPeriod?
    var filterRule: BIFilterRule?
    var objCommutability: Commutability?
    var activeTextfield: UITextField?
    var internationalCityMinutes = 75
    var cityMinutes = 60
    var isNoMidCkecked = false
    var valueaArray = [Int]()
    var commutability: CBCommutability?
    var depTime = 0
    var arrTime = 0
    var context = CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.text = "Commuting"
        let variables = filterRule?.variables
        let isChecked = (variables?[BIFilterRuleNoMidCheckStateVariablesKey] as? NSNumber ?? 0).boolValue
        noMidCheckButton.isSelected = isChecked
        //noMidCheckButton.Delegate = self
        if isChecked {
            noMidCheckButton.setImage(UIImage(named: "RadioButton-On"), for: .normal)
        } else {
            noMidCheckButton.setImage(UIImage(named: "radioButton-Off"), for: .normal)
        }
        
        if var time = variables![BIFilterRuleMonThursDepartTimeVariablesKey] as? Int {
            // var time: Int = timeInt
            if time > -1 && time > 0 {
                departureMonThurs.text = String(format: "%04zd", time)
            }
            time = variables![BIFilterRuleMonThursReturnTimeVariablesKey] as? Int ?? 0
            if time < 3000 && time > 0 {
                returnMonThurs.text = String(format: "%04zd", time)
            }
            time = variables![BIFilterRuleFriDepartTimeVariablesKey] as? Int ?? 0
            if time > -1 && time > 0 {
                departureFri.text = String(format: "%04zd", time)
            }
            time = variables![BIFilterRuleFriReturnTimeVariablesKey] as? Int ?? 0
            if time < 3000 && time > 0 {
                returnFri.text = String(format: "%04zd", time)
            }
            time = variables![BIFilterRuleSatDepartTimeVariablesKey] as? Int ?? 0
            if time > -1 && time > 0 {
                departureSat.text = String(format: "%04zd", time)
            }
            time = variables![BIFilterRuleSatReturnTimeVariablesKey] as? Int ?? 0
            if time < 3000 && time > 0 {
                returnSat.text = String(format: "%04zd", time)
            }
            time = variables![BIFilterRuleSunDepartTimeVariablesKey] as? Int ?? 0
            if time > -1 && time > 0 {
                departureSun.text = String(format: "%04zd", time)
            }
            time = variables![BIFilterRuleSunReturnTimeVariablesKey] as? Int ?? 0
            if time < 3000 && time > 0 {
                returnSun.text = String(format: "%04zd", time)
            }
        } else {
            var time = Int(variables![BIFilterRuleMonThursDepartTimeVariablesKey] as? String ?? "0") ?? 0
            if time > -1  && time > 0{
                departureMonThurs.text = String(format: "%04zd", time)
            }
            time = Int(variables![BIFilterRuleMonThursReturnTimeVariablesKey] as? String ?? "0") ?? 0
            if time < 3000  && time > 0{
                returnMonThurs.text = String(format: "%04zd", time)
            }
            time = Int(variables![BIFilterRuleFriDepartTimeVariablesKey] as? String ?? "0") ?? 0
            if time > -1  && time > 0{
                departureFri.text = String(format: "%04zd", time)
            }
            time = Int(variables![BIFilterRuleFriReturnTimeVariablesKey] as? String ?? "0") ?? 0
            if time < 3000 && time > 0 {
                returnFri.text = String(format: "%04zd", time)
            }
            time = Int(variables![BIFilterRuleSatDepartTimeVariablesKey] as? String ?? "0") ?? 0
            if time > -1  && time > 0{
                departureSat.text = String(format: "%04zd", time)
            }
            time = Int(variables![BIFilterRuleSatReturnTimeVariablesKey] as? String ?? "0") ?? 0
            if time < 3000  && time > 0{
                returnSat.text = String(format: "%04zd", time)
            }
            time = Int(variables![BIFilterRuleSunDepartTimeVariablesKey] as? String ?? "0") ?? 0
            if time > -1  && time > 0{
                departureSun.text = String(format: "%04zd", time)
            }
            time = Int(variables![BIFilterRuleSunReturnTimeVariablesKey] as? String ?? "0") ?? 0
            if time < 3000  && time > 0{
                returnSun.text = String(format: "%04zd", time)
            }
        }
        saveDefaultsButton.layer.cornerRadius = 6.0
        saveDefaultsButton.layer.borderWidth = 3.0
        saveDefaultsButton.layer.borderColor = CBColor.purpleColor.cgColor
        let defaultCommuteTimes = UserDefaults.standard.value(forKey: kCBDefaultCommutingTimesKey) as? [Any]
        loadDefaultsButton.layer.borderColor = defaultCommuteTimes != nil ? CBColor.purpleColor.cgColor : UIColor.gray.cgColor
        loadDefaultsButton.alpha = defaultCommuteTimes != nil ? 1.0 : 0.7
        loadDefaultsButton.titleLabel?.alpha = defaultCommuteTimes != nil ? 1.0 : 0.7
        calculateButton.isSelected = true
        saveDefaultsButton.isSelected = true
        loadDefaultsButton.isSelected = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func setupUI() {
        departureMonThurs.delegate = self
        departureFri.delegate = self
        departureSat.delegate = self
        departureSun.delegate = self
        returnMonThurs.delegate = self
        returnFri.delegate = self
        returnSat.delegate = self
        returnSun.delegate = self
        
        bidPeriod = CBGlobalMethods.shared.selectedBidPeriod!
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
        
        let defaultCommuteTimes = UserDefaults.standard.value(forKey: kCBDefaultCommutingTimesKey) as? [Any]
        
        loadDefaultsButton.layer.borderColor = defaultCommuteTimes != nil ? CBColor.purpleColor.cgColor : UIColor.gray.cgColor
        loadDefaultsButton.alpha = defaultCommuteTimes != nil ? 1.0 : 0.7
        loadDefaultsButton.titleLabel?.alpha = defaultCommuteTimes != nil ? 1.0 : 0.7
    }
    
    func didChangeState(state: Bool) {
        let variables = NSMutableDictionary(dictionary: self.filterRule!.variables!)
        if noMidCheckButton.isSelected {
            isNoMidCkecked = true
        }
        else {
            isNoMidCkecked = false
        }
        variables.setObject(isNoMidCkecked, forKey: BISortNoMidCheckStateVariablesKey as NSCopying)
        self.filterRule!.variables = variables as NSDictionary
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: nil)
    }
    
    func valueBtnAction(_ value: Int) {
        objCommutability?.value = value as NSNumber
        try? self.context.save()
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: nil)
    }
    
    @IBAction func saveCurrentValuesAsDefault(_ sender: Any) {
        saveDefaultsButton.isSelected = true
        calculateButton.isSelected = true
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
        UserDefaults.standard.set(defaultTimes, forKey: "kCBDefaultCommutingTimesKey")
        UserDefaults.standard.set(self.noMidCheckButton.isSelected, forKey: "NoMidCheckStateCommute")
        setNeedsLayout()
        AlertService.showAlertForTopVC(title: "Commuting Defaults Saved!", message: "")
    }
    
    @IBAction func loadDefaults(_ sender: Any) {
        loadDefaults()
    }
    
    func loadDefaults() {
        var defaultCommuteTimes = NSArray()
        if UserDefaults.standard.value(forKey: kCBDefaultCommutingTimesKey) != nil {
            defaultCommuteTimes = UserDefaults.standard.value(forKey: kCBDefaultCommutingTimesKey) as! NSArray
        }
        let state: Bool = UserDefaults.standard.bool(forKey: "NoMidCheckStateCommute")
        self.noMidCheckButton.isSelected = state
        calculateButton.isSelected = true
        saveDefaultsButton.isSelected = true
        loadDefaultsButton.isSelected = true
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
            let satRet = (defaultCommuteTimes[5] as! NSNumber).intValue
            let sunDept = (defaultCommuteTimes[6] as! NSNumber).intValue
            let sunRet = (defaultCommuteTimes[7] as! NSNumber).intValue
            
            if monThursDept > -1 {
                departureMonThurs.text = String(format: "&04d", monThursDept)
            }
            else {
                departureMonThurs.text = nil
            }
            if monThursRet > 3000 {
                returnMonThurs.text = String(format: "&04d", monThursRet)
            }
            else {
                returnMonThurs.text = nil
            }
            if friDept > -1 {
                departureFri.text = String(format: "&04d", friDept)
            }
            else {
                departureFri.text = nil
            }
            if friRet > 3000 {
                returnFri.text = String(format: "&04d", friRet)
            }
            else {
                returnFri.text = nil
            }
            if satDept > -1 {
                departureSat.text = String(format: "&04d", satDept)
            }
            else {
                departureSat.text = nil
            }
            if satRet > 3000 {
                returnSat.text = String(format: "&04d", satRet)
            }
            else {
                returnSat.text = nil
            }
            if sunDept > -1 {
                departureSun.text = String(format: "&04d", sunDept)
            }
            else {
                departureSun.text = nil
            }
            if sunRet > 3000 {
                returnSun.text = String(format: "&04d", sunRet)
            }
            else {
                returnSun.text = nil
            }
        }
        else {
            AlertService.showAlertForTopVC(title: "No saved defaults exist.", message: "")
        }
    }
    
    @IBAction func calculateCommutingSort(_ sender: Any) {
        self.updateFilterVariablessitchInputData()
        calculateButton.isSelected = true
        saveDefaultsButton.isSelected = true
        loadDefaultsButton.isSelected = true
        
        if (activeTextfield != nil) {
            let _ = textFieldShouldReturn(activeTextfield!)
        }
        let variables = NSMutableDictionary(dictionary: filterRule!.variables!)
        CBGlobalMethods.shared.showCustomActivityIndicator(message: "Calculating", bgcolor: .purple, height: 100)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
            self.calculateFilter(variables)
            CBGlobalMethods.shared.hideCustomActivityIndicator()
        }
    }
    
    func calculateFilter(_ variables: NSDictionary) {
        let resultsSort = (CBGlobalMethods.shared.selectedBidPeriod!.lineSorts!.allObjects as NSArray).filtered(using: NSPredicate(format: "category ==4")) as! [BILineSort]
        if resultsSort.count > 0 {
            let sort = resultsSort[0]
            var sortVrs = sort.variables! as! [String : Any]
            sortVrs["MON_THURS_RETURN"] = variables["MON_THURS_RETURN"] as! Int
            sortVrs["MON_THURS_DEPART"] = variables["MON_THURS_DEPART"] as! Int
            sortVrs["SAT_DEPART"] = variables["SAT_DEPART"] as! Int
            sortVrs["SAT_RETURN"] = variables["SAT_RETURN"] as! Int
            sortVrs["FRI_DEPART"] = variables["FRI_DEPART"] as! Int
            sortVrs["FRI_RETURN"] = variables["FRI_RETURN"] as! Int
            sortVrs["SUN_DEPART"] = variables["SUN_DEPART"] as! Int
            sortVrs["SUN_RETURN"] = variables["SUN_RETURN"] as! Int
            sortVrs["NoMidCheckState"] = (variables["NoMidCheckState"] as! NSNumber).boolValue
            sort.variables = sortVrs as NSDictionary
            try? self.context.save()
        }
        
        self.filterRule?.variables = variables
        if self.setCommuteTimeForDays() {
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
                obj.calculateCommuteLinePropertiesForWorkblock(withDepartureMonThursText: depMonThurs, departureFriText: depFriday, departureSatText: depSat, departureSunText: depSun, returnMonThursText: returnMonThurs, returnSunText: returnSun, returnSatText: returnSat, returnFriText: returnFriday, bidPeriod: self.bidPeriod!)
            }
            else {
                obj.calculateCommuteLinePropertiesForManualTrips(withDepartureMonThursText: depMonThurs, departureFriText: depFriday, departureSatText: depSat, departureSunText: depSun, returnMonThursText: returnMonThurs, returnSunText: returnSun, returnSatText: returnSat, returnFriText: returnFriday, bidPeriod: self.bidPeriod!)
            }
        }
        NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
    }
    
    func updateFilterVariablessitchInputData() {
        let variables = NSMutableDictionary(dictionary: filterRule!.variables!)
        
//        mon - thurs
        if (departureMonThurs.text?.length)! > 0 {
            let time: Int = Int(departureMonThurs.text!)!
            variables[BIFilterRuleMonThursDepartTimeVariablesKey] = time
        }
        else {
            variables[BIFilterRuleMonThursDepartTimeVariablesKey] = -1
        }
        if (returnMonThurs.text?.length)! > 0 {
            let time: Int = Int(returnMonThurs.text!)!
            variables[BIFilterRuleMonThursReturnTimeVariablesKey] = time
        }
        else {
            variables[BIFilterRuleMonThursReturnTimeVariablesKey] = 3000
        }
//        friday
        if (departureFri.text?.length)! > 0 {
            let time: Int = Int(departureFri.text!)!
            variables[BIFilterRuleFriDepartTimeVariablesKey] = time
        }
        else {
            variables[BIFilterRuleFriDepartTimeVariablesKey] = -1
        }
        if (returnFri.text?.length)! > 0 {
            let time: Int = Int(returnFri.text!)!
            variables[BIFilterRuleFriReturnTimeVariablesKey] = time
        }
        else {
            variables[BIFilterRuleFriReturnTimeVariablesKey] = 3000
        }
//        saturday
        if (departureSat.text?.length)! > 0 {
            let time: Int = Int(departureSat.text!)!
            variables[BIFilterRuleSatDepartTimeVariablesKey] = time
        }
        else {
            variables[BIFilterRuleSatDepartTimeVariablesKey] = -1
        }
        if (returnSat.text?.length)! > 0 {
            let time: Int = Int(returnSat.text!)!
            variables[BIFilterRuleSatReturnTimeVariablesKey] = time
        }
        else {
            variables[BIFilterRuleSatReturnTimeVariablesKey] = 3000
        }
//        sunday
        if (departureSun.text?.length)! > 0 {
            let time: Int = Int(departureSun.text!)!
            variables[BIFilterRuleSunDepartTimeVariablesKey] = time
        }
        else {
            variables[BIFilterRuleSunDepartTimeVariablesKey] = -1
        }
        if (returnSun.text?.length)! > 0 {
            let time: Int = Int(returnSun.text!)!
            variables[BIFilterRuleSunReturnTimeVariablesKey] = time
        }
        else {
            variables[BIFilterRuleSunReturnTimeVariablesKey] = 3000
        }
        
        let checkState = noMidCheckButton.isSelected.intValue
        variables[BIFilterRuleNoMidCheckStateVariablesKey] = checkState
        self.filterRule?.variables = variables
        try? self.context.save()
    }
    
    func setCommuteTimeForDays() -> Bool {
        let result = CBGlobalMethods.shared.selectedBidPeriod!.commuteTime?.allObjects
        for basket in result! {
            self.context.delete(basket as! NSManagedObject)
        }
        let startDate = self.startOfMonth()
        let dateFormat = DateFormatter()
        var endDate = self.endOfMonth()
        let daysToAdd = 4
        endDate = endDate?.addingTimeInterval(TimeInterval(60 * 60 * 24 * daysToAdd))
        let minDateString = "01/01/0001 00:00:00"
        
        dateFormat.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormat.locale = Locale.current
        dateFormat.dateFormat = "MM/dd/yyyy hh:mm:ss"
        
        let minDate = dateFormat.date(from: minDateString)
        var oneWeek = DateComponents()
        oneWeek.day = 1
        oneWeek.hour = 1
        //
        var tempStartDate = startDate
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        
        let dateFormatterForDayname = DateFormatter()
        dateFormatterForDayname.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatterForDayname.dateFormat = "EEEE"
        
        while tempStartDate?.compare(endDate!) == .orderedAscending || tempStartDate?.compare(endDate!) == .orderedSame {
            //Set WorkBlock Details
            let commuteEntity = NSEntityDescription.entity(forEntityName: "CommuteTime", in: (bidPeriod?.managedObjectContext)!)
            var objcommuteTime: CommuteTime? = nil
            objcommuteTime = CommuteTime(entity: commuteEntity!, insertInto: context)
            objcommuteTime?.commutable = bidPeriod
            let date = formatter.string(from: tempStartDate!)
            objcommuteTime?.bidDay = tempStartDate as NSDate? as Date?
            objcommuteTime?.bidDayStringValue = date
            objcommuteTime?.earliestArrivel = minDate as Date?
            objcommuteTime?.latestDeparture = minDate as Date?
            let dayName = dateFormatterForDayname.string(from: tempStartDate!)
            
            let variables = self.filterRule!.variables! as NSDictionary
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
            
//            mon - thurs
            if depMonThurs1.length > 0 {
                if dayName == "Monday" || dayName == "Tuesday" || dayName == "Wednesday" || dayName == "Thursday" {
                    objcommuteTime?.earliestArrivel = addminutesWithDates(CurrentDate: tempStartDate!, Minutes: depMonThurs1)
                }
            }
            if returnMonThurs1.length > 0 {
                if dayName == "Monday" || dayName == "Tuesday" || dayName == "Wednesday" || dayName == "Thursday" {
                    objcommuteTime?.latestDeparture = addminutesWithDates(CurrentDate: tempStartDate!, Minutes: returnMonThurs1)
                }
            }
//            friday
            if depFriday1.length > 0 {
                if dayName == "Friday" {
                    objcommuteTime?.earliestArrivel = addminutesWithDates(CurrentDate: tempStartDate!, Minutes: depFriday1)
                }
            }
            if returnFriday1.length > 0 {
                if dayName == "Friday" {
                    objcommuteTime?.latestDeparture = addminutesWithDates(CurrentDate: tempStartDate!, Minutes: returnFriday1)
                }
            }
//            saturday
            if depSat1.length > 0 {
                if dayName == "Saturday" {
                    objcommuteTime?.earliestArrivel = addminutesWithDates(CurrentDate: tempStartDate!, Minutes: depSat1)
                }
            }
            if returnSat1.length > 0 {
                if dayName == "Saturday" {
                    objcommuteTime?.latestDeparture = addminutesWithDates(CurrentDate: tempStartDate!, Minutes: returnSat1)
                }
            }
//            sunday
            if depSun1.length > 0 {
                if dayName == "Sunday" {
                    objcommuteTime?.earliestArrivel = addminutesWithDates(CurrentDate: tempStartDate!, Minutes: depSun1)
                }
            }
            if returnSun1.length > 0 {
                if dayName == "Sunday" {
                    objcommuteTime?.latestDeparture = addminutesWithDates(CurrentDate: tempStartDate!, Minutes: returnSun1)
                }
            }
            objcommuteTime?.type = 0
            let tempdate = Calendar.current.date(byAdding: oneWeek, to: tempStartDate!)
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone(secondsFromGMT: 0)!
            var comps: DateComponents = cal.dateComponents([.year, .month, .day], from: tempdate!)
            comps.hour = 0
            comps.minute = 0
            comps.second = 0
            tempStartDate = cal.date(from: comps)!
            
            if tempStartDate!.compare(endDate!) == .orderedSame {
                try? self.context.save()
                return true
            }
        }
        try? self.context.save()
        return false
    }
    
    func startOfMonth() -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        if let aName = TimeZone(secondsFromGMT: 0) {
            calendar.timeZone = aName as TimeZone
        }
        var day: NSNumber?
        var month: NSNumber?
        var year: NSNumber?
        var components = DateComponents()
        if (bidPeriod?.isFABid() == true) && (bidPeriod?.month?.intValue == 2) {
            
            day = 31
            month = 1
            year = bidPeriod?.year
        } else if (bidPeriod!.isFABid() == true) && (bidPeriod?.month?.intValue == 3) {
            day = 2
            month = bidPeriod?.month
            year = bidPeriod?.year
        } else {
            day = 1
            month = bidPeriod?.month
            year = bidPeriod?.year
        }
        components.day = Int(truncating: day ?? 0)
        components.month = Int(truncating: month ?? 0)
        components.year = Int(truncating: year ?? 0)
        components.minute = 0
        components.hour = 0
        components.second = 0
        
        return calendar.date(from: components)
    }
    
    func endOfMonth() -> Date? {
        var daysToAdd: Int = 1
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        if let aName = TimeZone(secondsFromGMT: 0) {
            calendar.timeZone = aName as TimeZone
        }
        var components = DateComponents()
        let day = 1
        let month = bidPeriod?.month
        let year = bidPeriod?.year
        components.day = day
        components.month = month as? Int
        components.year = year as? Int
        components.minute = 0
        components.hour = 0
        components.second = 0
        
        
        var dateComponents = DateComponents()
        dateComponents.month = 1
        dateComponents.day = -1
        
        var lastDayOfMonth: Date? = nil
        lastDayOfMonth = calendar.date(byAdding: dateComponents, to: calendar.date(from: components)!)
        
        //in case of februaury month for FA the last date should be march 1.
        if (bidPeriod!.isFABid() == true) && bidPeriod?.month == 2 {
            
            lastDayOfMonth = lastDayOfMonth?.addingTimeInterval(TimeInterval(60 * 60 * 24 * daysToAdd))
            return lastDayOfMonth
        } else if (bidPeriod!.isFABid() == true) && bidPeriod?.month?.intValue == 1 {
            daysToAdd = -1
            lastDayOfMonth = lastDayOfMonth?.addingTimeInterval(TimeInterval(daysToAdd * 24 * 60 * 60))
            return lastDayOfMonth
        }
        else {
            return lastDayOfMonth
        }
    }
    
    func getCompleteTime(timeString: String) -> String {
        if timeString == "-1" || timeString == "3000"{
            return ""
        }
        var timeStr = timeString
        while timeStr.length < 4 {
            timeStr = "0\(timeStr)"
        }
        return timeStr
    }
    
    func addminutesWithDates(CurrentDate: Date, Minutes mns: String) -> Date {
        var temp = ""
        if mns.count == 4 {
            temp = mns
        } else if mns.count == 3 {
            temp = "0" + mns
        }else if mns.count == 2 {
            temp = "00" + mns
        }else if mns.count == 1 {
            temp = "000" + mns
        }else{
            temp = "0000"
        }
        var hours = Int(temp.substring(to: 2))!
        let mins = Int(temp.substring(with: 2..<2))!
        hours = (hours * 60) + mins;
        let ModifiedDate = CurrentDate.addingTimeInterval(TimeInterval(hours * 60))
        return ModifiedDate
    }
    
    @IBAction func btnCheckNoMidAction(_ sender: Any) {
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let refreshViewController = storyboard.instantiateViewController(withIdentifier: "RefreshController") as! RefreshController
        refreshViewController.popOverType = PopoverViewType.CommutingManualNoMidInfo
        refreshViewController.selectedValue =  (sender as! UIButton).currentTitle ?? ""
        refreshViewController.modalPresentationStyle = .popover
        refreshViewController.showPopover(sourceView: btnCheckNoMid,isMidOn: true)
    }
    
    func addDoneButtonOnKeyboard()  {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.barStyle = UIBarStyle.blackTranslucent
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: self, action: #selector(CBCommutingRuleCell.doneButtonAction))
        
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        self.activeTextfield?.inputAccessoryView = doneToolbar
        
    }
    
    @IBAction func btnNoMidActionSelection(sender: UIButton) {
        noMidCheckButton.isSelected = !noMidCheckButton.isSelected
        let variables = NSMutableDictionary(dictionary:(filterRule!.variables)!)
        if noMidCheckButton.isSelected == true {
            sender.setImage(UIImage(named: "RadioButton-On"), for: .normal)
        } else {
            sender.setImage(UIImage(named: "radioButton-Off"), for: .normal)
            noMidCheckButton.isSelected = false
        }
        variables[BIFilterRuleNoMidCheckStateVariablesKey] = noMidCheckButton.isSelected
        self.filterRule?.variables = variables
    }
    
    @objc func doneButtonAction()
    {
        self.activeTextfield?.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField.text?.count ?? 0) != 0 {
            // Check to make sure the user didn't enter in a value greater than 60 for the minutes
            // or greater than 28 for the hours
            var minVal: Int = 0
            let timeVal = Int(textField.text ?? "") ?? 0
            let hundred: Int = timeVal / 100
            minVal = timeVal - (hundred * 100)
            if minVal > 59 || hundred > 28 {
                AlertService.showAlertForTopVC(title: "Invalid input.", message: "Please input 28 or less for the hours and 59 for less for the minutes.")
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
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextfield = textField
        self.addDoneButtonOnKeyboard()
    }
    
    func updateFilterVariableswithInputData(){
        let variables = NSMutableDictionary(dictionary:(filterRule!.variables)!)
        
        if (departureMonThurs.text?.length)! > 0  {
            let time: Int = Int(departureMonThurs.text!)!
            variables[BIFilterRuleMonThursDepartTimeVariablesKey] = time
        } else {
            variables[BIFilterRuleMonThursDepartTimeVariablesKey] = -1
        }
        if returnMonThurs.text!.length > 0 {
            let time: Int = Int(returnMonThurs.text!)!
            variables[BIFilterRuleMonThursReturnTimeVariablesKey] = time
        } else {
            variables[BIFilterRuleMonThursReturnTimeVariablesKey] = 3000
        }
        // Fri
        if departureFri.text!.length > 0 {
            let time: Int = Int(departureFri.text!)!
            variables[BIFilterRuleFriDepartTimeVariablesKey] = time
        } else {
            variables[BIFilterRuleFriDepartTimeVariablesKey] = -1
        }
        if returnFri.text!.length > 0 {
            let time: Int = Int(returnFri.text!)!
            variables[BIFilterRuleFriReturnTimeVariablesKey] = time
        } else {
            variables[BIFilterRuleFriReturnTimeVariablesKey] = 3000
        }
        
        // Sat
        if departureSat.text!.length > 0 {
            let time: Int = Int(departureSat.text!)!
            variables[BIFilterRuleSatDepartTimeVariablesKey] = time
        } else {
            variables[BIFilterRuleSatDepartTimeVariablesKey] = -1
        }
        if returnSat.text!.length > 0 {
            let time: Int = Int(returnSat.text!)!
            variables[BIFilterRuleSatReturnTimeVariablesKey] = time
        } else {
            variables[BIFilterRuleSatReturnTimeVariablesKey] = 3000
        }
        
        // Sun
        if departureSun.text!.length > 0 {
            let time: Int = Int(departureSun.text!)!
            variables[BIFilterRuleSunDepartTimeVariablesKey] = time
        } else {
            variables[BIFilterRuleSunDepartTimeVariablesKey] = -1
        }
        if returnSun.text!.length > 0 {
            let time: Int = Int(returnSun.text!)!
            variables[BIFilterRuleSunReturnTimeVariablesKey] = time
        } else {
            variables[BIFilterRuleSunReturnTimeVariablesKey] = 3000
        }
        
        let checksate = noMidCheckButton.isSelected.intValue
        variables[BIFilterRuleNoMidCheckStateVariablesKey] = checksate
        self.filterRule?.variables = variables
        try? self.context.save()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if (activeTextfield != nil) {
            activeTextfield = nil
            let _ = textFieldShouldReturn(textField)
        }
        
        self.updateFilterVariableswithInputData()
        
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
    
    func calculateCommutingManualFilter() {
        let resultsSort = (CBGlobalMethods.shared.selectedBidPeriod!.lineSorts!.allObjects as NSArray).filtered(using: NSPredicate(format: "category == 4")) as! [BILineSort]
        
        if (resultsSort.count > 0) {
            let rule = resultsSort[0]
            var variables = NSDictionary(dictionary: rule.variables!) as! [String: Any]
            // Mon-Thurs
            var time = variables[BISortMonThursDepartTimeVariablesKey] as? Int ?? 0
            if time > -1  && time != 0{
                departureMonThurs.text = String(format: "%04zd", time)
                variables[BIFilterRuleMonThursDepartTimeVariablesKey] = NSNumber(integerLiteral: time)
            } else {
                variables[BIFilterRuleMonThursDepartTimeVariablesKey] = NSNumber(integerLiteral: -1)
            }
            time = variables[BISortMonThursReturnTimeVariablesKey] as? Int ?? 0
            if time < 3000  && time != 0{
                returnMonThurs.text = String(format: "%04zd", time)
                variables[BIFilterRuleMonThursReturnTimeVariablesKey] = NSNumber(integerLiteral: time)
            } else {
                variables[BIFilterRuleMonThursReturnTimeVariablesKey] = NSNumber(integerLiteral: 3000)
            }
            
            // Fri
            time = variables[BISortFriDepartTimeVariablesKey] as? Int ?? 0
            if time > -1  && time != 0{
                departureFri.text = String(format: "%04zd", time)
                variables[BIFilterRuleFriDepartTimeVariablesKey] = NSNumber(integerLiteral: time)
            } else {
                variables[BIFilterRuleFriDepartTimeVariablesKey] = NSNumber(integerLiteral: -1)
            }
            time = variables[BISortFriReturnTimeVariablesKey] as? Int ?? 0
            if time < 3000  && time != 0{
                returnFri.text = String(format: "%04zd", time)
                variables[BISortFriReturnTimeVariablesKey] = NSNumber(integerLiteral: time)
            } else {
                variables[BISortFriReturnTimeVariablesKey] = NSNumber(integerLiteral: 3000)
            }
            
            
            // Sat
            time = variables[BISortSatDepartTimeVariablesKey] as? Int ?? 0
            if time > -1 && time != 0{
                departureSat.text = String(format: "%04zd", time)
                variables[BIFilterRuleSatDepartTimeVariablesKey] = NSNumber(integerLiteral: time)
            } else {
                variables[BIFilterRuleSatDepartTimeVariablesKey] = NSNumber(integerLiteral: -1)
            }
            time = variables[BISortSatReturnTimeVariablesKey] as? Int ?? 0
            if time < 3000 && time != 0 {
                returnSat.text = String(format: "%04zd", time)
                variables[BISortSatReturnTimeVariablesKey] = NSNumber(integerLiteral: time)
            } else {
                variables[BISortSatReturnTimeVariablesKey] = NSNumber(integerLiteral: 3000)
            }
            
            // Sun
            time = variables[BISortSunDepartTimeVariablesKey] as? Int ?? 0
            if time > -1 && time != 0 {
                departureSun.text = String(format: "%04zd", time)
                variables[BIFilterRuleSunDepartTimeVariablesKey] = NSNumber(integerLiteral: time)
            } else {
                variables[BIFilterRuleSunDepartTimeVariablesKey] = NSNumber(integerLiteral: -1)
            }
            time = variables[BISortSunReturnTimeVariablesKey] as? Int ?? 0
            if time < 3000  && time != 0{
                returnSun.text = String(format: "%04zd", time)
                variables[BISortSunReturnTimeVariablesKey] = NSNumber(integerLiteral: time)
            } else {
                variables[BISortSunReturnTimeVariablesKey] = NSNumber(integerLiteral: 3000)
            }
            
            filterRule?.variables = variables as NSDictionary
            
            do {
                try self.context.save()
            } catch {
                print(error.localizedDescription)
            }
        }
        
    }
    
    
    // Only allow numeric input
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        // return true if the replacementString only contains numeric characters
        let aSet = NSCharacterSet(charactersIn:"0123456789").inverted
        let compSepByCharInSet = string.components(separatedBy: aSet)
        let numberFiltered = compSepByCharInSet.joined(separator: "")
        return string == numberFiltered
    }
    
    @IBAction func deleteCellRow(_ sender: Any) {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        // MARK: FIX THIS
        if (filterRule?.ruleHighlightsTrips())! {
            filterRule?.deHighlightTrips()
        }
        // Set all text fields to nil
        departureMonThurs.text = nil
        returnMonThurs.text = nil
        departureFri.text = nil
        returnFri.text = nil
        departureSat.text = nil
        returnSat.text = nil
        departureSun.text = nil
        returnSun.text = nil

        for line in  CBGlobalMethods.shared.selectedBidPeriod!.orderedLines(){
            line.totalCommutes = NSNumber(integerLiteral: 0)
            line.commutableBacks = NSNumber(integerLiteral: 0)
            line.commutableFronts = NSNumber(integerLiteral: 0)
            line.commutabilityFront = NSNumber(integerLiteral: 0)
            line.commutabilityBack = NSNumber(integerLiteral: 0)
            line.commutabilityOverall = NSNumber(integerLiteral: 0)
            for trip in line.orderedTripObjects() {
                trip.info?.isFullyCommutable = NSNumber(booleanLiteral: false)
                trip.highlightCount = NSNumber(integerLiteral: 0)
            }
        }
        
        let result = CBGlobalMethods.shared.selectedBidPeriod!.commuteTime?.allObjects
        for basket in result! {
            self.context.delete(basket as! NSManagedObject)
        }
        try? self.context.save()
        // Remove the filtering by commute times
        filterRule?.managedObjectContext?.delete(filterRule!)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }
    }
}
