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
        self.tableView.setEditing(true, animated: true)
        setupUI()
        NotificationCenter.default.addObserver(self, selector: #selector(updateBidListCount), name: NSNotification.Name("updateBidListCount"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updatePresets), name: NSNotification.Name("refreshLines"), object: nil)
        CBGlobalMethods.shared.isSortAvailable = false
    }
    
    func setupUI(){
        btnBidListCount.layer.cornerRadius = btnBidListCount.frame.height/2
        updateBidListCount()
    }
    
    @objc func updateBidListCount(){
        var linesArray : [BILine] = []
        for case let line as BILine in CBGlobalMethods.shared.selectedBidPeriod!.lines! {
            linesArray.append(line)
        }
        var array : [NSPredicate] = []
        array.append(NSPredicate(format: "bidOrder > %@", NSNumber(integerLiteral: 0)))
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: array)
        linesArray = (linesArray as NSArray).filtered(using: predicate) as! [BILine]
        DispatchQueue.main.async {
            self.btnBidListCount.setTitle("\(linesArray.count)", for: .normal)
        }
    }
    
    @IBAction func btnFilterAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBFilterRulesTableVC") as! CBFilterRulesTableVC
        self.navigationController?.pushViewController(vc, animated: false)
    }
    
    @IBAction func btnSortAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBLineSortsTVC") as! CBLineSortsTVC
