//
//  CBPresetCell.swift
//  CrewBid iPad_Swift
//
//  Created by Developer on 04/05/25.
//

import UIKit

protocol CBPresetCellDelegate {
    
    func deleteButtonPressed(presetCell: CBPresetCell, indexpath: IndexPath)
    func nameTextFieldEndedEditing(presetCell: CBPresetCell)
    func nameTextFieldBeginEditing()
}

class CBPresetCell: UITableViewCell, UITextFieldDelegate {

    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var loadLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var addButton: UIImageView!
    
    var indexPath: IndexPath!
    var Delegate: CBPresetCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.loadLabel.layer.cornerRadius = 6.0
        self.loadLabel.layer.borderWidth = 3.0
        self.addButton.layer.cornerRadius = self.addButton.frame.height / 2
        self.addButton.layer.masksToBounds = true
        nameTextField.delegate = self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    @IBAction func deletePresetBtnTapped(_ sender: Any) {
        self.Delegate?.deleteButtonPressed(presetCell: self, indexpath: self.indexPath)
    }
    
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.nameTextField.borderStyle = .roundedRect
        return true
    }
    
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
        
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.Delegate?.nameTextFieldBeginEditing()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == self.nameTextField {
            if nameTextField.text == "" {
                CBGlobalMethods.shared.ShowAlert(TitleString: "Warning !", MessageString: "The 'Preset Name' field has taken the default value. You may choose to enter a name of your choice if required.")
            }
            self.nameTextField.backgroundColor = .clear
            if self.Delegate != nil {
                self.Delegate?.nameTextFieldEndedEditing(presetCell: self)
            }
        }
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.endEditing(true)
        textField.resignFirstResponder()
        return true
    }

}
