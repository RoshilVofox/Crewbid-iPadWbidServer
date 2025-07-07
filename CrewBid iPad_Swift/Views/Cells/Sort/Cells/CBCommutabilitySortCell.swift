//
//  CBCommutabilitySortCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBCommutabilitySortCell: UITableViewCell {
    
    var lineSort1: BILineSort!
    var context = CBGlobalMethods.shared.selectedBidPeriod?.managedObjectContext
    
    var lineSort: BILineSort? {
        set(newLineSort){
           lineSort1 = newLineSort
        }
        get {
            return lineSort1
        }
    }

    @IBOutlet weak var btnTitle: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configurecommutabilitySortCell() {
        
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
}
