

import UIKit
import CoreData

class CBDownloadAlldomicileViewController: UIViewController {
    
    @IBOutlet weak var btnAllPilot: UIButton!
    @IBOutlet weak var btnAllFltAttendat: UIButton!
    @IBOutlet weak var txtMonth: DropDown!
    @IBOutlet weak var txtYear: UITextField!
    @IBOutlet weak var txtUserID: UITextField!
    @IBOutlet weak var btnFirstRound: UIButton!
    @IBOutlet weak var btnSecondRound: UIButton!
    @IBOutlet weak var btnBoth: UIButton!
    @IBOutlet weak var btnCp: UIButton!
    @IBOutlet weak var btnFo: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var btnOk: UIButton!
    
    @IBOutlet weak var btnAtl: UIButton!
    @IBOutlet weak var btnAus: UIButton!
    @IBOutlet weak var btnBna: UIButton!
    @IBOutlet weak var btnBwi: UIButton!
    @IBOutlet weak var btnDal: UIButton!
    @IBOutlet weak var btnDen: UIButton!
    @IBOutlet weak var btHou: UIButton!
    @IBOutlet weak var btnLas: UIButton!
    @IBOutlet weak var btnLax: UIButton!
    @IBOutlet weak var btnMco: UIButton!
    @IBOutlet weak var btnMdw: UIButton!
    @IBOutlet weak var btnOak: UIButton!
    @IBOutlet weak var btnPhx: UIButton!
    @IBOutlet weak var activitySatusData: UILabel!
    
    let selectionColor = UIColor(red: 52/255, green: 61/255, blue: 66/255, alpha:1.0)
    let deSelectionColor = UIColor(red: 212/255, green: 135/255, blue: 14/255, alpha:1.0)
    var arrBase: [String] = []
    var bidPeriodList: [BIBidPeriod]?
    var dataSource = GlobalBidInfo.shared
//    private let viewModel = CBDefaultEmployeeViewModel()
    var tableviewData: [String] = []
    var activityIndicatorData = ""
    var isEmpIDVerified:Bool = false
    var confirmEmpNum:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        txtUserID.delegate = self
        txtUserID.text = UserDefaults.standard.string(forKey: kCBDefaultEmployeeNumberKey)
//        AuthService.shared.checkAuthentication(empID: kCBDefaultEmployeeNumberKey) { [weak self] authResult in
//            guard let self = self else { return }
//            self.view.hideActivityIndicator()
//            self.handleAuthResult(authResult)
//
//        } onFailure: { [weak self] error in
//            guard let self = self else { return }
//            self.view.hideActivityIndicator()
//            self.showAlert(message: error.localizedDescription)
//        }
        
        setUpUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(handleDomicileUpdate(_:)), name: Notification.Name("AllDomicileTableDataUpdate"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(FinishedDownloadingAllDomicileBids), name: Notification.Name("FinishedDownloadingAllDomicileBids"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver("AllDomicileTableDataUpdate")
        NotificationCenter.default.removeObserver("FinishedDownloadingAllDomicileBids")
    }
    
//    MARK: handle Notifications
    @objc func handleDomicileUpdate(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            DispatchQueue.main.async {
                
                if let status = userInfo["status"] as? [String],
                   let activityStatus = userInfo["activityStatus"] as? String {
                    self.tableviewData = status
                    self.activityIndicatorData = activityStatus
                    self.tableView.reloadData()
                    // 👇 Scroll to the last row
                    let lastRow = self.tableviewData.count - 1
                    if lastRow >= 0 {
                        let indexPath = IndexPath(row: lastRow, section: 0)
                        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                    }
                    if self.activityIndicatorData == "" {
                        self.activityIndicator.isHidden = true
                        self.activityIndicator.stopAnimating()
                        self.activitySatusData.isHidden = true
                        
                    }
                    else {
                        self.activityIndicator.isHidden = false
                        self.activitySatusData.isHidden = false
                        self.activityIndicator.startAnimating()
                        self.activitySatusData.text = activityStatus
                    }
                }
            }
        }
    }
    
