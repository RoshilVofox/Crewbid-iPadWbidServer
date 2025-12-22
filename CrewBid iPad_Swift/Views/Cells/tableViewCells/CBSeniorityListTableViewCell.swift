//
//  CBSeniorityListTableViewCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 22/12/25.
//

import UIKit

class CBSeniorityListTableViewCell: UITableViewCell {

    @IBOutlet weak var baseSeniorityLbl: UILabel!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var vacationLbl: UILabel!
    @IBOutlet weak var empNumLbl: UILabel!
    @IBOutlet weak var vacationTop: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.empNumLbl.isUserInteractionEnabled = true
        self.nameLbl.isUserInteractionEnabled = true
        
        let nameTapGesture = UITapGestureRecognizer(target: self, action: #selector(labelTapped))
        let empNumTapGesture = UITapGestureRecognizer(target: self, action: #selector(labelTapped))
        self.empNumLbl.addGestureRecognizer(empNumTapGesture)
        self.nameLbl.addGestureRecognizer(nameTapGesture)
        
        let font = UIFont(name: "Courier New Bold", size: 14)
        self.empNumLbl.font = font
        self.nameLbl.font = font
        self.vacationLbl.font = font
        self.baseSeniorityLbl.font = font
        
    }
    
    @objc func labelTapped(_ gesture:UILongPressGestureRecognizer){
//        self.becomeFirstResponder()
//        let label = gesture.view as! UILabel
//        let copyItem = UIMenuItem(title: "Copy", action: #selector(copyText))
//        UIMenuController().menuItems = [copyItem]
//        UIMenuController().showMenu(from: label, rect: label.bounds)
//
//        let font = UIFont(name: "Courier New Bold", size: 15)
//        label.font = font
        
    }
    
    @objc func copyText(){
        
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
