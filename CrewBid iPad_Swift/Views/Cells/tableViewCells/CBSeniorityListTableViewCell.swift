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
        NotificationCenter.default.addObserver(self, selector: #selector(menuDidHide), name: UIMenuController.willHideMenuNotification, object: nil)
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
    
    @objc func labelTapped(_ gesture:UITapGestureRecognizer){
        window?.endEditing(true)
        self.becomeFirstResponder()
        guard let label = gesture.view as? UILabel else {return}
        let copyItem = UIMenuItem(title: "Copy", action: #selector(copyText))
        UIMenuController.shared.menuItems = [copyItem]
        UIMenuController.shared.showMenu(from: label, rect: label.bounds)
        let font = UIFont(name: "Courier New Bold", size: 16)
        label.font = font
    }
    
    
    @objc func copyText(){
        UIPasteboard.general.string = self.empNumLbl.text?.replacingOccurrences(of: "[()]", with: "", options: .regularExpression)
        let font = UIFont(name: "Courier New Bold", size: 14)
        self.empNumLbl.font = font
        self.nameLbl.font = font
    }
    
    @objc func menuDidHide(){
        let font = UIFont(name: "Courier New Bold", size: 14)
        self.empNumLbl.font = font
        self.nameLbl.font = font
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
