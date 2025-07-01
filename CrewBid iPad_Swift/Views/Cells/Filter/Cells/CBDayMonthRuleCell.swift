//
//  CBDayMonthRuleCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBDayMonthRuleCell: UITableViewCell {
    var filterRule: BIFilterRule?
    var bidPeriod: BIBidPeriod?
    var calendarData: BICalendarData?
    let context = CBGlobalMethods.shared.selectedBidPeriod?.managedObjectContext
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @IBAction func deleteCellRow(_ sender: Any) {
//        code need to be added here
        self.bidPeriod!.managedObjectContext!.delete(filterRule!)
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
