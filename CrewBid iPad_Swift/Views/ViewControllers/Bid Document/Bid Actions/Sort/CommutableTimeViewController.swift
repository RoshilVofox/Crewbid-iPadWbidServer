//
//  CommutableTimeViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 17/04/25.
//

import UIKit

class CommutableTimeViewController: UIViewController, KUIPopOverUsable, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var contentSize: CGSize = CGSize(width: 400, height: 450)
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var lblMonthandYear: UILabel!
    @IBOutlet weak var lblCommuteCity: UILabel!
    @IBOutlet weak var lblBase: UILabel!
    @IBOutlet weak var herbLocalView: UIView!
    @IBOutlet weak var herbLbl: UILabel!
    @IBOutlet weak var localLbl: UILabel!
    @IBOutlet weak var herbLocalBtn: UIButton!
    @IBOutlet weak var lblTitle: UILabel!
    
    var bidPeriod: BIBidPeriod?
    var commuteCityValue = ""
    var weekday: Int = 0
    var arrCommutTimeFetched = NSArray()
    var isNonStop: Bool = false
    var arrowDirection: UIPopoverArrowDirection { return .left}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let month = bidPeriod!.month!.intValue
        let year = bidPeriod!.year!.intValue
        
        let dateString = "\(month)-\(year)"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-yyyy"
        let myDate: Date? = dateFormatter.date(from: dateString)!
        dateFormatter.dateFormat = "MMM-yyyy"
        var strDate: String? = nil
        if let aDate = myDate {
            strDate = dateFormatter.string(from: aDate)
        }
        
        let gregorian = Calendar(identifier: .gregorian)
        let aribtraryDate: Date? = myDate
        var comp: DateComponents? = nil
        if let aDate = aribtraryDate {
            comp = gregorian.dateComponents([.year, .month, .day], from: aDate)
        }
        comp?.day = 1
        var firstDayOfMonthDate: Date? = nil
        if let aComp = comp {
            firstDayOfMonthDate = gregorian.date(from: aComp)
        }
        
        var comps: DateComponents? = nil
        if firstDayOfMonthDate != nil {
            comps = gregorian.dateComponents([.weekday], from: firstDayOfMonthDate!)
        }
        
        let dayWeek: Int? = comps?.weekday
        if bidPeriod!.isFABid() == true && bidPeriod!.month!.intValue == 2 {
            weekday = (dayWeek ?? 0) - 1
        }
        else if bidPeriod!.isFABid() == true && bidPeriod!.month!.intValue == 3 {
            weekday = (dayWeek ?? 0) + 1
        }
        else {
            weekday = dayWeek!
        }
        
        lblBase.text = bidPeriod!.base
        lblCommuteCity.text = commuteCityValue
        lblMonthandYear.text = strDate
        arrCommutTimeFetched = generateCommutableTimeData()
        if isNonStop {
            self.lblTitle.text = "Arr & Dep Times (Non stop)"
        }
        
        herbLocalView.layer.borderWidth = 1
        herbLocalView.layer.borderColor = UIColor.black.cgColor
        herbLocalView.layer.cornerRadius = 11
    
        herbLbl.layer.borderColor = UIColor.white.cgColor
        herbLbl.layer.borderWidth = 0.4
        herbLbl.layer.cornerRadius = 10
        herbLbl.clipsToBounds = true
        
        localLbl.layer.borderColor = UIColor.white.cgColor
        localLbl.layer.borderWidth = 0.4
        localLbl.layer.cornerRadius = 10
        localLbl.clipsToBounds = true
        
        if UserDefaults.standard.integer(forKey: kCBTimeZoneSetting) == CBTimeZoneSetting.herbTime.rawValue {
            herbLbl.backgroundColor = .purple
            herbLbl.textColor = .white
            localLbl.backgroundColor = .white
            localLbl.textColor = .black
        }else{
            localLbl.backgroundColor = .purple
            localLbl.textColor = .white
            herbLbl.backgroundColor = .white
            herbLbl.textColor = .black
        }
        
        
    }
    
    func generateCommutableTimeData() -> NSMutableArray {
        let arrModifiedValues = NSMutableArray()
        
        guard let bidPeriod = self.bidPeriod else { return arrModifiedValues }
//        let useHerbTime = UserDefaults.standard.integer(forKey: kCBTimeZoneSetting) == CBTimeZoneSetting.herbTime.rawValue
//        let herbTZ = TimeZone(secondsFromGMT: 0)!
//        let commuteTZ = CBUtils.timeZone(forAirportCode: self.commuteCityValue)
//        let targetTZ = useHerbTime ? herbTZ : commuteTZ


        let fetchedObjects = (bidPeriod.commuteTime!.allObjects as NSArray).sortedArray(using: [NSSortDescriptor(key: "bidDay", ascending: true)]) as! [CommuteTime]

        for i in 0..<fetchedObjects.count {
            autoreleasepool {
                let dateFormat = DateFormatter()
                dateFormat.dateFormat = "HHmm"
                if let timezone = TimeZone(secondsFromGMT: 0) {
                    dateFormat.timeZone = timezone as TimeZone
                }

//                dateFormat.timeZone = targetTZ
                
                let commuteTime = fetchedObjects[i]
                let depDate = commuteTime.latestDeparture!
                let arrivalDate = commuteTime.earliestArrivel!
                let latestDeparture = dateFormat.string(from: depDate as Date)
                let earliestArrival = dateFormat.string(from: arrivalDate as Date)
                let dateFormateForDate = DateFormatter()
                dateFormateForDate.dateFormat = "dd"
                if let timezone = TimeZone(secondsFromGMT: 0) {
                    dateFormateForDate.timeZone = timezone as TimeZone
                }
                

//                dateFormateForDate.timeZone = targetTZ
                
                let biDay = commuteTime.bidDay!
                var day: String? = nil
                day = dateFormateForDate.string(from: biDay)
                let dicData = NSMutableDictionary()
                dicData.setObject(day!, forKey: "Day" as NSCopying)
                dicData.setObject(earliestArrival, forKey: "arrival" as NSCopying)
                dicData.setObject(latestDeparture, forKey: "departure" as NSCopying)
                arrModifiedValues.add(dicData)
            }
        }
        return arrModifiedValues
    }



    
    @IBAction func btnDoneAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func herbLocalBtnAction(_ sender: Any) {
        if UserDefaults.standard.integer(forKey: kCBTimeZoneSetting) == CBTimeZoneSetting.herbTime.rawValue {
            UserDefaults.standard.set(CBTimeZoneSetting.localTime.rawValue, forKey: kCBTimeZoneSetting)
           // btnTimeToggle.setTitle("Local Time", for: .normal)
            localLbl.backgroundColor = .purple
            localLbl.textColor = .white
            herbLbl.backgroundColor = .white
            herbLbl.textColor = .black
        }
        else {
            UserDefaults.standard.set(CBTimeZoneSetting.herbTime.rawValue, forKey: kCBTimeZoneSetting)
            //btnTimeToggle.setTitle("Herb Time", for: .normal)
            herbLbl.backgroundColor = .purple
            herbLbl.textColor = .white
            localLbl.backgroundColor = .white
            localLbl.textColor = .black
        }
//        arrCommutTimeFetched = generateCommutableTimeData()
        collectionView.reloadData()
        NotificationCenter.default.post(name: NSNotification.Name("updateLocalHerbSwitchUI"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrCommutTimeFetched.count + (weekday - 1)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Adjust cell size for orientation
        return CGSize(width: (self.collectionView.frame.size.width - 45) / 7, height: (self.collectionView.frame.size.height - 10) / 6)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ArrivalDepartureTimeCell", for: indexPath) as! ArrivalDepartureTimeCell
        if indexPath.row >= weekday - 1 {
            cell.isHidden = false
            cell.dateLabel.backgroundColor = UIColor(red: 205.0 / 255.0, green: 85.0 / 255.0, blue: 4.0 / 255.0, alpha: 1.0)
            let item = arrCommutTimeFetched.object(at: indexPath.row - (weekday - 1)) as! NSDictionary
//            cell.dateLabel.text = item.value(forKey: "Day") as? String
            //For showing the the latest departure value blank if the latest departure value is 0000
//            cell.latestDeparureLabel.text = item.value(forKey: "departure") as? String
            //For showing the the earliest arrival value blank if the earliest arrival value is 0000
//            cell.earliestArrivalLabel.text = item.value(forKey: "arrival") as? String
            cell.dateLabel.text = item["Day"] as? String
            let day = (item["Day"] as? NSString)?.integerValue ?? 1
            let month = (self.bidPeriod?.month as? NSNumber)?.intValue ?? ((self.bidPeriod?.month as? Int) ?? 1)
            let year = (self.bidPeriod?.year as? NSNumber)?.intValue ?? ((self.bidPeriod?.year as? Int) ?? 1970)
            
            if let depTime = item["departure"] as? String {
                if UserDefaults.standard.integer(forKey: kCBTimeZoneSetting) == CBTimeZoneSetting.herbTime.rawValue{
                    cell.latestDeparureLabel.text = depTime
                }else{
                    if depTime != "0000" && !depTime.isEmpty{
                        cell.latestDeparureLabel.text = convertHHMM(depTime, day: day, month: month, year: year)
                    }else{
                        cell.latestDeparureLabel.text = ""
                    }
                }
            }else{
                cell.latestDeparureLabel.text = ""
            }
            
            if let arrTime = item["arrival"] as? String {
                if UserDefaults.standard.integer(forKey: kCBTimeZoneSetting) == CBTimeZoneSetting.herbTime.rawValue{
                    cell.earliestArrivalLabel.text = arrTime
                }else{
                    if arrTime != "0000" && !arrTime.isEmpty{
                        cell.earliestArrivalLabel.text = convertHHMM(arrTime, day: day, month: month, year: year)
                    }else{
                        cell.earliestArrivalLabel.text = ""
                    }
                }
            }else{
                cell.earliestArrivalLabel.text = ""
            }
        }
        else {
            cell.isHidden = true
        }
        return cell
    }
    
    
    
    func convertHHMM(_ hhmm: String, day: Int, month: Int, year: Int) -> String {
        let trimmed = hhmm.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "" }

        // Herb TZ (original code used US/Central for herb)
        let herbTZ = TimeZone(identifier: "US/Central") ?? TimeZone(secondsFromGMT: 0)!

        // commute city local tz — use your CBUtils helper (adapt name if different)
        let commuteTZ = CBUtils.timeZone(forAirportCode: self.commuteCityValue)

        // parse HHmm or HH:mm
        var hh = "00", mm = "00"
        if trimmed.contains(":") {
            let parts = trimmed.split(separator: ":").map { String($0) }
            if parts.count >= 2 {
                hh = parts[0].trimmingCharacters(in: .whitespaces)
                mm = parts[1].trimmingCharacters(in: .whitespaces)
            }
        } else if trimmed.count >= 4 {
            let start = trimmed.startIndex
            let hhRange = start..<trimmed.index(start, offsetBy: 2)
            let mmRange = trimmed.index(start, offsetBy: 2)..<trimmed.index(start, offsetBy: 4)
            hh = String(trimmed[hhRange])
            mm = String(trimmed[mmRange])
        } else {
            return hhmm // fallback if unexpected format
        }

        // sanitize components
        let safeDay = (1...31).contains(day) ? day : 1
        let safeMonth = (1...12).contains(month) ? month : 1
        let safeYear = (year >= 1) ? year : 1970

        let full = String(format: "%04d-%02d-%02d %@:%@", safeYear, safeMonth, safeDay, hh, mm)

        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyyy-MM-dd HH:mm"
        parser.timeZone = herbTZ

        guard let date = parser.date(from: full) else {
            return hhmm // fallback
        }

        let out = DateFormatter()
        out.locale = Locale(identifier: "en_US_POSIX")
        out.dateFormat = "HHmm"
        out.timeZone = commuteTZ

        return out.string(from: date)
    }
}

