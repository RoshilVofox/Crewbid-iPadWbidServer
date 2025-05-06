//
//  CBPresetsTVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBPresetsTVC: UIViewController {

    @IBOutlet weak var btnBidListCount: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var textFieldIsEditing = false
    
    struct PresetModel {
        var selected: Int?
        var month: Int?
        var year: Int?
        var presetName: String?
        var presetIdentifier: String?
        var filterSortState: Any?
        var position: String?
        var order: Int?
    }
    
    var array: [PresetModel] = []
    
    let preset1 = PresetModel(
        selected: 1,
        month: 5,
        year: 2025,
        presetName: "",
        presetIdentifier: "preset_001",
        filterSortState: nil, // or some object if you know the type
        position: "Captain",
        order: 1
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsSelectionDuringEditing = true
        self.tableView.setEditing(true, animated: true)
        setupUI()
//
    }
    func setupUI(){
        btnBidListCount.layer.cornerRadius = btnBidListCount.frame.height/2
    }
    @IBAction func btnFilterAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBFilterRulesTableVC") as! CBFilterRulesTableVC
        self.navigationController?.pushViewController(vc, animated: false)
    }
    
    @IBAction func btnSortAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBLineSortsTVC") as! CBLineSortsTVC
        self.navigationController?.pushViewController(vc, animated: false)
    }
    
    @IBAction func btnBidsAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBBidListVC") as! CBBidListVC
        self.navigationController?.pushViewController(vc, animated: false)
        UIView.transition(from: self.view, to: vc.view, duration: 0.65, options: [.transitionFlipFromLeft])
    }
    
    func updatePresets() {
        tableView.reloadData()
    }
    
}


//MARK: delegate part
extension CBPresetsTVC: CBPresetCellDelegate{
    func deleteButtonPressed(presetCell: CBPresetCell, indexpath indexPath: IndexPath) {
        let alert = UIAlertController(title: "Delete Preset?", message: "Tap OK to confirm.", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self = self else { return }

            if indexPath.row < self.array.count {
                self.array.remove(at: indexPath.row)
                self.updatePresets()
            } else {
                print("Error: Index out of bounds")
            }

            UserDefaults.standard.set(true, forKey: kCBIsPresetModified)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        self.updatePresets()
        self.present(alert, animated: true, completion: nil)
    }
    
    func nameTextFieldBeginEditing() {
        self.textFieldIsEditing = true
        self.tableView.setEditing(false, animated: false)
    }

    
    func nameTextFieldEndedEditing(presetCell: CBPresetCell) {
        self.textFieldIsEditing = false
        self.tableView.setEditing(true, animated: false)
        
        guard let indexPath = presetCell.indexPath, indexPath.row < self.array.count else {
            print("Invalid indexPath or index out of bounds")
            return
        }
        var preset = self.array[indexPath.row]
        let text = presetCell.nameTextField.text
        if text == "" {
            preset.presetName = "Preset \(indexPath.row + 1)"
        }
        else {
            preset.presetName = text
        }
        self.array[indexPath.row] = preset  // Update the array with the modified model
//            UserDefaults.standard.set(true, forKey: kCBIsPresetModified)
            self.updatePresets()
    }
}

//MARK: Table view part
extension CBPresetsTVC: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if indexPath.row == self.array.count{
            return false
        }
        return true
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
            return nil
        }
        func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
            return 0.001
        }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle.none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard sourceIndexPath != destinationIndexPath,
              sourceIndexPath.row < array.count,
              destinationIndexPath.row < array.count else {
            return
        }

        let movedItem = array.remove(at: sourceIndexPath.row)
        array.insert(movedItem, at: destinationIndexPath.row)

        // Reload UI or notify if needed
//        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.array.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let presetCell = tableView.dequeueReusableCell(withIdentifier: "presetCell", for: indexPath) as! CBPresetCell
        presetCell.contentView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: presetCell.frame.height)
        if indexPath.row == self.array.count {
            // Preset addinf type cell
            presetCell.nameLabel.text = "New Preset With Current Settings"
            //presetCell.backgroundColor = CBColor.tableViewBackgroundColor()
            let deleteButton = presetCell.contentView.viewWithTag(55)
            deleteButton?.alpha = 0.0
            presetCell.nameTextField.alpha = 0.0
            presetCell.nameLabel.alpha = 1.0
            
            //presetCell.nameLabel.textColor = .black
            // presetCell.nameTextField.textColor = .black
            presetCell.addButton.alpha = 1.0
            presetCell.deleteButton.alpha = 0.0
            presetCell.loadLabel.alpha = 0.0
            
        }
        else {
            // Added preset cell
            let preset = self.array[indexPath.row]
            presetCell.nameLabel.text = preset.presetName
            presetCell.Delegate = self
            presetCell.nameLabel.alpha = 0.0
            presetCell.nameTextField.alpha = 1.0
            presetCell.nameTextField.text = preset.presetName
            presetCell.nameTextField.borderStyle = .none
            presetCell.indexPath = indexPath
            presetCell.loadLabel.alpha = 1
            presetCell.loadLabel.text = "Loaded"
//            if preset.presetIdentifier == self.bidPeriod.loadedPresetIdentifier {
//                presetCell.loadLabel.alpha = 1
//                presetCell.loadLabel.layer.borderColor = CBColor.purpleColor().cgColor
//                presetCell.loadLabel.text = "Loaded"
//            } else {
//                //presetCell.nameLabel.textColor = .black
//                // presetCell.nameTextField.textColor = .black
//                presetCell.loadLabel.alpha = 0.6
//                presetCell.loadLabel.layer.borderColor = CBColor.buttonLightTextColor()?.cgColor
//                //presetCell.loadLabel.textColor = CBColor.buttonLightTextColor()
//                presetCell.loadLabel.text = "Load"
//            }
//            //if justAddedAPreset && indexPath.row == self.array.count - 1 {
//            if justAddedAPreset && lastAddedPresetName == preset.presetName {
//                // set textfield editing
//                presetCell.nameTextField.becomeFirstResponder()
//                justAddedAPreset = false
//                lastAddedPresetName = ""
//            }
            presetCell.addButton.alpha = 0.0
            presetCell.deleteButton.alpha = 1.0
        }
        presetCell.selectionStyle = .none
        return presetCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
//MARK: didSelect
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == array.count {
            self.tableView.setEditing(false, animated: false)
            array.append(preset1)
            updatePresets()
            let newIndexPath = IndexPath(row: self.array.count - 1, section: 0)
            if let cell = tableView.cellForRow(at: newIndexPath) as? CBPresetCell {
//                cell.nameTextField.text = "New Preset"
                cell.nameTextField.becomeFirstResponder() // 👈 show keyboard
            }
        }
    }
    
    
}
//CBFilterRulesTableVC
//CBLineSortsTVC
