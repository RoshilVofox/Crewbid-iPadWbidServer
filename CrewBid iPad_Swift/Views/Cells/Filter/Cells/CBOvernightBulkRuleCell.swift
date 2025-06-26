//
//  CBOvernightBulkRuleCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit
import CoreData

class CBOvernightBulkRuleCell: UITableViewCell {
    
    @IBOutlet weak var yesBtn: UIButton!
    @IBOutlet weak var noBtn: UIButton!
    @IBOutlet weak var noneBtn: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var overnightCities: UILabel!
    @IBOutlet weak var noOvernightCities: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    
    var dictCityStatus: [String: Any]?
    var filterRule: BIFilterRule?
    var bidPeriod: BIBidPeriod?
    var objOvernight: OvernightBulk?
    var arrOverNightCitiesList: [String]?
    var arrCitiesList: NSMutableArray?
    var arrIntersected: NSMutableArray?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configureOvernightBulkCell() {
        let context = GlobalBidInfo.shared.managedObjectContext
        let fetchRequest: NSFetchRequest<OvernightBulk> = OvernightBulk.fetchRequest()
        do {
            let fetchedObjects = try context.fetch(fetchRequest)
            if fetchedObjects.count > 0 {
                objOvernight = fetchedObjects[0]
                if let cityStatus = fetchedObjects.first?.value(forKey: "citystatus") as? [String: Any] {
                    dictCityStatus = cityStatus  // [String: Any] is already mutable in Swift
                }
            }
            else {
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
            arrCitiesList?.remove("")
            if let cities = arrCitiesList as? [AnyHashable],
               let overnightCities = arrOverNightCitiesList {
                
                let intersection = Set(cities).intersection(Set(overnightCities))
                arrIntersected = Array(intersection) as? NSMutableArray
            }
            self.collectionView.reloadData()
        }
        catch {
            print("error fetching overnightBulk: \(error.localizedDescription)")
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @IBAction func deleteCellAction(_ sender: Any) {
        NotificationCenter.default.post(
            name: Notification.Name("DeleteCellNotification"),
            object: self // Pass the cell itself as the object
        )
    }
}
