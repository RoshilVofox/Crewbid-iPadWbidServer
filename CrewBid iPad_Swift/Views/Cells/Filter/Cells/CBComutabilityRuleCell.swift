//
//  CBComutabilityRuleCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit
import CoreData

enum CommutabilityType: Int {
    case filter = 0
    case sort
}


class CBComutabilityRuleCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var secondCellValue: UIButton!
    @IBOutlet weak var btnValue: UIButton!
    @IBOutlet weak var fourthCellValue: UIButton!
    @IBOutlet weak var thirdCellValue: UIButton!
    var filterRule: BIFilterRule?
    var objcommutability: Commutability?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @IBAction func deleteCellRow(_ sender: Any) {
        NotificationCenter.default.post(
            name: Notification.Name("DeleteCellNotification"),
            object: self // Pass the cell itself as the object
        )
    }
    
    func configurecommutabilityCell() {
        let context = GlobalBidInfo.shared.managedObjectContext
        let fetchRequest: NSFetchRequest<Commutability> = Commutability.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "commutableType == %d",CommutabilityType.filter.rawValue)
        do {
            let fetchedObjectsFilter = try context.fetch(fetchRequest)
            if fetchedObjectsFilter.count > 0 {
                objcommutability = fetchedObjectsFilter[0]
                var secondValue = (objcommutability?.secondCellValue!.intValue)! - 1
                if secondValue < 0 {
                    secondValue = 0
                }
                let title = CBUtils.commutabilitySecondCellValue()[secondValue]
                secondCellValue.setTitle(title, for: .normal)
                var thirdValue = (objcommutability?.thirdCellValue!.intValue)! - 1
                if thirdValue < 0 {
                    thirdValue = 0
                }
                let title1 = CBUtils.CommutabilityThirdCell()[thirdValue]
                thirdCellValue.setTitle(title, for: .normal)
                var type = (objcommutability?.type!.intValue)! - 1
                if type < 0 {
                    type = 0
                }
                let title2 = CBUtils.CommutabilityFourthCell()[type]
                fourthCellValue.setTitle(title, for: .normal)
                if let firstObject = fetchedObjectsFilter.first,
                   let value = firstObject.value(forKey: "value") as? String {
                    let val = "\(value)%"
                    btnValue.setTitle(val, for: .normal)
                }
                let commutablityCity = objcommutability?.city
            }
        }
        catch {
            print("cannot fetch commtablity \(error.localizedDescription)")
        }
    }
}
