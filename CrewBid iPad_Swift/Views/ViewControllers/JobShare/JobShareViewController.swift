//
//  JobShareViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Rishad on 17/05/25.
//

import UIKit
import CoreData

class JobShareViewController: BaseViewController {
    @IBOutlet weak var txtJobShare1: UITextField!
    @IBOutlet weak var txtJobShare2: UITextField!
    @IBOutlet weak var btnCheckBox: UIButton!
    @IBOutlet weak var domicileLbl: UILabel!
    @IBOutlet weak var empNameLbl: UILabel!
    
    var jobShare1BuddyList:[String]!
    var jobShare2BuddyList:[String]!
    var dict:[String:Any]!
    var buddy1ListDownloadedFor:String!
    var buddy2ListDownloadedFor:String!
    var selectedObject: [String: Any] = [:]
    
    var isChecked: Bool = false
    var bidPeriod = BIBidPeriod()
    var FAListDict:[String:Any]? = nil
    
    private var isPresentingInvalidTokenAlert = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dict = CBUtils.readJSONString(fromFile: "falistwb4.json")
        setupUI()
        NotificationCenter.default.addObserver(self,
            selector: #selector(handleAuthFlowEnded),
            name: Notification.Name("AuthFlowEnded"),
            object: nil)
//        self.writeInvalidTokenToKeychainForTests()
    }
    
//    func writeInvalidTokenToKeychainForTests() {
//        let tokenString = "invalid-token-for-testing"
//        guard let data = tokenString.data(using: .utf8) else { return }
//
//        let query: [String: Any] = [
//            kSecClass as String: kSecClassGenericPassword,
//            kSecAttrAccount as String: "BearerToken"
//        ]
//        // delete old
//        SecItemDelete(query as CFDictionary)
//        // add new bad token
//        var addQuery = query
//        addQuery[kSecValueData as String] = data
//        let status = SecItemAdd(addQuery as CFDictionary, nil)
//        if status == errSecSuccess {
//            print("WROTE INVALID TOKEN (TEST).")
//        } else {
//            print("FAILED writing invalid token: \(status)")
//        }
//    }
    
    
    func setupUI() {
        txtJobShare1.text = self.bidPeriod.bidByEmpID ?? ""
        txtJobShare1.isEnabled = false
        txtJobShare1.isUserInteractionEnabled = false
        txtJobShare1.textColor = UIColor.darkGray
//        txtJobShare2.becomeFirstResponder()
        txtJobShare2.delegate = self
        txtJobShare2.returnKeyType = .done
        btnCheckBox.setTitle("", for: .normal)
        empNameLbl.isHidden = true
        domicileLbl.isHidden = true
        FAListDict = CBUtils.readJSONStringFromFile()
        
        txtJobShare2.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
    }
    
    @objc private func handleAuthFlowEnded() {
        self.isPresentingInvalidTokenAlert = false
    }

    @IBAction func btnOkAction(_ sender: Any) {
        self.validateTextFields()
    }
    
    @IBAction func btnClearFeildsAction(_ sender: Any) {
        txtJobShare2.text = ""
    }
    
    @IBAction func btnCancelAction(_ sender: Any) {
        navigationController?.popViewController(animated: false)
        
    
    }

    
    @IBAction func btnBackAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnChekboxAction(_ sender: Any) {
        isChecked.toggle()  // Shorter toggle syntax

        let imageName = isChecked ? "checkmark.square" : "unCheckBox"
        let checkBoxImage = UIImage(systemName: imageName)
        btnCheckBox.setBackgroundImage(nil, for: .normal)
        btnCheckBox.setBackgroundImage(checkBoxImage, for: .normal)
    }
    
    func employeeContainsInFALISTForDomicile() -> Bool {

        let base = self.bidPeriod.base

        // First buddy dictionary
        let buddy2Dict = dict[self.txtJobShare2.text ?? ""] as? [String:Any]
        let empDomicile2 = buddy2Dict?["Domicile"] as? String

        // Validate Job Share 2 Domicile
        guard let empDomicile2 = empDomicile2 else {
            self.txtJobShare2.shakeTextField()
            return false
        }

        if empDomicile2 == base {
            return true
        } else {
            AlertService.showAlertForTopVC(title: "Job Share", message: "Job Share 2 NOT in \(base ?? "")")
            return false
        }
    }
    
    func validateTextFields() {
        guard isValidEmployeeNumber(txtJobShare1.text ?? "") else {
            txtJobShare1.shakeTextField()
            return
        }

        guard isValidEmployeeNumber(txtJobShare2.text ?? "") else {
            txtJobShare2.shakeTextField()
            return
        }

        guard employeeContainsInFALISTForDomicile() else {
            return
        }
        self.performBuddyListValidationFlow()
    }
    
    func performBuddyListValidationFlow() {

        let id1 = txtJobShare1.text ?? ""
        let id2 = txtJobShare2.text ?? ""
        
        var userList: [String] = []

        if buddy1ListDownloadedFor != id1 && !id1.isEmpty {
            userList.append(id1)
        }

        if buddy2ListDownloadedFor != id2 && !id2.isEmpty {
            userList.append(id2)
        }
        
        self.view.showActivityIndicator(message: "Validating Buddies...")

        if userList.isEmpty {
            
            self.view.hideActivityIndicator()
            validateBuddies()
            return
        }

        var pending = userList.count


        for userID in userList {

            downloadBuddies(userID: userID) { success in

                if !success {
                    DispatchQueue.main.async { self.view.hideActivityIndicator() }
                    return
                }
                
                if userID == id1 {
                    self.buddy1ListDownloadedFor = id1
                }
                if userID == id2 {
                    self.buddy2ListDownloadedFor = id2
                }

                pending -= 1
                if pending == 0 {
                    DispatchQueue.main.async {
                        self.view.hideActivityIndicator()
//                        self.validateBuddiesAndSubscription()
                        self.validateBuddies()
                    }
                }
            }
        }
    }
