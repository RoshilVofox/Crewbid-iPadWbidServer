//
//  CBPositionRuleCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBPositionRuleCell: UITableViewCell {

    @IBOutlet weak var positionAButton: CBBorderToggleButton!
    @IBOutlet weak var positionBButton: CBBorderToggleButton!
    @IBOutlet weak var positionCButton: CBBorderToggleButton!
    @IBOutlet weak var positionDButton: CBBorderToggleButton!
    @IBOutlet weak var positionMButton: CBBorderToggleButton!
    
    var bidPeriod: BIBidPeriod?
    var buttonTextColor: UIColor = .white
    
    var filterRule: BIFilterRule? {
        didSet {
            guard let filterRule = filterRule else { return }

            if let variables = filterRule.variables!["SET"] as? Set<Int> {
                positionAButton.isSelected = variables.contains(BIFaPosition.FaPositionA.rawValue)
                positionBButton.isSelected = variables.contains(BIFaPosition.FaPositionB.rawValue)
                positionCButton.isSelected = variables.contains(BIFaPosition.FaPositionC.rawValue)
                positionDButton.isSelected = variables.contains(BIFaPosition.FaPositionD.rawValue)
                positionMButton.isSelected = variables.contains(BIFaPosition.FaPositionMultiple.rawValue)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if bidPeriod?.isFirstRoundBid() == true {
            positionMButton.isHidden = true
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func buttonAction(_ sender: CBBorderToggleButton) {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        sender.isSelected = !sender.isSelected
        let SET = NSMutableSet()
        if positionAButton.isSelected {
            SET.add(BIFaPosition.FaPositionA.rawValue)
        }
        if positionBButton.isSelected {
            SET.add(BIFaPosition.FaPositionB.rawValue)
        }
        if positionCButton.isSelected {
            SET.add(BIFaPosition.FaPositionC.rawValue)
        }
        if positionDButton.isSelected {
            SET.add(BIFaPosition.FaPositionD.rawValue)
        }
        if positionMButton.isSelected {
            SET.add(BIFaPosition.FaPositionMultiple.rawValue)
        }
        // Always include this to keep NA lines from getting filtered out
        SET.add(BIFaPosition.FaPositionNA.rawValue)
        let dict = NSDictionary(object: SET, forKey: "SET" as NSCopying)
        filterRule?.variables = dict
        try? CBGlobalMethods.shared.selectedBidPeriod?.managedObjectContext!.save()
        DispatchQueue.main.asyncAfter(deadline: .now()+0.1){
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }
    }
}
