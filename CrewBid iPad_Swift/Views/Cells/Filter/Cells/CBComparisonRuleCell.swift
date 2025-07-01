//
//  CBComparisonRuleCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBComparisonRuleCell: UITableViewCell {
    
    @IBOutlet weak var comparisonButton: UIButton!
    @IBOutlet weak var valueButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var deletButton: UIButton!
    
    var filterRule: BIFilterRule?
    var modeTexttColor: UIColor = .gray
    var context = CBGlobalMethods.shared.selectedBidPeriod?.managedObjectContext
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @IBAction func showValueOptions(_ sender: Any) {
    }
    
    @IBAction func showComparisonOptions(_ sender: Any) {
    }
    
    @IBAction func deleteCellRow(_ sender: Any) {
        //        code need to be added here
        context!.delete(filterRule!)
        do {
            try context?.save()
        }
        catch {
            print("Error deleting object \(error.localizedDescription)")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }
        
    }
}