/*
    func checkSubscriptionFor(completion: @escaping (_ outputString: String, _ success: Bool) -> Void) {

        let emp1 = self.txtJobShare1.text ?? ""
        let emp2 = self.txtJobShare2.text ?? ""

        var employees: [[String: Any]] = []

        if emp1.count >= 2 {
            employees.append(["Password": "", "EmpNumber": emp1])
        }
        if emp2.count >= 2 {
            employees.append(["Password": "", "EmpNumber": emp2])
        }

        if employees.isEmpty {
            completion("", true)
            return
        }

        let params: [String: Any] = [
            "Platform": "iPad",
            "EmployeeNumbers": employees
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: params) else {
            completion("", true)
            return
        }

//        self.view.showActivityIndicator(message: "Checking Subscription...")

        APIService.shared.fetch(
            urlString: EndPoint.shared.checkValidSubscriptionForEmployeesRest,
            method: .POST,
            body: jsonData,
            headers: ["Content-Type": "application/x-www-form-urlencoded"],
            parse: { data in
                return try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
            },
            completion: { result in

                DispatchQueue.main.async {
                    self.view.hideActivityIndicator()
                }

                switch result {
                case .success(let jsonArray):
                    
                    let invalidEmployees = jsonArray.compactMap { dict -> String? in
                        let valid = dict["IsValid"] as? Bool ?? true
                        if !valid { return "\(dict["EmployeeNumber"] ?? "")" }
                        return nil
                    }

                    if invalidEmployees.isEmpty {
                        completion("", true)
                    } else {
                        let msg = invalidEmployees.joined(separator: " and ") +
                                  " does not have a current subscription."
                        completion(msg, false)
                    }

                case .failure:
                    completion("", true)
                }
            }
        )
    }
    */
    
