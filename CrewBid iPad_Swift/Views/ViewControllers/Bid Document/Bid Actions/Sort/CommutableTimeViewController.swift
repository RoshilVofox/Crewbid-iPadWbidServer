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
    @IBOutlet weak var navTitle: UINavigationItem!
    
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
            self.navTitle.title = "Arr & Dep Times (Non stop)"
        }
    }
    
    func generateCommutableTimeData() -> NSMutableArray {
        let fetchedObjects = (bidPeriod!.commuteTime!.allObjects as NSArray).sortedArray(using: [NSSortDescriptor(key: "bidDay", ascending: true)]) as! [CommuteTime]
        let arrModifiedValues = NSMutableArray()
        for i in 0..<fetchedObjects.count {
            autoreleasepool {
                let dateFormat = DateFormatter()
                dateFormat.dateFormat = "HHmm"
                if let timezone = TimeZone(secondsFromGMT: 0) {
                    dateFormat.timeZone = timezone as TimeZone
                }
                let commuteTime = fetchedObjects[i]
                let depDate = commuteTime.latestDeparture!
                var arrivalDate = commuteTime.earliestArrivel!
                var latestDeparture = dateFormat.string(from: depDate as Date)
                var earliestArrival = dateFormat.string(from: arrivalDate as Date)
                let dateFormateForDate = DateFormatter()
                dateFormateForDate.dateFormat = "dd"
                if let timezone = TimeZone(secondsFromGMT: 0) {
                    dateFormateForDate.timeZone = timezone as TimeZone
                }
                
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
            let value = arrCommutTimeFetched.object(at: indexPath.row - (weekday - 1)) as! NSDictionary
            cell.dateLabel.text = value.value(forKey: "departure") as? String
            //For showing the the latest departure value blank if the latest departure value is 0000
            cell.latestDeparureLabel.text = value.value(forKey: "departure") as? String
            //For showing the the earliest arrival value blank if the earliest arrival value is 0000
            cell.earliestArrivalLabel.text = value.value(forKey: "arrival") as? String
        }
        else {
            cell.isHidden = true
        }
        return cell
    }
}