    @objc func FinishedDownloadingAllDomicileBids() {
        GlobalBidInfo.shared.isCurrentlyDownloadingAllBid = 0
        if GlobalBidInfo.shared.alertCount == 0 {
            AlertService.showAlertForTopVC(title: "Success", message: "All Domicile Bids Downloaded Successfully")
            GlobalBidInfo.shared.alertCount = 1
            checkFlightData()
        }
    }

    func checkFlightData(){
        CBUtils.downloadFlightData(){ (result:Bool?) in
            if result!{
                print("Flight Data downloaded successfully")
            }
        }
    }
    
    func setUpUI(){
        let currentDate = Date()
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: currentDate)
        let currentYear = calendar.component(.year, from: currentDate)
        txtUserID.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: txtUserID.frame.height))
        
        // Determine next month and adjust year if needed
        let nextMonth = currentMonth % 12 + 1
        let nextYear = currentMonth == 12 ? currentYear + 1 : currentYear
        
        // Set txtYear and txtMonth
        txtYear.text = String(nextYear)
        txtMonth.text = String(nextMonth)
        
        // Set dropdown options and selection handler
        txtMonth.optionArray = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"]
        txtMonth.didSelect { (selectedText, index, id) in
            self.txtMonth.text = selectedText
        }
        
        // Select initial buttons and hide the indicator
        
        //        self.selectButton(button: btnAllPilot)
        self.selectButton(button: btnFirstRound)
        //        self.selectButton(button: btnBoth)
        activityIndicator.isHidden = true
        activitySatusData.isHidden = true
    }
    
    func selectButton(button : UIButton){
        button.isSelected = true
        if button.isSelected {
            button.backgroundColor = selectionColor
        }else{
            button.backgroundColor = deSelectionColor
        }
        button.setTitleColor(.white, for: .selected)
        button.setTitleColor(.white, for: .normal)
    }
    // Function to unselect a button
    
    func unselectButton(button : UIButton){
        button.isSelected = false
        if button.isSelected {
            button.backgroundColor = selectionColor
        }else{
            button.backgroundColor = deSelectionColor
        }
        button.setTitleColor(.white, for: .selected)
        button.setTitleColor(.white, for: .normal)
    }
    
    // MARK: - All flt btn
    @IBAction func btnAllFltAttndAction(_ sender: Any) {
        let btnArray: [UIButton] = [btnAtl, btnAus, btnBna, btnBwi, btnDal, btnDen, btHou, btnLas, btnLax, btnMco, btnMdw, btnOak, btnPhx, btnAllFltAttendat]
        
        for btn in btnArray {
            self.selectButton(button: btn)
            self.unselectButton(button: btnAllPilot)
        }
        print(arrBase)
    }
    
    // MARK: - All pilot btn
    @IBAction func btnAllPilotAction(_ sender: Any) {
        let btnArray: [UIButton] = [btnAtl, btnAus, btnBna, btnBwi, btnDal, btnDen, btHou, btnLas, btnLax, btnMco, btnMdw, btnOak, btnPhx, btnAllPilot]
        
        for btn in btnArray {
            self.selectButton(button: btn)
        }
        let btnArray2 : [UIButton] = [btnAllFltAttendat]
        for btn in btnArray2 {
            self.unselectButton(button: btn)
        }
    }
    
    // MARK: -  firstRound btn
    @IBAction func btnFirstRoundAction(_ sender: Any) {
        self.selectButton(button: sender as! UIButton)
        self.unselectButton(button: btnSecondRound)
    }
    
    // MARK: -  Second Round btn
    @IBAction func btnSecondRoundAction(_ sender: Any) {
        self.selectButton(button: sender as! UIButton)
        self.unselectButton(button: btnFirstRound)
    }
    
    @IBAction func btnCancelAction(_ sender: Any) {
        if GlobalBidInfo.shared.isCurrentlyDownloadingAllBid == 1 {
            AlertService.showAlertForTopVC(title: "Warning", message: "Currently downloading all bids. Please wait")
            return
        }
        else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: -  both btn
    @IBAction func btnBothAction(_ sender: Any) {
        self.selectButton(button: sender as! UIButton)
        self.unselectButton(button: btnCp)
        self.unselectButton(button: btnFo)
        self.unselectButton(button: btnAllFltAttendat)
    }
    
    // MARK: -  CP btn
    @IBAction func btnCpAction(_ sender: Any) {
        self.selectButton(button: sender as! UIButton)
        self.unselectButton(button: btnBoth)
        self.unselectButton(button: btnFo)
        self.unselectButton(button: btnAllFltAttendat)
    }
    
    // MARK: -  FO btn
    @IBAction func btnFoAction(_ sender: Any) {
        self.selectButton(button: sender as! UIButton)
        self.unselectButton(button: btnCp)
        self.unselectButton(button: btnBoth)
        self.unselectButton(button: btnAllFltAttendat)
    }
    
    @IBAction func btnBaseSelctionAction(_ sender: Any) {
        guard let button = sender as? UIButton else { return }
        // Toggle selection
        button.isSelected.toggle()
        if button.isSelected {
            self.selectButton(button: sender as! UIButton)
        } else {
            self.unselectButton(button: sender as! UIButton)
        }
    }
    
    func shakeTextField(textField: UITextField){
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 3
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: textField.center.x - 10, y: textField.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: textField.center.x + 10, y: textField.center.y))
        textField.layer.add(animation, forKey: "position")
        textField.attributedPlaceholder = NSAttributedString(string: textField.placeholder ?? "",
                                                             attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
    }
    
    func authChecking() {
        guard let empID = txtUserID.text, !empID.isEmpty else {
            shakeTextField(textField: txtUserID)
            return
        }
        dataSource.employeeNumber = empID
        UserDefaults.standard.set(txtUserID.text!, forKey: kCBDefaultEmployeeNumberKey)
        self.view.showActivityIndicator(color: CBColor.cbPurpleColor, message: "Authentication Checking...")
        AuthService.shared.checkAuthentication(empID: GlobalBidInfo.shared.employeeNumber) { [weak self] authResult in
            guard let self = self else { return }
            self.view.hideActivityIndicator()
            self.handleAuthResult(authResult)

        } onFailure: { [weak self] error in
            guard let self = self else { return }
            self.view.hideActivityIndicator()
            self.showAlert(message: error.localizedDescription)
        }
    }
    
    func handleAuthResult(_ result: AuthResult) {
        let msg = result.message ?? ""
        guard let empID = txtUserID.text else {return}
        if msg == "Invalid Account" || msg == "For security purposes, all users need a CrewBid or WBidMax account.  Go to www.crewbidmax.com and create an account" {
            showAlert(message: "User \(empID) does not have a CrewBid account. Go to www.crewbid.com to create the account.")
        } else if msg == "Subscription Expired" && !result.isSomehowSubscribed {
            showAlert(message: "User \(empID) does not have a valid subscription with Crewbid Account. Please Subscribe.")
        } else if msg.contains("Your subscription to CrewBid has expired.  Go to www.crewbid.com and re-subscribe - Go to crewbid.com") && !result.isSomehowSubscribed {
            showAlert(message: msg)
        } else {
            print("Valid Employee ID")
            self.gotoNextView()
        }
    }
    
    func gotoNextView(){
        UserDefaults.standard.set(txtUserID.text!, forKey: kCBDefaultEmployeeNumberKey)
        let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBCredentialsPageVC") as! CBCredentialsPageVC
        vc.selectedRound = btnFirstRound.isSelected ? 1 : 2
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: -  OK btn
    @IBAction func btnOkAction(_ sender: Any) {
        AppState.shared.isHistoricBid = false
        tableviewData = []
        tableView.reloadData()
        if GlobalBidInfo.shared.isCurrentlyDownloadingAllBid == 1 {
            AlertService.showAlertForTopVC(title: "Warning", message: "Currently downloading all bids. Please wait")
            return
        }
        let btnArray: [UIButton] = [btnAtl, btnAus, btnBna, btnBwi, btnDal, btnDen, btHou, btnLas, btnLax, btnMco, btnMdw, btnOak, btnPhx]
        arrBase = []
//        setting the selected bases to an array
        var dictionary = GlobalBidInfo.shared.allDomicileDownloadDictionary
        for btn in btnArray {
            if btn.isSelected{
                if let title = btn.title(for: .normal) {
                    arrBase.append(title)
                }
            }
        }
        if arrBase.count == 0 {
            AlertService.showAlertForTopVC(title: "Error", message: "Please select atleast one base")
            return
        }
        if btnAllPilot.isSelected == true {
            if btnCp.isSelected == false && btnFo.isSelected == false && btnBoth.isSelected == false {
                AlertService.showAlertForTopVC(title: "Error", message: "Please select atleast one pilot position")
                return
            }
        }
        if txtUserID.text!.isEmpty {
            AlertService.showAlertForTopVC(title: "Error", message: "Enter Employee number")
        }
        if (txtYear.text!.isEmpty && txtMonth.text!.isEmpty){
            AlertService.showAlertForTopVC(title: "Error", message: "Please enter Month and year")
        }
        print(arrBase)
        self.view.showActivityIndicator(color: CBColor.cbPurpleColor, message: "deleting...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let context = CoreDataManager.shared.managedObjectContext
            let fetchRequest: NSFetchRequest<BIBidPeriod> = BIBidPeriod.fetchRequest()
            
            do {
                let bidPeriods = try context.fetch(fetchRequest)
                
                for obj in bidPeriods {
                    self.dataSource.month = (obj.month as? Int)!
                    self.dataSource.base = obj.base!
                    self.dataSource.round = (obj.round as? Int)!
                    let rawValue = obj.positionType!.intValue
                    self.dataSource.position = BICrewPositionType(rawValue: rawValue)!
                    
                    let fileManager = FileManager.default
                    let bidDocURL = BIBidInfo().bidDocumentFileURL()
                    if fileManager.fileExists(atPath: bidDocURL.path) {
                        do {
                            try fileManager.removeItem(at: bidDocURL)
                            print("Deleted bid document: \(bidDocURL.lastPathComponent)")
                        } catch {
                            print("Failed to delete bid document: \(error.localizedDescription)")
                        }
                    }
                    
                    // Build file path
                    let tempDir = BIBidInfo.temporaryDirectory()
                    let originalFileName = BIBidInfo.shared.bidDataFilename()
                    let fileNameWithoutSuffix: String
                    if let range = originalFileName.range(of: ".737", options: .backwards) {
                        fileNameWithoutSuffix = String(originalFileName[..<range.lowerBound])
                    } else {
                        fileNameWithoutSuffix = originalFileName
                    }
                    let fileURL = tempDir.appendingPathComponent(fileNameWithoutSuffix)
                    
                    // Delete the file if it exists
                    if fileManager.fileExists(atPath: fileURL.path) {
                        do {
                            try fileManager.removeItem(at: fileURL)
                            print("✅ Deleted file: \(fileURL.lastPathComponent)")
                        } catch {
                            print("❌ Failed to delete file: \(error.localizedDescription)")
                        }
                    }
                    context.delete(obj)
                }
                
                try context.save() // Save changes to persist deletion
                print("Successfully deleted all BIBidPeriod records.")
                NotificationCenter.default.post(name: NSNotification.Name("ReloadCollectionView"), object: nil)
                DispatchQueue.main.async {
                    self.view.hideActivityIndicator()
                }
                //                    view.hideActivityIndicator()
                self.bidPeriodList = []
            } catch {
                print("Failed to delete BIBidPeriod records: \(error)")
            }
            var position: BICrewPositionType = .FlightAttendant
            GlobalBidInfo.shared.position = .FlightAttendant
            if self.btnCp.isSelected {
                position = .Captain
                GlobalBidInfo.shared.position = .Captain
            }
            else if self.btnFo.isSelected {
                position = .FirstOfficer
                GlobalBidInfo.shared.position = .FirstOfficer
            }
            else if self.btnBoth.isSelected {
                position = .FirstOfficer
                GlobalBidInfo.shared.position = .FirstOfficer
            }
            
            dictionary["position"] = position
            if self.btnFirstRound.isSelected {
                dictionary["round"] = 1
                GlobalBidInfo.shared.round = 1
            }
            if self.btnSecondRound.isSelected {
                dictionary["round"] = 2
                GlobalBidInfo.shared.round = 2
            }
            dictionary["month"] = Int(self.txtMonth.text!)
            GlobalBidInfo.shared.month = Int(self.txtMonth.text!) ?? 0
            dictionary["bases"] = self.arrBase
            GlobalBidInfo.shared.base = self.arrBase[0]
            dictionary["year"] = Int(self.txtYear.text!)
            if self.btnBoth.isSelected == true {
                dictionary["both"] = true
            }
            else {
                dictionary["both"] = false
            }
            GlobalBidInfo.shared.employeeNumber = self.txtUserID.text!
            print(dictionary)
            UserDefaults.standard.set(true, forKey: "isSecretForAllDomicileDownloadEnabled")
            GlobalBidInfo.shared.allDomicileDownloadDictionary = dictionary
            self.authChecking()
        }
        
        
    }
    func showAlert(message: String) {
        let alert = AlertService.showAlert(title: "CrewBid",message: message,actions: [(title: "Go to crewbid.com", style: .default, handler: { _ in
            if let url = URL(string: "http://www.crewbid.com/") {
                UIApplication.shared.open(url, options: [:])
            }
        }),(title: "Cancel", style: .cancel, handler: nil)])
        self.present(alert, animated: true)
    }
}