/*    func validateBuddiesAndSubscription()*/
    func validateBuddies() {
        let buddyID = txtJobShare2.text ?? ""
        guard buddyID.count >= 2 else {
            self.validateBuddiesAndNavigate()
            return
        }

        let isValidBuddy = self.checkBuddyInTheBuddyList()
        if !isValidBuddy{
            return
        }
        self.validateBuddiesAndNavigate()
//        self.checkSubscriptionFor() { msg, success in
//            if !success {
//                DispatchQueue.main.async {
//                    AlertService.showAlertForTopVC(title: "CrewBid iPad", message: msg)
//                }
//                return
//            }
//            DispatchQueue.main.async {
//                self.validateBuddiesAndNavigate()
//            }
//        }
    }
    
    func validateBuddiesAndNavigate() {
            self.selectedObject = [
                "jobShare1": self.txtJobShare1.text ?? "",
                "jobShare2": self.txtJobShare2.text ?? "",
                "isJobShareContingency": self.isChecked
            ]
            DispatchQueue.main.async {
                self.navigateToCredentialsPageVC()
            }
    }
    
    
    
    func navigateToCredentialsPageVC() {
        let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBCredentialsPageVC") as! CBCredentialsPageVC
        vc.type = .submitBid
        vc.bidPeriod = bidPeriod
        vc.selectedObject = self.selectedObject
        vc.defaultEmployeeNumber = self.txtJobShare1.text
        vc.preferredContentSize = CGSize(width: 600, height: 500)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func checkBuddyInTheBuddyList() -> Bool {
        
        if !Thread.isMainThread {
            var result = false
            DispatchQueue.main.sync {
                result = self.checkBuddyInTheBuddyList()
            }
            return result
        }
        
        let jobShare1 = txtJobShare1.text ?? ""
        let jobShare2 = txtJobShare2.text ?? ""
        
        var message = ""
        var isExist = true
        
        // Employee number of JobShare2 must be in JobShare1 buddy list
        if !jobShare1BuddyList.contains(jobShare2) && !jobShare2.isEmpty {
            message = "Job Share 2 [ID: \(jobShare2)] is not in the buddy list of Job Share 1 [ID: \(jobShare1)]."
            isExist = false
        }
        
        // Employee number of JobShare1 must be in JobShare2 buddy list
        if !jobShare2BuddyList.contains(jobShare1) && !jobShare1.isEmpty {
            
            let part = "Job Share 1 [ID: \(jobShare1)] is not in the buddy list of Job Share 2 [ID: \(jobShare2)]."
            
            if message.isEmpty {
                message = part
            } else {
                message += "\n\n" + part
            }
            
            isExist = false
        }
        
        if !isExist {
            AlertService.showAlertForTopVC(title: "Buddy Bid", message: message)
        }
        return isExist
    }
    
    
    func isValidEmployeeNumber(_ employeeNumber: String) -> Bool {
        guard employeeNumber.count > 0 else {
            return false
        }
        
        let nonDigits = CharacterSet.decimalDigits.inverted
        return employeeNumber.rangeOfCharacter(from: nonDigits) == nil
    }
    
    
    func downloadBuddies(userID: String, completion: @escaping (Bool) -> Void){
        let cleanUserID = userID.replacingOccurrences(of: "e", with: "")
        let context = self.bidPeriod.managedObjectContext
        let url = "\(self.kCBSwaServiceURL())/if-line-base-auction/buddies?employeeId=\(cleanUserID)"
        
        let headers: [String: String] = [
            "Content-Type": "application/hal+json",
            "Authorization": "Bearer \(KeychainHelper.retrieveTokenFromKeyChain()!)",
            "x-swa-user-department": "IF"
        ]
        
        APIService.shared.fetch(
            urlString: url,
            method: .GET,
            headers: headers,
            allowNon200Status: true,
            parse: { data in
                try JSONSerialization.jsonObject(with: data)
            },
            completion: { result in
                
                switch result {
                    
                case .success(let jsonObj):
                    if let dict = jsonObj as? [String: Any] {
                        let statusFromBody = dict["status"] as? Int
                        let errorFromBody = (dict["error"] as? String)?.lowercased()
                        let messageFromBody = (dict["message"] as? String)?.lowercased() ?? ""
                        
                        let looksLikeAuthError =
                            statusFromBody == 401 ||
                            errorFromBody == "invalid_token" ||
                            messageFromBody.contains("token not valid") ||
                            messageFromBody.contains("token expired")
                        
                        if looksLikeAuthError {
                            // Show invalid token alert and finish
                            self.showInvalidTokenAlertOnce()
                            completion(false)
                            return
                        }
                    }
        
                    guard
                        let dict = jsonObj as? [String: Any],
                        let buddyArray = dict["buddyIds"] as? [String]
                    else {
                        AlertService.showAlertForTopVC(title: "Buddy Bid Error", message: "Data is not in the correct format.")
                        completion(false)
                        return
                    }

                    var buddyDict: [String: [String: String]] = [:]
                    
                    for buddy in buddyArray{
                        let request = NSFetchRequest<SeniorityList>(entityName: "SeniorityList")
                        request.predicate = NSPredicate(format: "employeeId == %@", buddy)
                        request.fetchLimit = 1
                        
                        do {
                            let results = try context?.fetch(request)
                            if let seniority = results?.first {
                                let details: [String: String] = [
                                    "Name": seniority.legalName ?? "",
                                    "Domicile": self.bidPeriod.base ?? ""
                                ]
                                buddyDict[buddy] = details
                            }
                        } catch {
                            print("Error buddy bid list fetch: \(error)")
                            continue
                        }
                    }
                    DispatchQueue.main.async {
                        if userID == self.txtJobShare1.text{
                            self.jobShare1BuddyList = buddyArray
                        }
                        if userID == self.txtJobShare2.text{
                            self.jobShare2BuddyList = buddyArray
                        }

                        completion(true)
                    }
                    
                case .failure(let error):
                    switch error{
                    case .httpStatus(let status) where status == 401:
                        self.showInvalidTokenAlertOnce()
                        
                    default:
                        AlertService.showAlertForTopVC(title: "Buddy Bid Error", message: error.localizedDescription)
                    }
                    completion(false)
                }
            }
        )
    }
    
    private func showInvalidTokenAlertOnce() {
        DispatchQueue.main.async {
            // If already showing/presented, do nothing
            guard !self.isPresentingInvalidTokenAlert else { return }
            self.isPresentingInvalidTokenAlert = true
            self.invalidTokenAlert()
        }
    }
    
    func invalidTokenAlert(){
        AlertService.showAlertForTopVC(title: "Job Share Alert", message: "The token has expired or is invalid. Please provide the credentials to proceed.", actions: [(title: "OK", style: .default, handler:{ _ in
            DispatchQueue.main.async {
                guard let vc = UIStoryboard(name: "BidInfo", bundle: nil).instantiateViewController(withIdentifier: "CBCredentialsPageVC") as? CBCredentialsPageVC else { return }
                vc.selectedRound = self.bidPeriod.round?.intValue
                vc.loginReason = .tokenExpired
                vc.preferredContentSize = CGSize(width: 600, height: 500)
                vc.isModalInPresentation = true
                var dictInfo: [String: Any] = [:]
                dictInfo["base"] = self.bidPeriod.base
                dictInfo["month"] = self.bidPeriod.month
                dictInfo["round"] = self.bidPeriod.round
                if let positionValue = self.bidPeriod.positionType?.intValue,
                   let pos = BICrewPositionType(rawValue: positionValue){
                    dictInfo["position"] = CBUtils.shortName(for: pos)
                    vc.selectedPosition = pos
                }
                vc.isForReauth = true
                vc.bidDetails = dictInfo
                self.present(vc, animated: true)
            }
            self.isPresentingInvalidTokenAlert = true
        })])
    }
    
    
    func kCBSwaServiceURL() -> String{
        let env = UserDefaults.standard.string(forKey: "SwaApiEnv")
        var baseURL = ""
        if env == "Dev"{
            baseURL = "https://itest.service.east.0.crewbid.dev.swalife.com/"
        }else if env == "QA"{
            baseURL = "https://service.east.0.crewbid.qa.swalife.com/itest"
        }else{
            baseURL = "https://service.crewbid.swalife.com/golden"
        }
        return baseURL
    }
    
}

extension JobShareViewController: UITextFieldDelegate {
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        let empDict = self.FAListDict?[textField.text!] as? [String: Any]
        let empName = empDict?["Name"]
        let empDomicile = empDict?["Domicile"]
        if empName == nil{
            domicileLbl.isHidden = true
            empNameLbl.isHidden = true
        }else{
            domicileLbl.isHidden = false
            domicileLbl.text = empDomicile as? String
            empNameLbl.isHidden = false
            empNameLbl.text = empName as? String
            empNameLbl.textColor = CBColor.buddyTextColor
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() // dismiss keyboard
        return true
    }
    
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == txtJobShare2 || textField == txtJobShare1 {
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

    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text!.isEmpty {
            textField.layer.borderWidth = 4
            textField.layer.borderColor = UIColor.purple.cgColor
        } else {
            textField.layer.borderWidth = 4
            textField.layer.borderColor = UIColor.gray.cgColor
        }
    }
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        textField.layer.borderColor = UIColor.gray.cgColor
    }
    
}
