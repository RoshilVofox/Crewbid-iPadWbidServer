//
//  CBLineValuesMenuController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 16/04/25.
//

import UIKit

var CBLineValuesToDisplayDidChangeNotification = "CBLineValuesToDisplayDidChangeNotification"

class CBLineValuesMenuController: BaseViewController,UITableViewDelegate,UITableViewDataSource,KUIPopOverUsable {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var resetButton: UIButton!
    var lineValuesTemp:NSArray!
    
    var selectedValuesCount: Int = 0
    var lineValues = [Any]()
    weak var bidPeriod: BIBidPeriod?
    var menuItems = [Any]()
    

    
    var contentSize: CGSize {
        return CGSize(width: 310.0, height: UIScreen.main.bounds.height - 120)
    }

    var arrowDirection: UIPopoverArrowDirection {
        return .left
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.separatorStyle = .singleLine
        self.tableView.allowsMultipleSelection = true
        lineValues = lineValues1()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lineValues.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let lineValuesKey = CBLineValuesMenuController.lineValuesKey(for: bidPeriod!)
        let linevaluesToDisplay = NSMutableArray()
        if UserDefaults.standard.object(forKey: lineValuesKey) != nil {
            let arr = UserDefaults.standard.value(forKey: lineValuesKey) as! [Any]
            linevaluesToDisplay.addObjects(from: arr)
        }
        let value = lineValues[indexPath.row] as! NSDictionary
        if linevaluesToDisplay.count > 0 {
            let type = value.value(forKey: "type") as! NSNumber
            if linevaluesToDisplay.contains(type) {
                cell.setSelected(true, animated: true)
            }else{
                cell.setSelected(false, animated: false)
            }
        }
        if cell.isSelected{
            cell.accessoryType = .checkmark
            selectedValuesCount += 1
        }else{
            cell.accessoryType = .none
        }
        cell.selectionStyle = .none
        let title = value["name"] as? String
        cell.textLabel?.text = title
        let type = value["type"] as! Int
        if (type > 25 && type < 39) || type == 42 || type == 50 || type == 68 || type == 52 || type == 53 || (type >= 58 && type <= 63) {
            if cellIsHidden(for: value as! [AnyHashable : Any]) {
                cell.isHidden = true
            } else {
                if (bidPeriod?.isFABid())! {
                    let swapImage = UIImage(named: "FA_Vacation_Image_Shadow")
                    let swapImgView = UIImageView(frame: CGRect(x: 215.0, y: 2.0, width: 40.0, height: 40.0))
                    swapImgView.tag = 101
                    swapImgView.image = swapImage
                    cell.contentView.addSubview(swapImgView)
                } else {
                    let swapImage = UIImage(named: SwaptimizerVacationImage)
                    let swapImgView = UIImageView(frame: CGRect(x: 215.0, y: 2.0, width: 40.0, height: 40.0))
                    swapImgView.tag = 101
                    swapImgView.image = swapImage
                    cell.contentView.addSubview(swapImgView)
                }
            }
        }else{
            var viewToRemove: UIView? = cell.contentView.viewWithTag(101)
            while (viewToRemove != nil) {
                viewToRemove?.removeFromSuperview()
                viewToRemove = cell.contentView.viewWithTag(101)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let value = lineValues[indexPath.row] as! NSDictionary
        let typeNum = value.value(forKey: "type") as! NSNumber
        let type = Int(truncating: typeNum)
//        if self.lineValueTypeIsHidden(forPilotSecondRound: CBLineValueTypes(rawValue: type)!){
//            return 0
//        }
        /*else*/ if type > 25 {
            if self.cellIsHidden(for: value as! [AnyHashable : Any]){
                return 0
            }else{
                return tableView.rowHeight
            }
        }else{
            return tableView.rowHeight
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell:UITableViewCell? = tableView.cellForRow(at: indexPath)
        let selectedValue = lineValues[indexPath.row] as! NSDictionary
        let lineValuesKey = CBLineValuesMenuController.lineValuesKey(for: bidPeriod!)
        let lineValuesToDisplay = NSMutableArray()
        if UserDefaults.standard.object(forKey: lineValuesKey) != nil {
            let arr = UserDefaults.standard.value(forKey: lineValuesKey) as! [Any]
            lineValuesToDisplay.addObjects(from: arr)
        }
        if cell?.accessoryType == .checkmark {
            cell?.setSelected(false, animated: false)
            let type = selectedValue.value(forKey: "type") as! NSNumber
            lineValuesToDisplay.remove(type)
            UserDefaults.standard.set(lineValuesToDisplay, forKey: lineValuesKey)
            tableView.reloadData()
        }else if lineValuesToDisplay.count < 5{
            cell?.setSelected(false, animated: false)
            let type = selectedValue.value(forKey: "type") as! NSNumber
            lineValuesToDisplay.add(type)
            UserDefaults.standard.set(lineValuesToDisplay, forKey: lineValuesKey)
            tableView.reloadData()
        }else{
            tableView.deselectRow(at: indexPath, animated: true)
            let alert = UIAlertController(title: "Cannot select more than 5 values.", message: "Please deselect values before adding new ones.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: nil)
    }
    
    @IBAction func resetAction(_ sender: Any) {
        resetStdAction()
    }

    //Adding line to bidlist
    @objc func bidCellLine(_ notification: Notification) {
        //For passing FA line to bidlist we need to show a view for position
        if let buttonView = notification.userInfo![CBLineTableCellButtonViewKey] as? UIView, let lines = notification.userInfo!["Lines"] as? [BILine], let lineNum = notification.userInfo!["LineNum"] as? Int {
            
        }
    }
    
    
    class func setLineValueView(_ lineValueView: CBLineValueView, with line: BILine, forType valueType: CBLineValueTypes, bidPeriod: BIBidPeriod) {
        switch valueType {
            
        case .VOBoth:
            let val = (line.vBackVoPay?.floatValue ?? 0.0) + (line.vFrontVoPay?.floatValue ?? 0.0)
            lineValueView.setValue(value: String(format: "%.2f", val), forTitle: "VoBoth", andType: valueType)
            break
        case .VAbp:
            lineValueView.setValue(value: String(format: "%.2f", line.vAbp!.floatValue), forTitle: "VAbp", andType: valueType)
            break
            
        case .VAne:
            lineValueView.setValue(value: String(format: "%.2f", line.vAne?.floatValue ?? 0), forTitle: "VAne", andType: valueType)
            break
            
        case .VAbo:
            lineValueView.setValue(value: String(format: "%.2f", line.vAbo?.floatValue ?? 0), forTitle: "VAbo", andType: valueType)
            break
            
        case .VAPbp:
            lineValueView.setValue(value: String(format: "%.2f", line.vAPbp?.floatValue ?? 0), forTitle: "VAPbp", andType: valueType)
            break
            
        case .VAPne:
            lineValueView.setValue(value: String(format: "%.2f", line.vAPne?.floatValue ?? 0), forTitle: "VAPne", andType: valueType)
            break
            
        case .VAPbo:
            lineValueView.setValue(value: String(format: "%.2f", line.vAPbo?.floatValue ?? 0) , forTitle: "VAPbo", andType: valueType)
            break
            
        case .AircraftChanges:
            lineValueView.setValue(value: String(format: "%01ld", Int(truncating: line.numAircraftChanges!)), forTitle: "Chngs", andType: valueType)
            break
            
        case .AircraftTypeIs800:
            lineValueView.setValue(value: String(format: "%01ld", Int(truncating: line.aircraftType800Count!)), forTitle: "800s", andType: valueType)
            break
            
        case .AircraftTypeIs700:
            lineValueView.setValue(value: String(format: "%01ld", Int(truncating: line.aircraftType700Count!)), forTitle: "700s", andType: valueType)
            break
            
        case .AircraftTypeIs8Max:
            lineValueView.setValue(value: String(format: "%01ld", Int(truncating: line.aircraftType8MaxCount!)), forTitle: "8Max", andType: valueType)
            break
            
        case .AircraftTypeIs7Max:
            lineValueView.setValue(value: String(format: "%01ld", Int(truncating: line.aircraftType7MaxCount!)), forTitle: "7Max", andType: valueType)
            break
            
        case .BlockDaysOff:
            lineValueView.setValue(value: "\(Int(truncating: line.blockOfDaysOff!))", forTitle: "BlkOff", andType: valueType)
            break
            
        case .BlockTime:
            lineValueView.setValue(value: String(format: "%02zd:%02zd", Int(truncating: (line.blockMinutes!)) / 60, Int(truncating: line.blockMinutes!) % 60), forTitle: "BlkHrs", andType: valueType)
            break
            
        case .WorkBP:
            lineValueView.setValue(value: "\(Int(truncating: line.workDaysBP!))", forTitle: "Work BP", andType: valueType)
            break
            
        case .DaysOff:
            lineValueView.setValue(value: "\(String(describing: line.daysOff!))", forTitle: "DaysOff", andType: valueType)
            break
            
        case .Deadheads:
            lineValueView.setValue(value: "\(String(describing: line.deadheadsCount!))", forTitle: "DHs", andType: valueType)
            break
            
        case .DutyTime:
            lineValueView.setValue(value: String(format: "%01zd:%02zd", Int(truncating: line.dutyMinutes!) / 60, Int(truncating: line.dutyMinutes!) % 60), forTitle: "DtyHrs", andType: valueType)
            break
        case .GTmax:
            lineValueView.setValue(value: String(format: "%01zd:%02zd", Int(truncating: line.gTmax!) / 60, Int(truncating: line.gTmax!) % 60), forTitle: "GTmax", andType: valueType)
            break
        case .GTavg:
            lineValueView.setValue(value: String(format: "%01zd:%02zd", Int(truncating: line.gTavg!) / 60, Int(truncating: line.gTavg!) % 60), forTitle: "GTavg", andType: valueType)
            break
        case .DutyHoursPerDay:
            lineValueView.setValue(value: String(format: "%.2f", Float(truncating: line.dutyHoursPerDay!)), forTitle: "Dty/Day", andType: valueType)
            break
            
        case .NonConUsLegs:
            lineValueView.setValue(value: "\(String(describing: line.nonConusLegsCount!))", forTitle: "NC Legs", andType: valueType)
            break
            
        case .EarliestDept:
            let hours: Int = Int(truncating: line.earliestDepartureTime!) / 100
            let mins: Int = Int(truncating: line.earliestDepartureTime!) - hours * 100
            lineValueView.setValue(value: String(format: "%01zd:%02zd", hours, mins), forTitle: "EDep", andType: valueType)
            let minsTemp = (hours * 60) + mins
            if UserDefaults.standard.integer(forKey: kCBTimeZoneSetting) == CBTimeZoneSetting.localTime.rawValue && line.trips?.allObjects.count != 0 {
                let departFormatter = DateFormatter()
                departFormatter.dateFormat = "HHmm"
                departFormatter.timeZone = CBUtils.timeZone(forAirportCode: line.bidPeriod!.base!)
                
                var calendar = Calendar(identifier: .gregorian)
                calendar.locale = Locale(identifier: "en_US")
                calendar.timeZone = TimeZone(identifier: "US/Central")!
                
                var dateComps = calendar.dateComponents([.year, .month, .day], from: Date())
                dateComps.minute =  minsTemp
                let departDate = calendar.date(from: dateComps)
                let dep1 : Int = Int(departFormatter.string(from: departDate!)) ?? 0
                let hours1: Int = dep1 / 100
                let mins1: Int = dep1 - hours1 * 100
                lineValueView.setValue(value: String(format: "%01zd:%02zd", hours1, mins1), forTitle: "EDep", andType: valueType)
            }
            break
            
        case .LatestArr:
            var latestArrival: Int = line.latestArrivalTime as! Int
            if latestArrival > 2400 {
                latestArrival -= 2400
            }
            let hours: Int = latestArrival / 100
            let mins: Int = latestArrival - hours * 100
            lineValueView.setValue(value: String(format: "%01zd:%02zd", hours, mins), forTitle: "LArr", andType: valueType)
            let minsTemp = (hours * 60) + mins
            if UserDefaults.standard.integer(forKey: kCBTimeZoneSetting) == CBTimeZoneSetting.localTime.rawValue && line.trips?.allObjects.count != 0{
                let arriveFormatter = DateFormatter()
                arriveFormatter.dateFormat = "HHmm"
                arriveFormatter.timeZone = CBUtils.timeZone(forAirportCode: line.bidPeriod!.base!)
                
                var calendar = Calendar(identifier: .gregorian)
                calendar.locale = Locale(identifier: "en_US")
                calendar.timeZone = TimeZone(identifier: "US/Central")!
                
                var dateComps = calendar.dateComponents([.year, .month, .day], from: Date())
                dateComps.minute =  minsTemp
                let arriveDate = calendar.date(from: dateComps)
                let arr1 : Int = Int(arriveFormatter.string(from: arriveDate!)) ?? 0
                let hours1: Int = arr1 / 100
                let mins1: Int = arr1 - hours1 * 100
                lineValueView.setValue(value: String(format: "%01zd:%02zd", hours1, mins1), forTitle: "LArr", andType: valueType)
            }
            break
            
        case .Legs:
            lineValueView.setValue(value: String(format: "%d", line.numLegs!.intValue), forTitle: "Legs", andType: valueType)
            break
            
        case .MaxLegsInDay:
            lineValueView.setValue(value: String(format: "%d", line.maxLegsInADay!.intValue), forTitle: "MLegs", andType: valueType)
            break
            
        case .OvAvg:
            lineValueView.setValue(value: String(format: "%01zd:%02zd", Int(truncating: line.ovAvg ?? 0) / 60, Int(truncating: line.ovAvg ?? 0) % 60), forTitle: "OvAvg", andType: valueType)
            break
            
        case .OvernightsInBase:
            lineValueView.setValue(value: String(format: "%d", line.overnightsInBase!.intValue), forTitle: "OIBs", andType: valueType)
            break
            
        case .PassesThruBase:
            lineValueView.setValue(value: String(format: "%d", line.passesThruBase!.intValue), forTitle: "PTBs", andType: valueType)
            break
            
        case .T234:
            lineValueView.setValue(value: String(format: "%@", line.t234()), forTitle: "T234", andType: valueType)
            break
            
        case .Trips:
            lineValueView.setValue(value: String(format: "%d", line.numTrips!.intValue), forTitle: "Trips", andType: valueType)
            break
            
        case .Pay:
            lineValueView.setValue(value: String(format: "%0.2f", line.pay!.floatValue), forTitle: "Pay", andType: valueType)
            break
            
        case .PayPerBlock:
            lineValueView.setValue(value: String(format: "%0.2f", Float(truncating: line.payPerBlockHour!)), forTitle: "$/Blk", andType: valueType)
            break
            
        case .PayPerLeg:
            lineValueView.setValue(value: String(format: "%0.2f", Float(truncating: line.payPerLeg!)), forTitle: "$/Leg", andType: valueType)
            if line.payPerLeg!.floatValue == Float.infinity {
                lineValueView.setValue(value: "0.00", forTitle: "$/Leg", andType: valueType)
            }
            break
            
        case .PayPerTAFB:
            lineValueView.setValue(value: String(format: "%0.2f", Float(truncating: line.payPerTAFB!)), forTitle: "$/TAFB", andType: valueType)
            if line.payPerTAFB!.floatValue == Float.infinity{
                lineValueView.setValue(value: "0.00", forTitle: "$/TAFB", andType: valueType)
            }
            break
            
        case .TAFB:
            let firstValue: Int = Int(truncating: line.tafbMinutes!) / 60
            let secondValue: Int = Int(truncating: line.tafbMinutes!) % 60
            lineValueView.setValue(value: String(format: "%01zd:%02zd",Int(firstValue) , Int(secondValue)), forTitle: "TAFB", andType: valueType)
            break
            
        case .PayPerDay:
            lineValueView.setValue(value: String(format: "%0.2f", Float(truncating: line.payPerDay!)), forTitle: "$/Day", andType: valueType)
            if line.payPerDay!.floatValue == Float.infinity{
                lineValueView.setValue(value: "0.00", forTitle: "$/Day", andType: valueType)
            }
            break
            
        case .PayPerDutyTime:
            lineValueView.setValue(value: String(format: "%0.2f", Float(truncating: line.payPerDutyTime!)), forTitle: "$/Duty", andType: valueType)
            if line.payPerDutyTime!.floatValue == Float.infinity{
                lineValueView.setValue(value: "0.00", forTitle: "$/Duty", andType: valueType)
            }
            break
            
        case .CarryOutPay:
            lineValueView.setValue(value: String(format: "%0.2f", Float(truncating: line.carryOutPay!)), forTitle: "CoPay", andType: valueType)
            break
            
        case .Weekends:
            lineValueView.setValue(value: "\(String(describing: line.weekendsCount!))", forTitle: "Wknds", andType: valueType)
            break
            
        case .WorkDays:
            lineValueView.setValue(value: "\(String(describing: line.workDays!))", forTitle: "Work All", andType: valueType)
            break
            
        case .VTotalPay:
            lineValueView.setValue(value: String(format: "%0.2f", line.vTotalPay!.floatValue), forTitle: "TotalPay", andType: valueType)
            break
            
        case .VFlyPay:
            lineValueView.setValue(value: String(format: "%0.2f", line.vFlyPay!.floatValue), forTitle: "FlyPay", andType: valueType)
            break
            
        case .VVacayPay:
            lineValueView.setValue(value: String(format: "%0.2f", line.vVacationPay!.floatValue), forTitle: "vpCu", andType: valueType)
            break
            
        case .VCarryOutPay:
            lineValueView.setValue(value: String(format: "%0.1f", line.vCarryOutPay!.floatValue), forTitle: "CoFlyPay", andType: valueType)
            break
            
        case .VBlockTime:
            let blockTime = line.vBlockTime ?? 0
            let hrs : Int = Int(truncating: blockTime)
            let minutesInHrs = Float(truncating: blockTime) - Float(truncating: hrs.asNSNumber)
            let mins = Int((minutesInHrs * 60.0).rounded())
            lineValueView.setValue(value: String(format: "%02zd:%02zd", hrs, mins), forTitle: "BlkHrs", andType: valueType)
            break
            
        case .VDaysOff:
            lineValueView.setValue(value: "\(String(describing: line.vDaysOff!.intValue))", forTitle: "DaysOff", andType: valueType)
            break
            
        case .VLength:
            lineValueView.setValue(value: "\(String(describing: line.vEffectiveVacayLength!.intValue))", forTitle: "EffLength", andType: valueType)
            break
            
        case .LongBlock:
        lineValueView.setValue(value: String(describing: (line.vLongestBlockofDaysOff?.intValue ?? 0)), forTitle: "LonBlkoff", andType: valueType)
            break
            
        case .VPayPerBlock:
            lineValueView.setValue(value: String(format: "%0.2f", line.vPayPerBlock!.floatValue), forTitle: "$/Blk", andType: valueType)
            break
            
        case .VPayPerDay:
            lineValueView.setValue(value: String(format: "%0.2f", line.vPayPerDay!.floatValue), forTitle: "$/Day", andType: valueType)
            break
            
        case .VVacayCarryOutPay:
            lineValueView.setValue(value: String(format: "%0.1f", line.vVacayCarryOutPay!.floatValue), forTitle: "CoVaPay", andType: valueType)
            break
            
        case .VCarryOutVOPay:
            lineValueView.setValue(value: String(format: "%0.1f", line.vCarryOutVOPay!.floatValue), forTitle: "CoVoPay", andType: valueType)
            break
            
        case .VFrontVoPay:
            lineValueView.setValue(value: String(format: "%0.1f", line.vFrontVoPay!.floatValue), forTitle: "FrontVO", andType: valueType)
            break
            
        case .VBackVoPay:
            lineValueView.setValue(value: String(format: "%0.1f", line.vBackVoPay!.floatValue), forTitle: "BackVO", andType: valueType)
            break
            
        case .HolidayRig:
            lineValueView.setValue(value: String(format: "%0.2f", line.holidayPay!.floatValue), forTitle: "HoliRig", andType: valueType)
            break
            
        case .VacationPayDifference:
            let wbidVacPay = Float(truncating: line.vWBVacPay!)
            let swaVacPay = Float(truncating: line.vCBVacPay!)
            var vDiff: Float = 0.0
            if bidPeriod.isSwaptimizerOn == true {
                vDiff = swaVacPay - wbidVacPay
            } else {
                vDiff = wbidVacPay - swaVacPay
            }
            lineValueView.setValue(value: String(format: "%0.2f", vDiff), forTitle: "vDiff", andType: valueType)
            break
            
        case .CommutabilityBacks:
            if line.commutabilityBack == 0 {
                lineValueView.setValue(value: "0", forTitle: "cmt%Ba", andType: valueType)
            }
            else {
                lineValueView.setValue(value: "\(String(format: "%0.2f", line.commutabilityBack!.floatValue))%", forTitle: "cmt%Ba", andType: valueType)
            }
            break
        case .CommutabilityFronts:
            if line.commutabilityFront == 0 {
                lineValueView.setValue(value: "0", forTitle: "cmt%Fr", andType: valueType)
            }
            else {
                lineValueView.setValue(value: "\(String(format: "%0.2f", line.commutabilityFront!.floatValue))%", forTitle: "cmt%Fr", andType: valueType)
            }
            break
            
        case .CommutableBacks:
            lineValueView.setValue(value: "\(String(describing: line.commutableBacks!))", forTitle: "cmtBa", andType: valueType)
            break
            
        case .CommutableFronts:
            if !(line.commutableFronts == nil) {
                lineValueView.setValue(value: "\(String(describing: line.commutableFronts!))", forTitle: "cmtFr", andType: valueType)
            }
            else {
                lineValueView.setValue(value: "0", forTitle: "cmtFr", andType: valueType)
            }
            break
            
        case .NightsInMid:
            lineValueView.setValue(value: "\(String(describing: line.nightsInMid!))", forTitle: "nMid", andType: valueType)
            break
            
        case .TotalCommutes:
            lineValueView.setValue(value: "\(String(describing: line.totalCommutes!))", forTitle: "cmts", andType: valueType)
            break
            
        case .CommutabilityOverall:
            if line.commutabilityOverall == 0 {
                lineValueView.setValue(value: "0", forTitle: "cmt%Ov", andType: valueType)
            }
            else {
                lineValueView.setValue(value: "\(String(format: "%0.2f", line.commutabilityOverall!.floatValue))%", forTitle: "cmt%Ov", andType: valueType)
            }
            break
            
        case .LineRig:
            lineValueView.setValue(value: String(format: "%0.2f", line.lineRig!.floatValue), forTitle: "lineRig", andType: valueType)
            break
            
        case .VVacayPayNext:
            lineValueView.setValue(value: String(format: "%0.2f", line.vVacayPayNextBP!.floatValue), forTitle: "vpNe", andType: valueType)
            break
            
            
        case .VVacayPayBoth:
            lineValueView.setValue(value: String(format: "%0.2f", line.vVacayPayBothBP!.floatValue), forTitle: "vpBo", andType: valueType)
            break
            
        case .TpLPay:
            lineValueView.setValue(value: String(format: "%0.2f", line.vTpLPay!.floatValue), forTitle: "Vac+LG", andType: valueType)
            break
            
        case .ETrips:
            lineValueView.setValue(value: String(format: "%01zd", line.etopsTripsCount!.intValue), forTitle: "eTrips", andType: valueType)
            break
        case .WorkBlockCount:
            lineValueView.setValue(value: "\(line.workBlockCount?.intValue ?? 0)", forTitle: "BlkCount", andType: valueType)
            break
        case .ReserveDaysCount:
            lineValueView.setValue(value: "\(line.reserveDays?.intValue ?? 0)", forTitle: "DoR", andType: valueType)
            break
        case .rigADG:
            lineValueView.setValue(value: String(format: "%0.2f", line.rigADG?.floatValue ?? 0.0), forTitle: "rigADG", andType: valueType)
            break
        case .rigDHR:
            lineValueView.setValue(value: String(format: "%0.2f", line.rigDHR?.floatValue ?? 0.0), forTitle: "rigDHR", andType: valueType)
            break
        case .rigTHR:
            lineValueView.setValue(value: String(format: "%0.2f", line.rigTHR?.floatValue ?? 0.0), forTitle: "rigTHR", andType: valueType)
            break
        case .rigDPM:
            lineValueView.setValue(value: String(format: "%0.2f", line.rigDPM?.floatValue ?? 0.0), forTitle: "rigDPM", andType: valueType)
            break
        case .LinePay:
            lineValueView.setValue(value: String(format: "%0.2f", line.tripTfp?.floatValue ?? 0.0), forTitle: "TripTfp", andType: valueType)
            break
        case .coHoli:
            lineValueView.setValue(value: String(format: "%0.2f", line.coHoli?.floatValue ?? 0.0), forTitle: "coHoli", andType: valueType)
            break
        case .PayPlusCO:
            lineValueView.setValue(value: String(format: "%0.2f", line.payPlusCo?.floatValue ?? 0.0), forTitle: "Pay+CO", andType: valueType)
            break
        case .CoPlusHoli:
            lineValueView.setValue(value: String(format: "%0.2f", line.coPlusHoli?.floatValue ?? 0.0), forTitle: "Co+Holi", andType: valueType)
            break
        case .ClawBack:
            lineValueView.setValue(value: String(format: "%0.2f", line.clawBack?.floatValue ?? 0.0), forTitle: "ClawBack", andType: valueType)
        }
    }
    
    func resetStdAction(){
        UserDefaults.standard.removeObject(forKey: kCBDefaultLineValuesKey)
        let defaultLineValues = [CBLineValueTypes.Pay.rawValue, CBLineValueTypes.BlockTime.rawValue, CBLineValueTypes.AircraftChanges.rawValue, CBLineValueTypes.PayPerBlock.rawValue, CBLineValueTypes.PayPerDay.rawValue]
        let standardDefaults = [kCBDefaultLineValuesKey:defaultLineValues]
        UserDefaults.standard.register(defaults: standardDefaults)
        
        let defaultRound2LineValues = [CBLineValueTypes.Pay.rawValue, CBLineValueTypes.BlockDaysOff.rawValue, CBLineValueTypes.Weekends.rawValue, CBLineValueTypes.WorkDays.rawValue, CBLineValueTypes.PayPerDay.rawValue]
        let standardRound2Defaults = [ kCBRound2DefaultLineValuesKey : defaultRound2LineValues ]
        UserDefaults.standard.register(defaults: standardRound2Defaults)
        
        // Set up the swaptimizer default line values and add them to the register defaults
        UserDefaults.standard.removeObject(forKey: kCBSwaptimizerLineValuesKey)
        let swaptimizerLineValues = [CBLineValueTypes.VTotalPay.rawValue, CBLineValueTypes.VVacayPay.rawValue, CBLineValueTypes.VBlockTime.rawValue, CBLineValueTypes.VDaysOff.rawValue, CBLineValueTypes.VPayPerDay.rawValue]
        let swaptimizerDefaults = [kCBSwaptimizerLineValuesKey : swaptimizerLineValues]
        UserDefaults.standard.register(defaults: swaptimizerDefaults)
        
        // Set up the Fa Vacation default line values and add them to the register defaults
        UserDefaults.standard.removeObject(forKey: kCBFaVacationLineValuesKey)
        let faVacationLineValues = [CBLineValueTypes.VTotalPay.rawValue, CBLineValueTypes.VVacayPay.rawValue, CBLineValueTypes.VBlockTime.rawValue, CBLineValueTypes.VDaysOff.rawValue, CBLineValueTypes.VPayPerDay.rawValue]
        let faVacationDefaults = [kCBFaVacationLineValuesKey : faVacationLineValues]
        UserDefaults.standard.register(defaults: faVacationDefaults)
        
        self.tableView.reloadData()
        
    }
    
    func cellIsHidden(for lineValue: [AnyHashable: Any]) -> Bool {
        if self.bidPeriod!.isFABid() {
            return lineValue["isHiddenForFA"] as? Bool ?? false
        } else {
            let type = lineValue["type"] as? Int ?? 0
            return self.lineValueTypeIsHidden(forPilotVacation:CBLineValueTypes(rawValue: type)!)
        }
    }
    
    
    
    func lineValues1() -> [Any] {
        var values: [Any]? = nil
        let path = Bundle.main.path(forResource: "LineValues", ofType: "plist")
        let valueDictionary = NSDictionary(contentsOfFile: path!)
        values = valueDictionary?["values"] as? [Any] ?? [Any]()
        if (CBSwaptimizerStatus.enabled.rawValue == self.bidPeriod?.swaptimizerStatus?.intValue) || (BIFaVacationStatus.enabled.rawValue == self.bidPeriod?.faVacationStatus?.intValue) {
            let swaptimizerFileURL = Bundle.main.path(forResource: "LineValuesVacation", ofType: "plist")
            let swapValuesDictionary = NSDictionary(contentsOfFile: swaptimizerFileURL!)
            let swapValuesArray = swapValuesDictionary?["values"] as? [Any]
            values = swapValuesArray! + values!
        }
        return values!
    }
    
    func getLineValues() -> NSArray {
        var values: NSArray!
        let path = Bundle.main.path(forResource: "LineValues", ofType: "plist")
        let valueDictionary = NSMutableDictionary(contentsOfFile: path!)!
        values = (valueDictionary["values"]! as! NSArray)
        return values! as NSArray
    }
    
    static func lineValuesKey(for bidPeriod: BIBidPeriod) -> String {
        var lineValuesKey: String = ""
        if (bidPeriod.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue) {
            lineValuesKey = kCBSwaptimizerLineValuesKey;
        }
        else if (bidPeriod.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue) {
            lineValuesKey = kCBFaVacationLineValuesKey;
        } else {
            lineValuesKey = (bidPeriod.containsMissingTripLines?.boolValue ?? false) && !bidPeriod.isFABid() ? kCBRound2DefaultLineValuesKey : kCBDefaultLineValuesKey
        }
        return lineValuesKey
    }
    
    func lineValueTypeIsHidden(forPilotVacation type: CBLineValueTypes) -> Bool {
        guard let hiddenDict = UserDefaults.standard.dictionary(forKey: kCBSwaptimizerHiddenDict) else {
            return false
        }
        return (type.rawValue == CBLineValueTypes.VLength.rawValue && (hiddenDict[kCBSwaptmizerEffVacayLengthHidden] as? Bool ?? false)) ||
        (type.rawValue == CBLineValueTypes.LongBlock.rawValue && (hiddenDict[kCBSwaptmizerLongestBlockofDaysOffHidden] as? Bool ?? false)) ||
        (type.rawValue == CBLineValueTypes.VCarryOutPay.rawValue && (hiddenDict[kCBSwaptmizerCarryOutPayHidden] as? Bool ?? false)) ||
        (type.rawValue == CBLineValueTypes.VVacayCarryOutPay.rawValue && (hiddenDict[kCBSwaptmizerVacayCarryOutPayHidden] as? Bool ?? false)) ||
        (type.rawValue == CBLineValueTypes.VCarryOutVOPay.rawValue && (hiddenDict[kCBSwaptmizerCarryOutVoHidden] as? Bool ?? false)) ||
        (type.rawValue == CBLineValueTypes.VVacayPayNext.rawValue && (hiddenDict[kCBSwaptmizerVacPayNextBPHidden] as? Bool ?? false)) ||
        (type.rawValue == CBLineValueTypes.VVacayPayBoth.rawValue && (hiddenDict[kCBSwaptmizerVacPayBothBPHidden] as? Bool ?? false)) ||
        (type.rawValue == CBLineValueTypes.ClawBack.rawValue && (hiddenDict[kCBSwaptmizerClawBackHidden] as? Bool ?? false))
    }
    
    
    func lineValueTypeIsHidden(forPilotSecondRound type:CBLineValueTypes) -> Bool{
        if (self.bidPeriod?.wbFileIntent == nil) || (self.bidPeriod?.cbFileIntent == nil) || (type == .VacationPayDifference){
            return true
        }
        if (self.bidPeriod?.containsMissingTripLines!.boolValue)! && !(self.bidPeriod?.isFABid())! && type == .AircraftChanges || type == .Deadheads || type == .DutyTime || type == .Legs || type == .PayPerDutyTime || type == .PayPerLeg || type == .BlockTime || type == .PayPerBlock{
            return true
        }else{
            return false
        }
    }
}
