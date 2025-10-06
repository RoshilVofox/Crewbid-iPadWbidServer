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
            
            var variables: Set<NSNumber> = NSSet() as! Set<NSNumber>
            if let value = filterRule.variables?["SET"] {
                if let set = value as? NSSet {
                    variables = set as! Set<NSNumber>
                } else if let array = value as? [Any] {
                    variables = NSSet(array: array) as! Set<NSNumber>
                } else {
                    print("Unexpected type:", type(of: value))
                }
            }
            
            
            amLinesButton.isSelected = variables.contains(NSNumber(value: BILineAMPM.AMLine.rawValue)) ? true : false
            pmLinesButton.isSelected = variables.contains(NSNumber(value: BILineAMPM.PMLine.rawValue)) ? true : false
            mixedAmPmLinesButton.isSelected = variables.contains(NSNumber(value: BILineAMPM.MixedAMPMLine.rawValue)) ? true : false
            redEyeLinesButton.isSelected = variables.contains(NSNumber(value: BILineAMPM.RedEyeAMPMLine.rawValue)) ? true : false
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
