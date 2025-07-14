//
//  CBAmPmRuleCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBAmPmRuleCell: UITableViewCell {
    
    @IBOutlet weak var amLinesButton: CBBorderToggleButton!
    @IBOutlet weak var pmLinesButton: CBBorderToggleButton!
    @IBOutlet weak var mixedAmPmLinesButton: CBBorderToggleButton!
    @IBOutlet weak var redEyeLinesButton: CBBorderToggleButton!
    var buttonTextColor: UIColor = .white
    var bidPeriod: BIBidPeriod?
    
    var filterRule: BIFilterRule? {
        didSet {
            guard let filterRule = filterRule else { return }
            

            if let variables = filterRule.variables!["SET"] as? Set<NSNumber> {
                amLinesButton.isSelected = variables.contains(NSNumber(value: BILineAMPM.AMLine.rawValue))
                pmLinesButton.isSelected = variables.contains(NSNumber(value: BILineAMPM.PMLine.rawValue))
                mixedAmPmLinesButton.isSelected = variables.contains(NSNumber(value: BILineAMPM.MixedAMPMLine.rawValue))
                redEyeLinesButton.isSelected = variables.contains(NSNumber(value: BILineAMPM.RedEyeAMPMLine.rawValue))
            } else {
                // Reset buttons if variables is nil
                amLinesButton.isSelected = false
                pmLinesButton.isSelected = false
                mixedAmPmLinesButton.isSelected = false
                redEyeLinesButton.isSelected = false
            }
        }
    }


    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.bidPeriod = CBGlobalMethods.shared.selectedBidPeriod!
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBAction func buttonsAction(_ sender: CBBorderToggleButton) {
        self.bidPeriod?.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        sender.isSelected = !sender.isSelected
        let SET = NSMutableSet()
        if amLinesButton.isSelected {
            SET.add(BILineAMPM.AMLine.rawValue)
        }
        if pmLinesButton.isSelected {
            SET.add(BILineAMPM.PMLine.rawValue)
        }
        if mixedAmPmLinesButton.isSelected {
            SET.add(BILineAMPM.MixedAMPMLine.rawValue)
        }
        if redEyeLinesButton.isSelected {
            SET.add(BILineAMPM.RedEyeAMPMLine.rawValue)
        }
        // Always include this to keep the blank lines from getting filtered out
        SET.add(BILineAMPM.BlankAMPMLine.rawValue)
        let dict = NSDictionary(object: SET, forKey: "SET" as NSCopying)
        filterRule?.variables = dict
        try? CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!.save()
        DispatchQueue.main.asyncAfter(deadline: .now()+0.1){
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }
    }
    
}