extension CBDownloadAlldomicileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableviewData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BulkDownloadStatusCell", for: indexPath) as! BulkDownloadStatusCell
        cell.dataStatusLabel.text = tableviewData[indexPath.row]
        return cell
    }
    
    
}

extension CBDownloadAlldomicileViewController : UITextFieldDelegate{
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == txtUserID {
            // Limit characters to 7
            let currentText = textField.text ?? ""
            let prospectiveText = (currentText as NSString).replacingCharacters(in: range, with: string)
            if prospectiveText.count > 7 {
                textField.shakeTextField() // Exceeds length limit
                return false
            }
            let allowedCharacters = CharacterSet(charactersIn: "0123456789") // Modify if needed
            let characterSet = CharacterSet(charactersIn: string)
            
            if !allowedCharacters.isSuperset(of: characterSet) {
                textField.shakeTextField() // Disallowed characters
                return false
            }
            return true
        }
        return true
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        guard let empID = txtUserID.text, !empID.isEmpty else {
            showAlert(message: "Please enter a valid employee number.")
            return false
        }
//        AuthService.shared.checkAuthentication(empID: empID) { [weak self] authResult in
//            guard let self = self else { return }
//            self.view.hideActivityIndicator()
//
//            if authResult.isSomehowSubscribed {
//                self.isEmpIDVerified = true
//                self.confirmEmpNum = empID
//                self.handleAuthResult(authResult) // existing method
//            } else {
//                let alert = AlertService.showAlert(
//                    title: "Authentication Failed",
//                    message: authResult.message ?? "You are not subscribed or authorized.",
//                    actions: nil
//                )
//                self.present(alert, animated: true)
//            }
//
//        } onFailure: { [weak self] error in
//            guard let self = self else { return }
//            self.view.hideActivityIndicator()
//            self.showAlert(message: error.localizedDescription)
//        }
        return true
    }
    
}
