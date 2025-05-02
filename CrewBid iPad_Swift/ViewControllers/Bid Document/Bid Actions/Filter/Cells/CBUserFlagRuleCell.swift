//
//  CBUserFlagRuleCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBUserFlagRuleCell: UITableViewCell,CBFilterRuleCellDelegateAssignable {
    weak var delegate: CBFilterRuleCellDelegate?
    
    
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

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func deleteCellRow(_ sender: Any) {
        delegate?.deleteCellRow(in: self)
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
