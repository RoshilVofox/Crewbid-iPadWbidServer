//
//  CBUserFlagRuleCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBUserFlagRuleCell: UITableViewCell {
    
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
    var bidPeriod: BIBidPeriod?
    
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
    }
}
