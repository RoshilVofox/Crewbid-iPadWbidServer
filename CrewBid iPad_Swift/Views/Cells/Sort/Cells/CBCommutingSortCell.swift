//
//  CBCommutingSortCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBCommutingSortCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    
    var lineSort: BILineSort!
    var bidPeriod: BIBidPeriod!
    var context = CBGlobalMethods.shared.selectedBidPeriod?.managedObjectContext
    var outsideFlag: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func CalculateCommutingManualSort() {
        
    }

    @IBAction func btnCloseAction(_ sender: Any) {
        context!.delete(lineSort!)
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
    func calculateSortAfterVacationLoading() {
        
    }
}
