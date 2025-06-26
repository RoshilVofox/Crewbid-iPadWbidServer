//
//  CBLineValuesMenuController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 16/04/25.
//

import UIKit

class CBLineValuesMenuController: BaseViewController,UITableViewDelegate,UITableViewDataSource,KUIPopOverUsable {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var resetButton: UIButton!
    
    var lineValuesTemp:NSArray!
    
    var selectedValuesCount: Int = 0
    var lineValues = [Any]()
    weak var bidPeriod: BIBidPeriod?
    var menuItems = [Any]()
    
    var count = 0
    
    var contentSize: CGSize {
        return CGSize(width: 310.0, height: UIScreen.main.bounds.height - 120)
    }

    var arrowDirection: UIPopoverArrowDirection {
        return .left
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
//        lineValuesTemp = getLineValues()
        self.navigationController?.navigationBar.isHidden = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.separatorStyle = .singleLine
        self.tableView.allowsMultipleSelection = true
        
// ----------------------------------
        lineValues = lineValues1()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return lineValuesTemp.count
        return lineValues.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
//        let value = lineValuesTemp[indexPath.row] as! NSDictionary
        let value = lineValues[indexPath.row] as! NSDictionary
        let title = value["name"] as? String
        cell.textLabel?.text = title
        cell.selectionStyle = .none
        if (cell.isSelected) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if count < 5{
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
            count += 1
        }
        else{
            tableView.deselectRow(at: indexPath, animated: true)
            let alert = UIAlertController(title: "Cannot select more than 5 values.", message: "Please deselect values before adding new ones.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
        count -= 1
    }
    
    @IBAction func resetAction(_ sender: Any) {
        
    }
    
    class func setLineValueView(_ lineValueView: CBLineValueView, with line: BILine, forType valueType: CBLineValueTypes, bidPeriod: BIBidPeriod) {
        switch valueType {
            
        case CBLineValueTypes.cBLineValueTypeVOBoth:
            let val = (line.vBackVoPay?.floatValue ?? 0.0) + (line.vFrontVoPay?.floatValue ?? 0.0)
            lineValueView.setValue(value: String(format: "%.2f", val), forTitle: "VoBoth", andType: valueType)
            break
        case CBLineValueTypes.cbLineValueTypeVAbp:
            lineValueView.setValue(value: String(format: "%.2f", line.vAbp!.floatValue), forTitle: "VAbp", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeVAne:
            lineValueView.setValue(value: String(format: "%.2f", line.vAne?.floatValue ?? 0), forTitle: "VAne", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeVAbo:
            lineValueView.setValue(value: String(format: "%.2f", line.vAbo?.floatValue ?? 0), forTitle: "VAbo", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeVAPbp:
            lineValueView.setValue(value: String(format: "%.2f", line.vAPbp?.floatValue ?? 0), forTitle: "VAPbp", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeVAPne:
            lineValueView.setValue(value: String(format: "%.2f", line.vAPne?.floatValue ?? 0), forTitle: "VAPne", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeVAPbo:
            lineValueView.setValue(value: String(format: "%.2f", line.vAPbo?.floatValue ?? 0) , forTitle: "VAPbo", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeAircraftChanges:
            lineValueView.setValue(value: String(format: "%01ld", Int(truncating: line.numAircraftChanges!)), forTitle: "Chngs", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeAircraftTypeIs800:
            lineValueView.setValue(value: String(format: "%01ld", Int(truncating: line.aircraftType800Count!)), forTitle: "800s", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeAircraftTypeIs700:
            lineValueView.setValue(value: String(format: "%01ld", Int(truncating: line.aircraftType700Count!)), forTitle: "700s", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeAircraftTypeIs8Max:
            lineValueView.setValue(value: String(format: "%01ld", Int(truncating: line.aircraftType8MaxCount!)), forTitle: "8Max", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeAircraftTypeIs7Max:
            lineValueView.setValue(value: String(format: "%01ld", Int(truncating: line.aircraftType7MaxCount!)), forTitle: "7Max", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeBlockDaysOff:
            lineValueView.setValue(value: "\(Int(truncating: line.blockOfDaysOff!))", forTitle: "BlkOff", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeBlockTime:
            lineValueView.setValue(value: String(format: "%02zd:%02zd", Int(truncating: (line.blockMinutes!)) / 60, Int(truncating: line.blockMinutes!) % 60), forTitle: "BlkHrs", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueWorkBP:
            lineValueView.setValue(value: "\(Int(truncating: line.workDaysBP!))", forTitle: "Work BP", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeDaysOff:
            lineValueView.setValue(value: "\(String(describing: line.daysOff!))", forTitle: "DaysOff", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeDeadheads:
            lineValueView.setValue(value: "\(String(describing: line.deadheadsCount!))", forTitle: "DHs", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeDutyTime:
            lineValueView.setValue(value: String(format: "%01zd:%02zd", Int(truncating: line.dutyMinutes!) / 60, Int(truncating: line.dutyMinutes!) % 60), forTitle: "DtyHrs", andType: valueType)
            break
        case CBLineValueTypes.cBLineValueTypeGTmax:
            lineValueView.setValue(value: String(format: "%01zd:%02zd", Int(truncating: line.gTmax!) / 60, Int(truncating: line.gTmax!) % 60), forTitle: "GTmax", andType: valueType)
            break
        case CBLineValueTypes.cBLineValueTypeGTavg:
            lineValueView.setValue(value: String(format: "%01zd:%02zd", Int(truncating: line.gTavg!) / 60, Int(truncating: line.gTavg!) % 60), forTitle: "GTavg", andType: valueType)
            break
        case CBLineValueTypes.cbLineValueTypeDutyHoursPerDay:
            lineValueView.setValue(value: String(format: "%.2f", Float(truncating: line.dutyHoursPerDay!)), forTitle: "Dty/Day", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeNonConUsLegs:
            lineValueView.setValue(value: "\(String(describing: line.nonConusLegsCount!))", forTitle: "NC Legs", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeEarliestDept:
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
            
        case CBLineValueTypes.cbLineValueTypeLatestArr:
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
            
        case CBLineValueTypes.cbLineValueTypeLegs:
            lineValueView.setValue(value: String(format: "%d", line.numLegs!.intValue), forTitle: "Legs", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeMaxLegsInDay:
            lineValueView.setValue(value: String(format: "%d", line.maxLegsInADay!.intValue), forTitle: "MLegs", andType: valueType)
            break
            
        case CBLineValueTypes.cBLineValueTypeOvAvg:
            lineValueView.setValue(value: String(format: "%01zd:%02zd", Int(truncating: line.ovAvg ?? 0) / 60, Int(truncating: line.ovAvg ?? 0) % 60), forTitle: "OvAvg", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeOvernightsInBase:
            lineValueView.setValue(value: String(format: "%d", line.overnightsInBase!.intValue), forTitle: "OIBs", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypePassesThruBase:
            lineValueView.setValue(value: String(format: "%d", line.passesThruBase!.intValue), forTitle: "PTBs", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeT234:
            lineValueView.setValue(value: String(format: "%@", line.t234()), forTitle: "T234", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeTrips:
            lineValueView.setValue(value: String(format: "%d", line.numTrips!.intValue), forTitle: "Trips", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypePay:
            lineValueView.setValue(value: String(format: "%0.2f", line.pay!.floatValue), forTitle: "Pay", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypePayPerBlock:
            lineValueView.setValue(value: String(format: "%0.2f", Float(truncating: line.payPerBlockHour!)), forTitle: "$/Blk", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypePayPerLeg:
            lineValueView.setValue(value: String(format: "%0.2f", Float(truncating: line.payPerLeg!)), forTitle: "$/Leg", andType: valueType)
            if line.payPerLeg!.floatValue == Float.infinity {
                lineValueView.setValue(value: "0.00", forTitle: "$/Leg", andType: valueType)
            }
            break
            
        case CBLineValueTypes.cbLineValueTypePayPerTAFB:
            lineValueView.setValue(value: String(format: "%0.2f", Float(truncating: line.payPerTAFB!)), forTitle: "$/TAFB", andType: valueType)
            if line.payPerTAFB!.floatValue == Float.infinity{
                lineValueView.setValue(value: "0.00", forTitle: "$/TAFB", andType: valueType)
            }
            break
            
        case CBLineValueTypes.cbLineValueTypeTAFB:
            let firstValue: Int = Int(truncating: line.tafbMinutes!) / 60
            let secondValue: Int = Int(truncating: line.tafbMinutes!) % 60
            lineValueView.setValue(value: String(format: "%01zd:%02zd",Int(firstValue) , Int(secondValue)), forTitle: "TAFB", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypePayPerDay:
            lineValueView.setValue(value: String(format: "%0.2f", Float(truncating: line.payPerDay!)), forTitle: "$/Day", andType: valueType)
            if line.payPerDay!.floatValue == Float.infinity{
                lineValueView.setValue(value: "0.00", forTitle: "$/Day", andType: valueType)
            }
            break
            
        case CBLineValueTypes.cbLineValueTypePayPerDutyTime:
            lineValueView.setValue(value: String(format: "%0.2f", Float(truncating: line.payPerDutyTime!)), forTitle: "$/Duty", andType: valueType)
            if line.payPerDutyTime!.floatValue == Float.infinity{
                lineValueView.setValue(value: "0.00", forTitle: "$/Duty", andType: valueType)
            }
            break
            
        case CBLineValueTypes.cbLineValueTypeCarryOutPay:
            lineValueView.setValue(value: String(format: "%0.2f", Float(truncating: line.carryOutPay!)), forTitle: "CoPay", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeWeekends:
            lineValueView.setValue(value: "\(String(describing: line.weekendsCount!))", forTitle: "Wknds", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeWorkDays:
            lineValueView.setValue(value: "\(String(describing: line.workDays!))", forTitle: "Work All", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeVTotalPay:
            lineValueView.setValue(value: String(format: "%0.2f", line.vTotalPay!.floatValue), forTitle: "TotalPay", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeVFlyPay:
            lineValueView.setValue(value: String(format: "%0.2f", line.vFlyPay!.floatValue), forTitle: "FlyPay", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeVVacayPay:
            lineValueView.setValue(value: String(format: "%0.2f", line.vVacationPay!.floatValue), forTitle: "vpCu", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeVCarryOutPay:
            lineValueView.setValue(value: String(format: "%0.1f", line.vCarryOutPay!.floatValue), forTitle: "CoFlyPay", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeVBlockTime:
            let blockTime = line.vBlockTime ?? 0
            let hrs : Int = Int(truncating: blockTime)
            let minutesInHrs = Float(truncating: blockTime) - Float(truncating: hrs.asNSNumber)
            let mins = Int((minutesInHrs * 60.0).rounded())
            lineValueView.setValue(value: String(format: "%02zd:%02zd", hrs, mins), forTitle: "BlkHrs", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeVDaysOff:
            lineValueView.setValue(value: "\(String(describing: line.vDaysOff!.intValue))", forTitle: "DaysOff", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeVLength:
            lineValueView.setValue(value: "\(String(describing: line.vEffectiveVacayLength!.intValue))", forTitle: "EffLength", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeLongBlock:
        lineValueView.setValue(value: String(describing: (line.vLongestBlockofDaysOff?.intValue ?? 0)), forTitle: "LonBlkoff", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeVPayPerBlock:
            lineValueView.setValue(value: String(format: "%0.2f", line.vPayPerBlock!.floatValue), forTitle: "$/Blk", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeVPayPerDay:
            lineValueView.setValue(value: String(format: "%0.2f", line.vPayPerDay!.floatValue), forTitle: "$/Day", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeVVacayCarryOutPay:
            lineValueView.setValue(value: String(format: "%0.1f", line.vVacayCarryOutPay!.floatValue), forTitle: "CoVaPay", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeVCarryOutVOPay:
            lineValueView.setValue(value: String(format: "%0.1f", line.vCarryOutVOPay!.floatValue), forTitle: "CoVoPay", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeVFrontVoPay:
            lineValueView.setValue(value: String(format: "%0.1f", line.vFrontVoPay!.floatValue), forTitle: "FrontVO", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeVBackVoPay:
            lineValueView.setValue(value: String(format: "%0.1f", line.vBackVoPay!.floatValue), forTitle: "BackVO", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueHolidayRig:
            lineValueView.setValue(value: String(format: "%0.2f", line.holidayPay!.floatValue), forTitle: "HoliRig", andType: valueType)
            break
            
        case CBLineValueTypes.cbVacationPayDifference:
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
            
        case CBLineValueTypes.cbCommutabilityBacks:
            if line.commutabilityBack == 0 {
                lineValueView.setValue(value: "0", forTitle: "cmt%Ba", andType: valueType)
            }
            else {
                lineValueView.setValue(value: "\(String(format: "%0.2f", line.commutabilityBack!.floatValue))%", forTitle: "cmt%Ba", andType: valueType)
            }
            break
        case CBLineValueTypes.cbCommutabilityFronts:
            if line.commutabilityFront == 0 {
                lineValueView.setValue(value: "0", forTitle: "cmt%Fr", andType: valueType)
            }
            else {
                lineValueView.setValue(value: "\(String(format: "%0.2f", line.commutabilityFront!.floatValue))%", forTitle: "cmt%Fr", andType: valueType)
            }
            break
            
        case CBLineValueTypes.cbCommutableBacks:
            lineValueView.setValue(value: "\(String(describing: line.commutableBacks!))", forTitle: "cmtBa", andType: valueType)
            break
            
        case CBLineValueTypes.cbCommutableFronts:
            if !(line.commutableFronts == nil) {
                lineValueView.setValue(value: "\(String(describing: line.commutableFronts!))", forTitle: "cmtFr", andType: valueType)
            }
            else {
                lineValueView.setValue(value: "0", forTitle: "cmtFr", andType: valueType)
            }
            break
            
        case CBLineValueTypes.cbNightsInMid:
            lineValueView.setValue(value: "\(String(describing: line.nightsInMid!))", forTitle: "nMid", andType: valueType)
            break
            
        case CBLineValueTypes.cbTotalCommutes:
            lineValueView.setValue(value: "\(String(describing: line.totalCommutes!))", forTitle: "cmts", andType: valueType)
            break
            
        case CBLineValueTypes.cbCommutabilityOverall:
            if line.commutabilityOverall == 0 {
                lineValueView.setValue(value: "0", forTitle: "cmt%Ov", andType: valueType)
            }
            else {
                lineValueView.setValue(value: "\(String(format: "%0.2f", line.commutabilityOverall!.floatValue))%", forTitle: "cmt%Ov", andType: valueType)
            }
            break
            
        case CBLineValueTypes.cbLineValueTypeLineRig:
            lineValueView.setValue(value: String(format: "%0.2f", line.lineRig!.floatValue), forTitle: "lineRig", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeVVacayPayNext:
            lineValueView.setValue(value: String(format: "%0.2f", line.vVacayPayNextBP!.floatValue), forTitle: "vpNe", andType: valueType)
            break
            
            
        case CBLineValueTypes.cbLineValueTypeVVacayPayBoth:
            lineValueView.setValue(value: String(format: "%0.2f", line.vVacayPayBothBP!.floatValue), forTitle: "vpBo", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTpLPay:
            lineValueView.setValue(value: String(format: "%0.2f", line.vTpLPay!.floatValue), forTitle: "Vac+LG", andType: valueType)
            break
            
        case CBLineValueTypes.cbLineValueTypeETrips:
            lineValueView.setValue(value: String(format: "%01zd", line.etopsTripsCount!.intValue), forTitle: "eTrips", andType: valueType)
            break
        case .cbLineValueTypeWorkBlockCount:
            lineValueView.setValue(value: "\(line.workBlockCount?.intValue ?? 0)", forTitle: "BlkCount", andType: valueType)
            break
        case .cBLineValueTypeReserveDaysCount:
            lineValueView.setValue(value: "\(line.reserveDays?.intValue ?? 0)", forTitle: "DoR", andType: valueType)
            break
        case .cBLineValueTyperigADG:
            lineValueView.setValue(value: String(format: "%0.2f", line.rigADG?.floatValue ?? 0.0), forTitle: "rigADG", andType: valueType)
            break
        case .cBLineValueTyperigDHR:
            lineValueView.setValue(value: String(format: "%0.2f", line.rigDHR?.floatValue ?? 0.0), forTitle: "rigDHR", andType: valueType)
            break
        case .cBLineValueTyperigTHR:
            lineValueView.setValue(value: String(format: "%0.2f", line.rigTHR?.floatValue ?? 0.0), forTitle: "rigTHR", andType: valueType)
            break
        case .cBLineValueTyperigDPM:
            lineValueView.setValue(value: String(format: "%0.2f", line.rigDPM?.floatValue ?? 0.0), forTitle: "rigDPM", andType: valueType)
            break
        case .cBLineValueTypeLinePay:
            lineValueView.setValue(value: String(format: "%0.2f", line.tripTfp?.floatValue ?? 0.0), forTitle: "TripTfp", andType: valueType)
            break
        case .cBLineValueTypecoHoli:
            lineValueView.setValue(value: String(format: "%0.2f", line.coHoli?.floatValue ?? 0.0), forTitle: "coHoli", andType: valueType)
            break
        case .cBLineValueTypePayPlusCO:
            lineValueView.setValue(value: String(format: "%0.2f", line.payPlusCo?.floatValue ?? 0.0), forTitle: "Pay+CO", andType: valueType)
            break
        case .cBLineValueTypeCoPlusHoli:
            lineValueView.setValue(value: String(format: "%0.2f", line.coPlusHoli?.floatValue ?? 0.0), forTitle: "Co+Holi", andType: valueType)
            break
        case .cbLineValueTypeClawBack:
            lineValueView.setValue(value: String(format: "%0.2f", line.clawBack?.floatValue ?? 0.0), forTitle: "ClawBack", andType: valueType)
        }
    }
    
    
    func lineValues1() -> [Any] {
        var values: [Any]? = nil
        let path = Bundle.main.path(forResource: "LineValues", ofType: "plist")
        let valueDictionary = NSDictionary(contentsOfFile: path!)
        values = valueDictionary?["values"] as? [Any] ?? [Any]()
//        if CBSwaptimizerStatus.enabled.rawValue == Int(truncating: (bidPeriod?.swaptimizerStatus)!) || BIFaVacationStatus.enabled.rawValue == Int(truncating: (bidPeriod?.faVacationStatus)!) {
//            let swaptimizerFileURL = Bundle.main.path(forResource: "LineValuesVacation", ofType: "plist")
//            let swapValuesDictionary = NSDictionary(contentsOfFile: swaptimizerFileURL!)
//            var swapValuesArray = swapValuesDictionary?["values"] as? [Any]
//            if ((self.bidPeriod!.fvVacationArrayFromServer?.count ?? 0) > 0){
//                swapValuesArray?.remove(at: 3)
//            }
//            values = swapValuesArray! + values!
//        }
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
    
    func lineValueTypeIsHiddenForPilotVacation(_ type: Int) -> Bool {
        guard let hiddenDict = UserDefaults.standard.dictionary(forKey: kCBSwaptimizerHiddenDict) else {
            return false
        }

        return (type == CBLineValueTypes.cbLineValueTypeVLength.rawValue && (hiddenDict[kCBSwaptmizerEffVacayLengthHidden] as? Bool ?? false)) ||
        (type == CBLineValueTypes.cbLineValueTypeLongBlock.rawValue && (hiddenDict[kCBSwaptmizerLongestBlockofDaysOffHidden] as? Bool ?? false)) ||
        (type == CBLineValueTypes.cbLineValueTypeVCarryOutPay.rawValue && (hiddenDict[kCBSwaptmizerCarryOutPayHidden] as? Bool ?? false)) ||
        (type == CBLineValueTypes.cbLineValueTypeVVacayCarryOutPay.rawValue && (hiddenDict[kCBSwaptmizerVacayCarryOutPayHidden] as? Bool ?? false)) ||
               (type == CBLineValueTypes.cbLineValueTypeVCarryOutVOPay.rawValue && (hiddenDict[kCBSwaptmizerCarryOutVoHidden] as? Bool ?? false)) ||
               (type == CBLineValueTypes.cbLineValueTypeVVacayPayNext.rawValue && (hiddenDict[kCBSwaptmizerVacPayNextBPHidden] as? Bool ?? false)) ||
               (type == CBLineValueTypes.cbLineValueTypeVVacayPayBoth.rawValue && (hiddenDict[kCBSwaptmizerVacPayBothBPHidden] as? Bool ?? false)) ||
               (type == CBLineValueTypes.cbLineValueTypeClawBack.rawValue && (hiddenDict[kCBSwaptmizerClawBackHidden] as? Bool ?? false))
    }

}
