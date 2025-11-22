//
//  CBOvernightBulkRuleCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit
import CoreData

class CBOvernightBulkRuleCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var yesBtn: UIButton!
    @IBOutlet weak var noBtn: UIButton!
    @IBOutlet weak var noneBtn: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var lblOvernightBulkTitle: UILabel!
    @IBOutlet weak var lblnoOvernightCities: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    
    var dictCityStatus: [String: Any]?
    var filterRule: BIFilterRule?
    var bidPeriod: BIBidPeriod?
    var objOvernight: OvernightBulk?
    var arrOverNightCitiesList: [String]?
    var arrCitiesList: NSMutableArray?
    var arrIntersected = NSMutableArray()
    var context = CBGlobalMethods.shared.selectedBidPeriod?.managedObjectContext
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        arrCitiesList = UserDefaults.standard.value(forKey: kCBAllCitiesList) as? NSMutableArray
        lblOvernightBulkTitle.transform = CGAffineTransformMakeRotation(3.14/2)
        lblnoOvernightCities.transform = CGAffineTransformMakeRotation(3.14/2)
        dictCityStatus = [:]
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    func reloadContent() {
        if self.filterRule?.ruleHighlightsTrips() == true {
            CBUtils.highlightTripsOverNightBulk()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }
    }
    func configureOvernightBulkCell() {
        let context = GlobalBidInfo.shared.managedObjectContext
        let fetchRequest: NSFetchRequest<OvernightBulk> = OvernightBulk.fetchRequest()
        do {
            let fetchedObjects = try context.fetch(fetchRequest)
            if fetchedObjects.count > 0 {
                objOvernight = fetchedObjects[0]
                if let cityStatusValueArray = objOvernight!.value(forKey: "citystatus") as? NSMutableArray, cityStatusValueArray.count > 0 {
                    dictCityStatus = (cityStatusValueArray[0] as? [String: Any])!
                }
                else if let cityStatus = fetchedObjects.first?.value(forKey: "citystatus") as? [String: Any] {
//                    when taking from state sync
                    if (cityStatus["OverNightYes"] != nil) || (cityStatus["OverNightNo"] != nil) {
                        if let yesList = cityStatus["OverNightYes"] as? [String] {
                            for city in yesList {
                                dictCityStatus?[city] = 1
                            }
                        }

                        if let noList = cityStatus["OverNightNo"] as? [String] {
                            for city in noList {
                                dictCityStatus?[city] = 2
                            }
                        }
                    }
                    else {
//                        normal
                        dictCityStatus = cityStatus
                    }// [String: Any] is already mutable in Swift
                }
            }
            else {
                objOvernight = OvernightBulk(context: context)
                objOvernight?.citystatus = [:] as NSObject
                dictCityStatus = [:]
                
                do {
                    try context.save()
                } catch {
                    print("Save error: \(error.localizedDescription)")
                }
            }
            if bidPeriod?.overNightCities?.count == 0 {
                arrOverNightCitiesList = CBUtils.GenerateOvernightCities()
            }
            else {
                arrOverNightCitiesList = bidPeriod?.overNightCities as? [String]
            }
            if dictCityStatus?.count == 0 {
                self.dictCityStatus = filterRule?.variables as? [String: Any]
            }
            arrCitiesList?.remove("")
            if let cities = arrCitiesList as? [AnyHashable],
               let overnightCities = arrOverNightCitiesList {
                
                let intersection = Set(cities).intersection(Set(overnightCities))
                arrIntersected =  NSMutableArray(array: Array(intersection))
            }
            self.collectionView.reloadData()
        }
        catch {
            print("error fetching overnightBulk: \(error.localizedDescription)")
        }
//        self.collectionView.reloadData()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @IBAction func deleteCellAction(_ sender: Any) {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        
        self.bidPeriod?.isOverNightBulkApplied = "NO"
        if (self.filterRule?.ruleHighlightsTrips() == true) {
            self.filterRule?.deHighlightTrips()
        }
        
        let filterFetchRequest: NSFetchRequest<BIFilterRule> = BIFilterRule.fetchRequest()
        filterFetchRequest.predicate = NSPredicate(format: "category == 34")
        let fetchedFilter = try? context?.fetch(filterFetchRequest)
        for filter in fetchedFilter! {
            context?.delete(filter)
        }
        let overnightBulkFetchRequest: NSFetchRequest<OvernightBulk> = OvernightBulk.fetchRequest()
        let resuts = try? context?.fetch(overnightBulkFetchRequest)
        for bulk in resuts! {
            context?.delete(bulk)
        }
        try? self.context?.save()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrCitiesList!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let kCityCellIdentifier = "CityCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kCityCellIdentifier, for: indexPath) as! CBOvernightCitiesBulkCollectionViewCell
        if arrCitiesList![indexPath.row] as! String == "ATL" {
            print("")
        }
        cell.lblCityName.text = arrCitiesList![indexPath.row] as? String
        if arrIntersected.contains(arrCitiesList![indexPath.row]) {
            let key = String(describing: arrCitiesList![indexPath.row])
            let value = String(describing: dictCityStatus![key] ?? "")
            if value != "" {
//                let key = String(describing: arrCitiesList![indexPath.row])
//                let type1 = dictCityStatus![key] as? String ?? "0"
                let type = Int(value)
                switch type {
                case ColorType.red.rawValue:
                    cell.lblCityName.backgroundColor = .red
                    cell.lblCityName.textColor = .white
                    cell.isUserInteractionEnabled = true
                    break
                case ColorType.green.rawValue:
                    cell.lblCityName.backgroundColor = .green
                    cell.lblCityName.textColor = .white
                    cell.isUserInteractionEnabled = true
                    break
                case ColorType.nocolor.rawValue:
                    cell.lblCityName.backgroundColor = .clear
                    cell.isUserInteractionEnabled = true
                    if #available(iOS 13.0, *) {
                        cell.lblCityName.textColor = UIColor.label
                    } else {
                        cell.lblCityName.textColor = UIColor.black // Fallback on earlier versions
                    }
                    break
                default:
                    break
                }
            }
            else {
                cell.isUserInteractionEnabled = true
                cell.lblCityName.backgroundColor = .clear
                cell.lblCityName.textColor = .label
            }
        }
        else {
            cell.isUserInteractionEnabled = false
            cell.lblCityName.textColor = .white
            cell.lblCityName.backgroundColor = .black
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        CBGlobalMethods.shared.showActivityIndicator(bgColor: .purple)
        self.bidPeriod?.currentDateTime = Date()
        self.bidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        if self.filterRule?.ruleHighlightsTrips() == true {
            self.filterRule?.deHighlightTrips()
        }
        let cell = collectionView.cellForItem(at: indexPath) as! CBOvernightCitiesBulkCollectionViewCell
//        if cell.lblCityName.backgroundColor == .clear {
//            cell.lblCityName.backgroundColor = .red
//            cell.lblCityName.textColor = .white
//            dictCityStatus![arrCitiesList![indexPath.row] as! String] = String(ColorType.red.rawValue)
//        }
        if cell.lblCityName.backgroundColor == .clear {
            cell.lblCityName.backgroundColor = .red
            cell.lblCityName.textColor = .white
            dictCityStatus![arrCitiesList![indexPath.row] as! String] = String(ColorType.red.rawValue)
        }
        else if cell.lblCityName.backgroundColor == .red {
            cell.lblCityName.backgroundColor = .green
            cell.lblCityName.textColor = .white
            dictCityStatus![arrCitiesList![indexPath.row] as! String] = String(ColorType.green.rawValue)
        }
        else if cell.lblCityName.backgroundColor == .green {
            cell.lblCityName.backgroundColor = .clear
            cell.lblCityName.textColor = .label
            dictCityStatus![arrCitiesList![indexPath.row] as! String] = String(ColorType.nocolor.rawValue)
        }
        
        let dict = NSDictionary(dictionary: dictCityStatus!)
        objOvernight?.citystatus = dict
        filterRule?.variables = dict
        try? context?.save()
        let noArray = (dictCityStatus!.filter { $0.value as? String == "1" }.map { $0.key } as? NSArray)!
        let yesArray = (dictCityStatus!.filter { $0.value as? String == "2" }.map { $0.key } as? NSArray)!

        CBUtils.overnightBulkRedApply(noArray: noArray)
        CBUtils.overnightBulkGreenApply(yesArray: yesArray)
        reloadContent()
        CBGlobalMethods.shared.hideActivityIndicator()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let collectionviewWidth = collectionView.frame.size.width
        return CGSize(width: collectionviewWidth/7, height: 45)
    }
}