//        vc.bidPeriod = self.bidPeriod
        self.navigationController?.pushViewController(vc, animated: false)
    }
    
    @IBAction func btnBidsAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBBidListVC") as! CBBidListVC
        self.navigationController?.pushViewController(vc, animated: false)
        UIView.transition(from: self.view, to: vc.view, duration: 0.65, options: [.transitionFlipFromLeft])
    }
    
    
    @IBAction func btnBidListCountAction(_ sender: Any) {
    }
    
    
    @objc func updatePresets() {
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
    
    class func selectedPresetName(bidPeriod: BIBidPeriod) -> String? {
        guard let presets = self.openPresetsFromFile(bidPeriod: bidPeriod) as? [Any] else {
            return nil
        }

        let selectedPresets = presets.filter {
            if let dict = $0 as? [String: Any],
               let presetIdentifier = dict["presetIdentifier"] as? String {
                return presetIdentifier == bidPeriod.loadedPresetIdentifier
            } else if let preset = $0 as? CBPreset {
                return preset.presetIdentifier == bidPeriod.loadedPresetIdentifier
            }
            return false
        }

        if let selected = selectedPresets.first {
            if let dict = selected as? [String: Any] {
                return dict["name"] as? String
            } else if let preset = selected as? CBPreset {
                return preset.name
            }
        }

        return nil
    }
    
    class func openPresetsFromFile(bidPeriod: BIBidPeriod) -> NSMutableArray {
        let filePath = self.presetsDocumentFilePath(bidPeriod: bidPeriod)
        var presets = NSMutableArray()

        if let result = FileManager.default.contents(atPath: filePath) {
            do {
                if let unarchived = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSMutableArray.self, CBPresetFilterRule.self], from: result) as? NSMutableArray {
                        presets = unarchived
                        print(presets, result as NSData)
                    }
            } catch {
                print("Unarchive error: \(error.localizedDescription)")

                let systemVersion = UIDevice.current.systemVersion
                if systemVersion.compare("16.0.0", options: .numeric) != .orderedAscending {
                    DispatchQueue.main.async {
                        let defaults = UserDefaults.standard
                        if defaults.string(forKey: "iOS16PresetSavedToServer") != "YES" {
//                            if result != nil {
                                self.saveiOS16PresetsToServer(with: result)
//                            }
                        }
                        self.getCrashedPresetFromServer(bidPeriod: bidPeriod)
                    }
                }
            }
        }

        return presets
    }
    
    static func getCrashedPresetFromServer(bidPeriod: BIBidPeriod) {

        var dicInfo: [String: Any] = [:]
        let employeeNumber = CBGlobalMethods.shared.employeeNumber ?? ""
        dicInfo["EmployeeNumber"] = employeeNumber
        dicInfo["PresetFileName"] = "\(employeeNumber).json"

        guard let url = URL(string: "http://www.wbidmax.com:8000/WBidDataDwonloadAuthService.svc/GetCrashedCBPresetFromServer") else { return }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dicInfo, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            urlRequest.httpBody = jsonString.data(using: .utf8)
        } catch {
            print("Failed to encode JSON: \(error.localizedDescription)")
            return
        }

        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            guard let data = data, error == nil else {
                print("Network error: \(error?.localizedDescription ?? "unknown")")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Bad HTTP response")
                return
            }

            do {
                guard let res = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? [String: Any] else { return }
                print("Server response:", res)

                if let presetContent = res["PresetContent"] as? [Any] {
                    let count = presetContent.count
                    var bytes = [UInt8]()
                    
                    for item in presetContent {
                        if let str = item as? String, let intVal = Int(str) {
                            bytes.append(UInt8(intVal))
                        }
                    }

                    let byteData = Data(bytes)
                    
                    if let jsonArray = try JSONSerialization.jsonObject(with: byteData, options: .mutableLeaves) as? [Any], !jsonArray.isEmpty {
                        let plistData = try NSKeyedArchiver.archivedData(withRootObject: jsonArray, requiringSecureCoding: false)
                        
                        let presetPath = CBPresetsTVC.presetsDocumentFilePath(bidPeriod: bidPeriod)
                        try plistData.write(to: URL(fileURLWithPath: presetPath), options: .atomic)

                        let presetFilename = String(Int(employeeNumber) ?? 0)
                        let namedPath = CBPresetsTVC.presetsDocumentFilePath(withFileName: presetFilename)
                        try plistData.write(to: URL(fileURLWithPath: namedPath), options: .atomic)

                        DispatchQueue.main.async {
                            UserDefaults.standard.set(false, forKey: kCBIsPresetModified)
                            NotificationCenter.default.post(name: Notification.Name("presetSynched"), object: self)
//                            NotificationCenter.default.post(name: Notification.Name(kCBPresetSyncReload), object: self)
                        }
                    }
                } else {
//                    self.sendMailForUnConvertedFile()
                }
            } catch {
                print("Parsing error: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    class func presetsDocumentFilePath(withFileName presetFileName: String) -> String {
        let presetsDirectoryURL = self.presetsDocumentDirectory()
        let presetsDocumentURL = presetsDirectoryURL!.appendingPathComponent(presetFileName)
        return presetsDocumentURL.path
    }
    
    
    class func presetsDocumentFilePath(bidPeriod: BIBidPeriod) -> String {
        let isConversion = UserDefaults.standard.bool(forKey: "isConversion")
        let presetsDirectoryURL = self.presetsDocumentDirectory()

        if isConversion {
            let presetsFilename = CBPresetsTVC.presetsFilename(with: bidPeriod)
            let presetsDocument = presetsDirectoryURL!.appendingPathComponent(presetsFilename).path
            return presetsDocument
        } else {
            let empNum = CBGlobalMethods.shared.employeeNumber
            let presetsFilename = empNum!
            let presetsDocument = presetsDirectoryURL!.appendingPathComponent(presetsFilename).path
            return presetsDocument
        }
    }
    
    static func saveiOS16PresetsToServer(with data: Data) {
        var dicInfo: [String: Any] = [:]

        let employeeNumber = CBGlobalMethods.shared.employeeNumber ?? ""
        dicInfo["EmployeeNumber"] = employeeNumber
        dicInfo["PresetFileName"] = "\(employeeNumber).plist"

        let bytes = [UInt8](data)
        let resArr = bytes.map { NSNumber(value: $0) }
        dicInfo["PresetContent"] = resArr

        guard let url = URL(string: "http://www.wbidmax.com:8000/WBidDataDwonloadAuthService.svc/SaveCrashedPresetToServer") else { return }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dicInfo, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            urlRequest.httpBody = jsonString.data(using: .utf8)
        } catch {
            print("Error creating JSON: \(error.localizedDescription)")
            return
        }

        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown")")
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                do {
                    if let res = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? [String: Any] {
                        UserDefaults.standard.setValue("YES", forKey: "iOS16PresetSavedToServer")
                        print(res)
                    }
                } catch {
                    print("Failed to parse response JSON: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    
    class func presetsFilename(with bidPeriod: BIBidPeriod) -> String {
        if bidPeriod.isFABid() {
            return "CrewBidFAPresets.plist"
        } else if bidPeriod.isSecondRoundBid() {
            return "CrewBidRound2Presets.plist"
        } else {
            return "CrewBidPilotPresets.plist"
        }
    }
    
    class func presetsDocumentDirectory() -> URL? {
        // Presets directory URL
        let documentsDirectory = BIBidInfo.shared.documentsDirectory()
        
        
        let presetsURL = documentsDirectory.appendingPathComponent("Presets")
        let fileManager = FileManager.default

        do {
            try fileManager.createDirectory(at: presetsURL, withIntermediateDirectories: true, attributes: nil)
            return presetsURL
        } catch {
            // You can handle or log the error here if needed
            // e.g., BIBidInfoError.setError(...)
            return nil
        }
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
