//
//  CommuteCityViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 17/04/25.
//

import UIKit

protocol CityNameViewControllerDelegate: AnyObject {
    func setCityName(_ cityName: String?)
    func disableButtonsForNoConnection()
}

class CommuteCityViewController: UIViewController, KUIPopOverUsable, UICollectionViewDelegate, UICollectionViewDataSource {
    var contentSize: CGSize = CGSize(width: 350, height: 420)
    @IBOutlet weak var collectionView: UICollectionView!
    
    var delegate: CityNameViewControllerDelegate!
    var arrAllCities: NSMutableArray!
    var commuteTime: CommuteTime?
    var depTime: Int = 0
    var arrTime: Int = 0
    var bidPeriod: BIBidPeriod?
    var isNonStopOnly : Bool = false
    var connectTime : Int = 30
    
    var arrowDirection: UIPopoverArrowDirection = UIPopoverArrowDirection.left
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        let cityArray = UserDefaults.standard.array(forKey: kCBAllCitiesList) as? [String]
        let sortedCityArray = cityArray!.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        arrAllCities = NSMutableArray(array: sortedCityArray)
        arrAllCities?.remove("")
       
    }
    
    @IBAction func btnCloseAction(_ sender: Any) {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod!.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod!.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        self.dismiss(animated: true, completion: nil)
    }
    
    func commutabilityCalculationWithForSync(city: String, isNonStop: Bool) -> (Bool, String) {
        let startOfMonth = self.startOfMonth()!
        var endOfMonth = self.endOfMonth()!
        let flightRoteDetails = CBUtils.getFlightData()
        let (success, commuteCity) = CBCommutingCellHelper().calculateCommutability(commuteCity: city, flightRoteDetails: flightRoteDetails, isNonStopOnly: isNonStop, bidperiod: self.bidPeriod!, start: startOfMonth, end: &endOfMonth, connectTime: self.connectTime)
        return (success, commuteCity)
    }
    
    func commutablityCalculationWithForCommuteDiff(city: String, isNonStop: Bool) -> (Bool, NSMutableArray) {
        let startOfMonth = self.startOfMonth()!
        var endOfMonth = self.endOfMonth()!
        let flightRoteDetails = CBUtils.getFlightData()
        let (success, commuteArray) =  CBCommutingCellHelper().calculateCommutabilityForCommuteDiff(commuteCity: city, flightRoteDetails: flightRoteDetails, isNonStopOnly: isNonStop, bidperiod: self.bidPeriod!, start: startOfMonth, end: &endOfMonth, connectTime: self.connectTime)
        return (success, commuteArray)
    }

    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrAllCities.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CityPickerCell", for: indexPath) as! CityPickerCell
        cell.cityLabel.text = "\(arrAllCities[indexPath.row])"
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        AlertService.showAlertForTopVC(title: self.arrAllCities.object(at: indexPath.row) as? String, message: "is your Commuter City?", actions: [(
            title: "Yes",
            style: .default,
            handler: { _ in
                CBGlobalMethods.shared.showActivityIndicator(bgColor: .purple)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.commuteCitySelecction(indexPath: indexPath)
                    CBGlobalMethods.shared.hideActivityIndicator()
                    self.dismissPopover(animated: true)
                }
            }
        ),
        (
            title: "No",
            style: .cancel,
            handler: { _ in }
        )])
    }
    
    func commuteCitySelecction(indexPath:IndexPath)  {
        let startOfMonth = self.startOfMonth()!
        var endOfMonth = self.endOfMonth()!
        let flightRoteDetails = CBUtils.getFlightData()
        let (success, commuteCity) =  CBCommutingCellHelper().calculateCommutability(commuteCity: self.arrAllCities.object(at: indexPath.row) as! String, flightRoteDetails: flightRoteDetails, isNonStopOnly: self.isNonStopOnly, bidperiod: self.bidPeriod!, start: startOfMonth, end: &endOfMonth, connectTime: self.connectTime)
        if success {
            self.delegate.disableButtonsForNoConnection()
            CBGlobalMethods.shared.hideActivityIndicator()
            AlertService.showAlertForTopVC(title: "Crewbid", message: "There are NO possible connections between your commute city and your base.")
        }
        else {
            self.delegate.setCityName(commuteCity)
        }
    }
    
    func startOfMonth() -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        if let timeZone = TimeZone(secondsFromGMT: 0) {
            calendar.timeZone = timeZone as TimeZone
        }
        var day: NSNumber?
        var month: NSNumber?
        var year: NSNumber?
        var components = DateComponents()
        
        if (bidPeriod?.isFABid() == true && bidPeriod!.month!.intValue == 2) {
            day = 31
            month = 1
            year = bidPeriod!.year
        }
        else if (bidPeriod?.isFABid() == true && bidPeriod!.month!.intValue == 3) {
            day = 2
            month = bidPeriod!.month
            year = bidPeriod!.year
        }
        else {
            day = 1
            month = bidPeriod!.month
            year = bidPeriod!.year
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
        var daysToAdd = 1
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        if let timezone = TimeZone(secondsFromGMT: 0) {
            calendar.timeZone = timezone as TimeZone
        }
        var components = DateComponents()
        let day = 1
        let month = bidPeriod!.month!.intValue
        let year = bidPeriod!.year!.intValue
        components.day = day
        components.month = month
        components.year = year
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        var dateComponents = DateComponents()
        dateComponents.month = 1
        dateComponents.day = -1
        var lastDayOfMonth = calendar.date(byAdding: dateComponents, to: calendar.date(from: components)!)
//        in case of february month for FA the last date should be march 1.
        if (bidPeriod!.isFABid() == true && bidPeriod!.month!.intValue == 2) {
            lastDayOfMonth = lastDayOfMonth?.addingTimeInterval(TimeInterval(60 * 60 * 24 * daysToAdd))
            return lastDayOfMonth
        }
        else if (bidPeriod!.isFABid() == true && bidPeriod!.month!.intValue == 1) {
            daysToAdd = -1
            lastDayOfMonth = lastDayOfMonth?.addingTimeInterval(TimeInterval(60 * 60 * 24 * daysToAdd))
            return lastDayOfMonth
        }
        else {
            return lastDayOfMonth
        }
    }
    
    
}
