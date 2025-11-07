//
//  SwitchTableViewCell.swift
//  CrewBid iPad_Swift
//
//  Created by Developer on 21/04/25.
//

import UIKit

class SwitchTableViewCell: UITableViewCell {

    @IBOutlet weak var `switch`: UISwitch!
    @IBOutlet weak var lblTitle: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
//        if UserDefaults.standard.bool(forKey: kCBIncludeDroppedTripsInProcessingKey){
//            self.switch.isOn = true
//        }else{
//            self.switch.isOn = false
//        }  
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
