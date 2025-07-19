//
//  CBUserFlagRuleCell.swift
//  CrewBid iPad
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBUserFlagRuleCell: UITableViewCell {
    
        var bidPeriod: BIBidPeriod?
        weak var userFlagControlNoColor: UIControl?
        weak var userFlagControlYellow: UIControl?
        weak var userFlagControlOrange: UIControl?
        weak var userFlagControlRed: UIControl?
        weak var userFlagControlBlue: UIControl?
        weak var userFlagControlGreen: UIControl?
        weak var userFlagControlBrown: UIControl?
        weak var userFlagControlPink: UIControl?
    
        @IBOutlet weak var backView: UIView!
        
        var kUserFlagFilterHorizontalSpacing: CGFloat = 10.0
        var kUserFlagFilterWidthHeight: CGFloat = 35.0
        var kUserFlagFilterX: CGFloat = 50.0
        var kUserFlagFilterY: CGFloat = 11.0
        var bacViewColor: UIColor = .black
        var flagColor: UIColor = .gray
        
        override func awakeFromNib() {
            super.awakeFromNib()
            // Initialization code
            // No Color
            var flagControl: UIControl = CBUserFlagTableController.userFlagControlForColor(color: CBUserFlagTableController.colorForUserFlagType(flagType: CBUserFlagType.none), diameter: kUserFlagFilterWidthHeight)
            flagControl.frame = CGRect(x: kUserFlagFilterX, y: kUserFlagFilterY, width: kUserFlagFilterWidthHeight, height: kUserFlagFilterWidthHeight)
            flagControl.layer.borderWidth = 0.5
            flagControl.layer.borderColor = flagColor.cgColor
            let flagImage: UIView? = flagControl.viewWithTag(kFlagImageTag)
            flagImage?.alpha = 1
            flagControl.addTarget(self, action: #selector(self.buttonAction), for: .touchUpInside)
            contentView.addSubview(flagControl)
            userFlagControlNoColor = flagControl

            //Green
            flagControl = CBUserFlagTableController.userFlagControlForColor(color: CBUserFlagTableController.colorForUserFlagType(flagType: CBUserFlagType.green), diameter: kUserFlagFilterWidthHeight)
            flagControl.frame = CGRect(x: kUserFlagFilterX + 1.0 * (kUserFlagFilterWidthHeight + kUserFlagFilterHorizontalSpacing), y: kUserFlagFilterY, width: kUserFlagFilterWidthHeight, height: kUserFlagFilterWidthHeight)
            flagControl.layer.borderWidth = 0.5
            flagControl.addTarget(self, action: #selector(self.buttonAction), for: .touchUpInside)
            contentView.addSubview(flagControl)
            userFlagControlGreen = flagControl
            
            //Yellow
            flagControl = CBUserFlagTableController.userFlagControlForColor(color: CBUserFlagTableController.colorForUserFlagType(flagType: CBUserFlagType.yellow), diameter: kUserFlagFilterWidthHeight)
            flagControl.frame = CGRect(x: kUserFlagFilterX + 2.0 * (kUserFlagFilterWidthHeight + kUserFlagFilterHorizontalSpacing), y: kUserFlagFilterY, width: kUserFlagFilterWidthHeight, height: kUserFlagFilterWidthHeight)
            flagControl.layer.borderWidth = 0.5
            flagControl.addTarget(self, action: #selector(self.buttonAction), for: .touchUpInside)
            contentView.addSubview(flagControl)
            userFlagControlYellow = flagControl
            
            //Orange
            flagControl = CBUserFlagTableController.userFlagControlForColor(color: CBUserFlagTableController.colorForUserFlagType(flagType: CBUserFlagType.orange), diameter: kUserFlagFilterWidthHeight)
            flagControl.frame = CGRect(x: kUserFlagFilterX + 3.0 * (kUserFlagFilterWidthHeight + kUserFlagFilterHorizontalSpacing), y: kUserFlagFilterY, width: kUserFlagFilterWidthHeight, height: kUserFlagFilterWidthHeight)
            flagControl.layer.borderWidth = 0.5
            flagControl.addTarget(self, action: #selector(self.buttonAction), for: .touchUpInside)
            contentView.addSubview(flagControl)
            userFlagControlOrange = flagControl
            
            //Red
            flagControl = CBUserFlagTableController.userFlagControlForColor(color: CBUserFlagTableController.colorForUserFlagType(flagType: CBUserFlagType.red), diameter: kUserFlagFilterWidthHeight)
            flagControl.frame = CGRect(x: kUserFlagFilterX + 4.0 * (kUserFlagFilterWidthHeight + kUserFlagFilterHorizontalSpacing), y: kUserFlagFilterY, width: kUserFlagFilterWidthHeight, height: kUserFlagFilterWidthHeight)
            flagControl.layer.borderWidth = 0.5
            flagControl.addTarget(self, action: #selector(self.buttonAction), for: .touchUpInside)
            contentView.addSubview(flagControl)
            userFlagControlRed = flagControl
            
            //Blue
            flagControl = CBUserFlagTableController.userFlagControlForColor(color: CBUserFlagTableController.colorForUserFlagType(flagType: CBUserFlagType.blue), diameter: kUserFlagFilterWidthHeight)
            flagControl.frame = CGRect(x: kUserFlagFilterX + 5.0 * (kUserFlagFilterWidthHeight + kUserFlagFilterHorizontalSpacing), y: kUserFlagFilterY, width: kUserFlagFilterWidthHeight, height: kUserFlagFilterWidthHeight)
            flagControl.layer.borderWidth = 0.5
            flagControl.addTarget(self, action: #selector(self.buttonAction), for: .touchUpInside)
            contentView.addSubview(flagControl)
            userFlagControlBlue = flagControl
            
            //Brown
            flagControl = CBUserFlagTableController.userFlagControlForColor(color: CBUserFlagTableController.colorForUserFlagType(flagType: CBUserFlagType.brown), diameter: kUserFlagFilterWidthHeight)
            flagControl.frame = CGRect(x: kUserFlagFilterX + 6.0 * (kUserFlagFilterWidthHeight + kUserFlagFilterHorizontalSpacing), y: kUserFlagFilterY, width: kUserFlagFilterWidthHeight, height: kUserFlagFilterWidthHeight)
            flagControl.layer.borderWidth = 0.5
            flagControl.addTarget(self, action: #selector(self.buttonAction), for: .touchUpInside)
            contentView.addSubview(flagControl)
            userFlagControlBrown = flagControl
            
            //Pink
            flagControl = CBUserFlagTableController.userFlagControlForColor(color: CBUserFlagTableController.colorForUserFlagType(flagType: CBUserFlagType.pink), diameter: kUserFlagFilterWidthHeight)
            flagControl.frame = CGRect(x: kUserFlagFilterX + 7.0 * (kUserFlagFilterWidthHeight + kUserFlagFilterHorizontalSpacing), y: kUserFlagFilterY, width: kUserFlagFilterWidthHeight, height: kUserFlagFilterWidthHeight)
            flagControl.layer.borderWidth = 0.5
            flagControl.addTarget(self, action: #selector(self.buttonAction), for: .touchUpInside)
            contentView.addSubview(flagControl)
            userFlagControlPink = flagControl
            
        }
        

        
        @IBAction func deleteCellRow(_ sender: Any) {
            CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
            CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
            CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
            if (filterRule.ruleHighlightsTrips()) {
                filterRule.highlightTrips()
            }
            self.bidPeriod!.managedObjectContext!.delete(filterRule)
            //CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!.delete(filterRule)
            try? CBGlobalMethods.shared.selectedBidPeriod?.managedObjectContext!.save()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
            }
        }
        
        
        @objc func buttonAction(_ sender: UIControl) {
        sender.isSelected = !sender.isSelected
            let SET = NSMutableSet(capacity: 8)
            if (userFlagControlNoColor?.isSelected)! {
                SET.add(CBUserFlagType.none.rawValue)
            }
            if (userFlagControlYellow?.isSelected)! {
                SET.add(CBUserFlagType.yellow.rawValue)
            }
            if (userFlagControlOrange?.isSelected)! {
                SET.add(CBUserFlagType.orange.rawValue)
            }
            if (userFlagControlRed?.isSelected)! {
                SET.add(CBUserFlagType.red.rawValue)
            }
            if (userFlagControlBlue?.isSelected)! {
                SET.add(CBUserFlagType.blue.rawValue)
            }
            if (userFlagControlGreen?.isSelected)! {
                SET.add(CBUserFlagType.green.rawValue)
            }
            if (userFlagControlBrown?.isSelected)! {
                SET.add(CBUserFlagType.brown.rawValue)
            }
            if (userFlagControlPink?.isSelected)! {
                SET.add(CBUserFlagType.pink.rawValue)
            }
            let dict  = NSDictionary(object: SET, forKey: "SET" as NSCopying)
            filterRule.variables = dict
            try? CBGlobalMethods.shared.selectedBidPeriod?.managedObjectContext!.save()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
            }
        }
        
        
        private var _filterRule: BIFilterRule?
        
        var filterRule: BIFilterRule  {
            get {
                let variables = _filterRule!.variables?["SET"] as! NSSet
                let arrVariables = NSMutableArray(array:variables.allObjects)
                userFlagControlNoColor?.isSelected = arrVariables.contains(CBUserFlagType.none.rawValue)
                userFlagControlYellow?.isSelected = arrVariables.contains(CBUserFlagType.yellow.rawValue)
                userFlagControlOrange?.isSelected = arrVariables.contains(CBUserFlagType.orange.rawValue)
                userFlagControlRed?.isSelected = arrVariables.contains(CBUserFlagType.red.rawValue)
                userFlagControlBlue?.isSelected = arrVariables.contains(CBUserFlagType.blue.rawValue)
                userFlagControlGreen?.isSelected = arrVariables.contains(CBUserFlagType.green.rawValue)
                userFlagControlBrown?.isSelected = arrVariables.contains(CBUserFlagType.brown.rawValue)
                userFlagControlPink?.isSelected = arrVariables.contains(CBUserFlagType.pink.rawValue)
                //code to execute
                return _filterRule!
            }
            set(newValue) {
              //  _filterRule = newValue
                if _filterRule != newValue {
                    _filterRule = newValue
                }
                let variables = newValue.variables?["SET"] as! NSSet
                let arrVariables = NSMutableArray(array:variables.allObjects)
                userFlagControlNoColor?.isSelected = arrVariables.contains(0)
                userFlagControlYellow?.isSelected = arrVariables.contains(4)
                userFlagControlOrange?.isSelected = arrVariables.contains(5)
                userFlagControlRed?.isSelected = arrVariables.contains(3)
                userFlagControlBlue?.isSelected = arrVariables.contains(1)
                userFlagControlGreen?.isSelected = arrVariables.contains(2)
                userFlagControlBrown?.isSelected = arrVariables.contains(6)
                userFlagControlPink?.isSelected = arrVariables.contains(7)
                if userFlagControlNoColor!.isSelected {
                    userFlagControlNoColor?.layer.borderWidth = 3
                } else {
                    userFlagControlNoColor?.layer.borderWidth = 0.5
                }
                if userFlagControlYellow!.isSelected {
                    userFlagControlYellow?.layer.borderWidth = 3
                } else {
                    userFlagControlYellow?.layer.borderWidth = 0.5
                }
                if userFlagControlOrange!.isSelected {
                    userFlagControlOrange?.layer.borderWidth = 3
                } else {
                    userFlagControlOrange?.layer.borderWidth = 0.5
                }
                if userFlagControlRed!.isSelected {
                    userFlagControlRed?.layer.borderWidth = 3
                } else {
                    userFlagControlRed?.layer.borderWidth = 0.5
                }
                if userFlagControlBlue!.isSelected {
                    userFlagControlBlue?.layer.borderWidth = 3
                } else {
                    userFlagControlBlue?.layer.borderWidth = 0.5
                }
                if userFlagControlGreen!.isSelected {
                    userFlagControlGreen?.layer.borderWidth = 3
                } else {
                    userFlagControlGreen?.layer.borderWidth = 0.5
                }
                if userFlagControlBrown!.isSelected {
                    userFlagControlBrown?.layer.borderWidth = 3
                } else {
                    userFlagControlBrown?.layer.borderWidth = 0.5
                }
                if userFlagControlPink!.isSelected {
                    userFlagControlPink?.layer.borderWidth = 3
                } else {
                    userFlagControlPink?.layer.borderWidth = 0.5
                }
            }
        }
        
        let kUserFlagTransparentAlphaValue = 1.0;
    
        override func layoutSubviews() {
            backView.backgroundColor = bacViewColor
            let variables = _filterRule!.variables?["SET"] as! NSSet
            userFlagControlNoColor?.alpha = CGFloat(variables.contains(CBUserFlagType.none.rawValue) ? 1.0 : kUserFlagTransparentAlphaValue)
            userFlagControlYellow?.alpha = CGFloat(variables.contains(CBUserFlagType.yellow.rawValue) ? 1.0 : kUserFlagTransparentAlphaValue)
            userFlagControlOrange?.alpha = CGFloat(variables.contains(CBUserFlagType.orange.rawValue) ? 1.0 : kUserFlagTransparentAlphaValue)
            userFlagControlRed?.alpha = CGFloat(variables.contains(CBUserFlagType.red.rawValue) ? 1.0 : kUserFlagTransparentAlphaValue)
            userFlagControlBlue?.alpha = CGFloat(variables.contains(CBUserFlagType.blue.rawValue) ? 1.0 : kUserFlagTransparentAlphaValue)
            userFlagControlGreen?.alpha = CGFloat(variables.contains(CBUserFlagType.green.rawValue) ? 1.0 : kUserFlagTransparentAlphaValue)
            userFlagControlBrown?.alpha = CGFloat(variables.contains(CBUserFlagType.brown.rawValue) ? 1.0 : kUserFlagTransparentAlphaValue)
            userFlagControlPink?.alpha = CGFloat(variables.contains(CBUserFlagType.pink.rawValue) ? 1.0 : kUserFlagTransparentAlphaValue)
            
            var borderColor: CGColor?
            
            if #available(iOS 13.0, *) {
                borderColor = UIColor.label.withAlphaComponent(0.7).cgColor
            } else {
                borderColor = UIColor.black.withAlphaComponent(0.7).cgColor
            }
            
            self.userFlagControlNoColor?.layer.borderColor = borderColor
            self.userFlagControlYellow?.layer.borderColor = borderColor
            self.userFlagControlOrange?.layer.borderColor = borderColor
            self.userFlagControlRed?.layer.borderColor = borderColor
            self.userFlagControlBlue?.layer.borderColor = borderColor
            self.userFlagControlGreen?.layer.borderColor = borderColor
            self.userFlagControlBrown?.layer.borderColor = borderColor
            self.userFlagControlPink?.layer.borderColor = borderColor
            
            userFlagControlNoColor?.isSelected = variables.contains(CBUserFlagType.none.rawValue)
            userFlagControlYellow?.isSelected = variables.contains(CBUserFlagType.yellow.rawValue)
            userFlagControlOrange?.isSelected = variables.contains(CBUserFlagType.orange.rawValue)
            userFlagControlRed?.isSelected = variables.contains(CBUserFlagType.red.rawValue)
            userFlagControlBlue?.isSelected = variables.contains(CBUserFlagType.blue.rawValue)
            userFlagControlGreen?.isSelected = variables.contains(CBUserFlagType.green.rawValue)
            userFlagControlBrown?.isSelected = variables.contains(CBUserFlagType.brown.rawValue)
            userFlagControlPink?.isSelected = variables.contains(CBUserFlagType.pink.rawValue)
        }
        override func setSelected(_ selected: Bool, animated: Bool) {
            super.setSelected(selected, animated: animated)

            // Configure the view for the selected state
        }

    }
