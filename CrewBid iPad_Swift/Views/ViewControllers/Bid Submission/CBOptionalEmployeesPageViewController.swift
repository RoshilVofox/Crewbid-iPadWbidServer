

import UIKit
import CoreData

class CBOptionalEmployeesPageViewController: BaseViewController {
    
    @IBOutlet weak var lblMessage: UILabel!
    @IBOutlet weak var buddyBidTxtField_1: customUITextField!
    @IBOutlet weak var buddyBidderName_1: UILabel!
    @IBOutlet weak var buddyBidTxtField_2: customUITextField!
    @IBOutlet weak var buddyBidderName_2: UILabel!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var btnNext: UIButton!
    
    @IBOutlet weak var buddyBidderDomicile_1: UILabel!
    @IBOutlet weak var buddyBidderDomicile_2: UILabel!
    
    @IBOutlet weak var lblWarning: UILabel!
    @IBOutlet weak var lblBuddyBid: UILabel!
    
    @IBOutlet weak var lblTitle: UILabel!
    var isBuddy1Valid: Bool = false
    var isBuddy2Valid: Bool = false
    var empID: String?
    var bidPeriod: BIBidPeriod!
//    var FAListDict:[String:Any]? = nil
    var optionalEmployees = NSMutableArray()
    var biddersBuddyList = [String]()
    var buddy1BuddyList = [String]()
    var buddy2BuddyList = [String]()
    private var isPresentingInvalidTokenAlert = false
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
//        FAListDict = CBUtils.readJSONStringFromFile()
        NotificationCenter.default.addObserver(self,
            selector: #selector(handleAuthFlowEnded),
            name: Notification.Name("AuthFlowEnded"),
            object: nil)
    }
    
    func setupUI() {
        self.lblTitle.text = "Submit bid or Buddy bid for EID \(empID ?? "")"
        buddyBidTxtField_1.delegate = self
        buddyBidTxtField_2.delegate = self
        buddyBidTxtField_1.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: buddyBidTxtField_1.frame.height))
        buddyBidTxtField_2.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: buddyBidTxtField_2.frame.height))
        buddyBidTxtField_1.leftViewMode = .always
        buddyBidTxtField_2.leftViewMode = .always
        buddyBidderDomicile_1.isHidden = true
        buddyBidderDomicile_2.isHidden = true
        buddyBidderName_1.text = ""
        buddyBidderName_2.text = ""
        lblBuddyBid.textColor = .secondaryLabel
        btnClose.setTitle("", for: .normal)
        btnNext.setTitle("", for: .normal)
        buddyBidTxtField_1.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        buddyBidTxtField_2.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    @objc private func handleAuthFlowEnded() {
        self.isPresentingInvalidTokenAlert = false
    }
    
    
    @IBAction func btnDismissAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnNextAction(_ sender: Any) {
        view.endEditing(true)
        let buddy1 = buddyBidTxtField_1.text ?? ""
        let buddy2 = buddyBidTxtField_2.text ?? ""
        
        if buddy1.isEmpty && buddy2.isEmpty {
            NotificationCenter.default.post(name:Notification.Name("showJobShareAlert"), object: nil)
            return
        }
           
        if buddy1 == buddy2 && !buddy1.isEmpty {
                AlertService.showAlertForTopVC(title: "CrewBid", message: "You cannot enter the same employee number in Buddy 1 and Buddy 2.", actions: [(title: "OK", style: .default, handler: { _ in
                    self.buddyBidTxtField_2.text = ""
                    self.buddyBidderName_2.text = ""
                    self.buddyBidderDomicile_2.text = ""
                })])
            return
            }
        
        let isBuddy1Invalid = !buddy1.isEmpty && !isBuddyInSameDomicile(buddy1)
        let isBuddy2Invalid = !buddy2.isEmpty && !isBuddyInSameDomicile(buddy2)

        if isBuddy1Invalid || isBuddy2Invalid {
            
            if isBuddy1Invalid {
                buddyBidTxtField_1.shakeTextField()
            }

            if isBuddy2Invalid {
                buddyBidTxtField_2.shakeTextField()
            }
            return
        }
//        if CBGlobalMethods.shared.domicileIsDifferent == true{
//                AlertService.showAlertForTopVC(title: "CrewBid", message: "One of the Buddy Bidders is NOT in \(CBGlobalMethods.shared.selectedBidPeriod?.base ?? "")", actions: [(title: "OK", style: .default, handler: {_ in
//                    self.buddyBidTxtField_1.text = ""
//                    self.buddyBidTxtField_2.text = ""
//                    self.buddyBidderName_1.text = ""
//                    self.buddyBidderDomicile_1.text = ""
//                    self.buddyBidderName_2.text = ""
//                    self.buddyBidderDomicile_2.text = ""
//                    self.optionalEmployees.removeAllObjects()
//                })])
//            return
//            }
        
        if buddy1 == self.empID || buddy2 == self.empID {
            let bidder = self.empID ?? ""
            
            if buddy1 == bidder {
                AlertService.showAlertForTopVC(title: "Buddy Bid", message: "Bidder [\(bidder)] and Buddy 1 [\(buddy1)] should not be the same.")
                return
            }
            
            if buddy2 == bidder {
                AlertService.showAlertForTopVC(title: "Buddy Bid", message: "Bidder [\(bidder)] and Buddy 2 [\(buddy2)] should not be the same.")
                return
            }
        }
        
        let buddiesToCheck = [buddy1, buddy2].filter { !$0.isEmpty }

        self.view.showActivityIndicator(message: "Checking Authentication...")

        checkBuddyAuthentication(buddiesToCheck[0]) { [weak self] isValid1 in
            guard let self = self else { return }

            if !isValid1 {
                DispatchQueue.main.async {
                    self.view.hideActivityIndicator()
                }
                return
            }

            // If only one buddy entered
            if buddiesToCheck.count == 1 {
                DispatchQueue.main.async {
                    self.view.hideActivityIndicator()
                }
                self.validateBuddyLists(buddy1: buddy1, buddy2: buddy2)
                return
            }

            // Check second buddy
            self.checkBuddyAuthentication(buddiesToCheck[1]) { isValid2 in

                DispatchQueue.main.async {
                    self.view.hideActivityIndicator()
                }

                guard isValid2 else { return }

                self.validateBuddyLists(buddy1: buddy1, buddy2: buddy2)
            }
        }
        
//        self.view.showActivityIndicator(message: "Validating Buddies...")
//        
//        self.hasBuddyExistInEachOtherList { isValid in
//            DispatchQueue.main.async {
//                self.view.hideActivityIndicator()
//                guard isValid else { return }
//                self.optionalEmployees.removeAllObjects()
//                // Add buddies directly — no subscription check
//                if !buddy1.isEmpty { self.optionalEmployees.add(buddy1) }
//                if !buddy2.isEmpty { self.optionalEmployees.add(buddy2) }
//                let removedCount = CBBidSubmissionViewModel.previewRemovedFALinesCount(
//                    bidPeriod: self.bidPeriod!,
//                    optionalEmpNumbers: self.optionalEmployees
//                )
//
//                if removedCount > 0 {
//                    AlertService.showAlertForTopVC(
//                        title: "CrewBid",
//                        message: "\(removedCount) lines were removed from the submission because they were D position lines. Buddy Bid Lines must have positions (A, B, etc.) for each bidder.",
//                        actions: [
//                            (title: "OK", style: .default, handler: { _ in
//                                self.finalAlert()   // Buddy Bid Terms NEXT
//                            }),
//                            (title: "Cancel", style: .cancel, handler: { _ in })
//                        ]
//                    )
//                } else {
//                    self.finalAlert()
//                }
//            }
//        }
    }
    
    func validateBuddyLists(buddy1: String, buddy2: String) {

        self.view.updateActivityIndicator(message: "Validating Buddies...")

        self.hasBuddyExistInEachOtherList { isValid in
            DispatchQueue.main.async {
                self.view.hideActivityIndicator()
                guard isValid else { return }

                self.optionalEmployees.removeAllObjects()

                if !buddy1.isEmpty { self.optionalEmployees.add(buddy1) }
                if !buddy2.isEmpty { self.optionalEmployees.add(buddy2) }

                let removedCount = CBBidSubmissionViewModel.previewRemovedFALinesCount(
                    bidPeriod: self.bidPeriod!,
                    optionalEmpNumbers: self.optionalEmployees
                )

                if removedCount > 0 {
                    AlertService.showAlertForTopVC(
                        title: "CrewBid",
                        message: "\(removedCount) lines were removed from the submission because they were D position lines. Buddy Bid Lines must have positions (A, B, etc.) for each bidder.",
                        actions: [
                            (title: "OK", style: .default, handler: { _ in
                                self.finalAlert()
                            }),
                            (title: "Cancel", style: .cancel, handler: { _ in })
                        ]
                    )
                } else {
                    self.finalAlert()
                }
            }
        }
    }
    
    func checkBuddyAuthentication(_ empID: String,
                                  completion: @escaping (Bool) -> Void) {

        AuthService.shared.checkAuthentication(empID: empID) { result in

            let msg = result.message ?? ""

            if msg == "Invalid Account" ||
                msg.contains("create an account") {

                AlertService.showAlertForTopVC(
                    title: "CrewBid",
                    message: "User \(empID) does not have a CrewBid account. Go to www.crewbid.com to create the account."
                )
                completion(false)
                return
            }

            completion(true)

        } onFailure: { error in
            AlertService.showAlertForTopVC(
                title: "CrewBid",
                message: error.localizedDescription
            )
            completion(false)
        }
    }
    
    
    func finalAlert() {
        AlertService.showAlertForTopVC(title: "Buddy Bidding Terms", message: "By continuing, you represent that you have the permission of your buddy or buddies to Buddy Bid with them and you have taken the necessary steps in SwA lite to out them on vour BuddyBidding list.I Understand and Accept", actions: [(title: "OK", style: .default, handler: { _ in
            let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "CBCredentialsPageVC") as! CBCredentialsPageVC
            vc.type = .submitBid
            vc.bidPeriod = self.bidPeriod
            vc.defaultEmployeeNumber = self.empID
            vc.optionalEmployees = self.optionalEmployees
            vc.preferredContentSize = CGSize(width: 600, height: 500)
            self.navigationController?.pushViewController(vc, animated: true)
        })])
    }
    
    /*func ifEmployeeContainsInFALIST() ->Bool {
        if CBGlobalMethods.shared.falistDict.count == 0{
            CBGlobalMethods.shared.falistDict = CBUtils.readJSONStringFromFile()!
        }
        var employeeInFALIST = false
        var isFirstBuddyCorrect = false
        var isSecondBuddyCorrect = false

        let buddy1 = buddyBidTxtField_1.text ?? ""
        let buddy2 = buddyBidTxtField_2.text ?? ""

        if buddy1.isEmpty { isFirstBuddyCorrect = true }
        if buddy2.isEmpty { isSecondBuddyCorrect = true }
        
        if self.bidPeriod.positionType?.intValue == BICrewPositionType.FlightAttendant.rawValue {
            if !employeeInFALIST {
                
                if !isFirstBuddyCorrect {
                    
                    let firstEmp = CBGlobalMethods.shared.falistDict[buddy1]
                    isFirstBuddyCorrect = (firstEmp != nil)
                }
                
                if !isSecondBuddyCorrect {
                    let secondEmp = CBGlobalMethods.shared.falistDict[buddy2]
                    isSecondBuddyCorrect = (secondEmp != nil)
                }
                
                if isFirstBuddyCorrect && isSecondBuddyCorrect {
                    employeeInFALIST = true
                } else {
                    employeeInFALIST = false
                }
                
            }
            if !isFirstBuddyCorrect {
                buddyBidderName_1.isHidden = false
                buddyBidderName_1.text = "Invalid Employee Number"
                buddyBidderName_1.textColor = .red
                buddyBidderDomicile_1.text = ""
                shakeTextField(textField: buddyBidTxtField_1)
            }
            if !isSecondBuddyCorrect {
                buddyBidderName_2.isHidden = false
                buddyBidderName_2.text = "Invalid Employee Number"
                buddyBidderName_2.textColor = .red
                buddyBidderDomicile_2.text = ""
                shakeTextField(textField: buddyBidTxtField_2)
            }
        }
        return true
    }*/
    
    /*
    func checkAllBuddysSubscription(completion: @escaping (_ outputString: String, _ success: Bool) -> Void) {

        let emp1 = self.buddyBidTxtField_1.text ?? ""
        let emp2 = self.buddyBidTxtField_2.text ?? ""
        // Build authentication dictionary
        var employees: [[String: Any]] = []

        if emp1.count >= 2 {
            employees.append([
                "Password": "",
                "EmpNumber": emp1
            ])
        }

        if emp2.count >= 2 {
            employees.append([
                "Password": "",
                "EmpNumber": emp2
            ])
        }

        // No buddy numbers → success
        if employees.isEmpty {
            completion("", true)
            return
        }
        
        let params: [String: Any] = [
            "Platform": "iPad",
            "EmployeeNumbers": employees
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: params, options: []) else {
            completion("", true)
            return
        }
        

//        self.view.showActivityIndicator(message: "Checking subscription...")
        APIService.shared.fetch(
            urlString: EndPoint.shared.checkValidSubscriptionForEmployeesRest,
            method: .POST,
            body: jsonData,
            headers: ["Content-Type": "application/x-www-form-urlencoded"],
            parse: { data in
                // Parse into [[String: Any]]
                return try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] ?? []
            },
            completion: { result in

                DispatchQueue.main.async {
                    self.view.hideActivityIndicator()
                }

                switch result {
                case .success(let jsonArray):

                    var invalidEmployees: [String] = []

                    for dict in jsonArray {
                        let isValid = dict["IsValid"] as? Bool ?? true
                        let empNum = "\(dict["EmployeeNumber"] ?? "")"

                        if !isValid {
                            invalidEmployees.append(empNum)
                        }
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
        })


    }*/
    
    func hasBuddyExistInEachOtherList(completion: @escaping (Bool) -> Void) {
//        let isValidBuddy = self.ifEmployeeContainsInFALIST()
//        if !isValidBuddy {
//            completion(false)
//            return
//        }
        
        let buddy1 = self.buddyBidTxtField_1.text ?? ""
        let buddy2 = self.buddyBidTxtField_2.text ?? ""
        
        var userList: [String] = []
        userList.append(self.empID ?? "")
        
        if !buddy1.isEmpty { userList.append(buddy1) }
        if !buddy2.isEmpty { userList.append(buddy2) }
        
        if userList.isEmpty {
            completion(true)
            return
        }
        
        var pendingCalls = userList.count
        
        var didFinish = false
        var didShowBuddyErrorAlert = false
        for userID in userList {
            self.downloadBuddies(userID: userID) { success in
                DispatchQueue.main.async {
                    
                    if didFinish {return}
                    
                    if !success{
                        if self.isPresentingInvalidTokenAlert {
                            didFinish = true
                            completion(false)
                            return
                        }
                        
                        if !didShowBuddyErrorAlert {
                            didShowBuddyErrorAlert = true
                            didFinish = true

                            AlertService.showAlertForTopVC(
                                title: "Buddy Bid Error",
                                message: "Error 404: Not Found\n\nResponse Not Found"
                            )

                            completion(false)
                            return
                        }
                    }
                    pendingCalls -= 1
                    
                    if pendingCalls == 0 {
                        didFinish = true
                        self.checkBuddyInTheBuddyList{ isValid in
                            completion(isValid)
                        }
                    }
                }
            }
        }
    }
    
    
    func downloadBuddies(userID: String, completion: @escaping (Bool) -> Void){
        let cleanUserID = userID.replacingOccurrences(of: "e", with: "")
        
        let buddy1 = self.buddyBidTxtField_1.text ?? ""
        let buddy2 = self.buddyBidTxtField_2.text ?? ""
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
                            self.showInvalidTokenAlertOnce()
                            completion(false)
                            return
                        }
                    }
                    
                    guard
                        let dict = jsonObj as? [String: Any],
                        let buddyArray = dict["buddyIds"] as? [String]
                    else {
                        self.assignBuddyList([], for: userID, buddy1: buddy1, buddy2: buddy2)
                        completion(true)
                        return
                    }
                    self.assignBuddyList(buddyArray, for: userID, buddy1: buddy1, buddy2: buddy2)
                    completion(true)
                    
                    
                case .failure(let error):
                    switch error{
                    case .httpStatus(let status, _) where status == 401:
                        self.showInvalidTokenAlertOnce()
                        completion(false)
                        
                    case .httpStatus(let status, let data) where status == 404:
                        if let data = data,
                           let _ = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            self.assignBuddyList([], for: userID, buddy1: buddy1, buddy2: buddy2)
                            completion(true)

                        } else {
                            completion(false)
                        }
                        return
                    default:
                        break
                    }
                    completion(false)
                }
            }
        )
    }
    
    private func assignBuddyList(
        _ buddies: [String],
        for userID: String,
        buddy1: String,
        buddy2: String
    ) {
        if userID == self.empID {
            self.biddersBuddyList = buddies
        } else if userID == buddy1 {
            self.buddy1BuddyList = buddies
        } else if userID == buddy2 {
            self.buddy2BuddyList = buddies
        }
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
        AlertService.showAlertForTopVC(title: "Invalid Token Alert", message: "The token has expired or is invalid. Please provide the credentials to proceed.", actions: [(title: "OK", style: .default, handler:{ _ in
            DispatchQueue.main.async {
                guard let vc = UIStoryboard(name: "BidInfo", bundle: nil).instantiateViewController(withIdentifier: "CBCredentialsPageVC") as? CBCredentialsPageVC else { return }
                vc.preferredContentSize = CGSize(width: 600, height: 500)
                vc.isModalInPresentation = true
                var dictInfo: [String: Any] = [:]
                dictInfo["base"] = self.bidPeriod?.base
                dictInfo["month"] = self.bidPeriod?.month
                dictInfo["round"] = self.bidPeriod?.round
                if let positionValue = self.bidPeriod?.positionType?.intValue,
                   let pos = BICrewPositionType(rawValue: positionValue){
                    dictInfo["position"] = CBUtils.shortName(for: pos)
                    vc.selectedPosition = pos
                }
                vc.isForReauth = true
                self.isPresentingInvalidTokenAlert = true
                self.present(vc, animated: true)
            }
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
        
    
    func checkBuddyInTheBuddyList(completion: @escaping (Bool) -> Void){
//        var result = true

        DispatchQueue.main.async {
            let empNum = self.empID ?? ""
            let buddy1 = self.buddyBidTxtField_1.text ?? ""
            let buddy2 = self.buddyBidTxtField_2.text ?? ""
            
            var message = ""
            var isExist = true
      
            // Buddy 1 in bidder's list
            if !buddy1.isEmpty {
                if !(self.biddersBuddyList.contains(buddy1)) {
                    message = "Buddy 1 [ID: \(buddy1)] is not in the buddy list of Employee Number \(empNum)."
                    isExist = false
                }
            }
            
            // Buddy 2 in bidder's list
            if !buddy2.isEmpty && !self.biddersBuddyList.contains(buddy2) {
                if message.isEmpty {
                    message = "Buddy 2 [ID: \(buddy2)] is not in the buddy list of Employee Number \(empNum)."
                } else {
                    message += "\n\nBuddy 2 [ID: \(buddy2)] is not in the buddy list of Employee Number \(empNum)."
                }
                isExist = false
            }

            // EMP in buddy1 list
            if !empNum.isEmpty && !buddy1.isEmpty && !self.buddy1BuddyList.contains(empNum) {
                if message.isEmpty {
                    message = "Employee Number \(empNum) is not in the buddy list of Buddy 1 [ID: \(buddy1)]."
                } else {
                    message += "\n\nEmployee Number \(empNum) is not in the buddy list of Buddy 1 [ID: \(buddy1)]."
                }
                isExist = false
            }

            // EMP in buddy2 list
            if !empNum.isEmpty && !buddy2.isEmpty && !self.buddy2BuddyList.contains(empNum) {
                if message.isEmpty {
                    message = "Employee Number \(empNum) is not in the buddy list of Buddy 2 [ID: \(buddy2)]."
                } else {
                    message += "\n\nEmployee Number \(empNum) is not in the buddy list of Buddy 2 [ID: \(buddy2)]."
                }
                isExist = false
            }

            if !isExist {
                AlertService.showAlertForTopVC(title: "Buddy Bid", message: message)
            }

            completion(isExist)
        }

    }
    
    
    func seniorityInfo(for employeeId: String) -> SeniorityList? {
        guard let bidPeriod = bidPeriod else { return nil }

        let context = CoreDataManager.shared.persistentContainer.viewContext

        let request: NSFetchRequest<SeniorityList> = SeniorityList.fetchRequest()
        request.predicate = NSPredicate(
            format: "employeeId == %@ AND bidPeriod == %@",
            employeeId,
            bidPeriod
        )
        request.fetchLimit = 1

        return try? context.fetch(request).first
    }
    
    func isBuddyInSameDomicile(_ empId: String) -> Bool {
        guard
            let seniority = seniorityInfo(for: empId),
            let empDomicile = seniority.base,
            let base = bidPeriod?.base
        else {
            return false
        }
        return empDomicile == base
    }
}


extension CBOptionalEmployeesPageViewController: UITextFieldDelegate {
    
    @objc func textFieldDidChange(_ textField: UITextField) {
//        let empDict = self.FAListDict?[textField.text!] as? [String: Any]
//        let empName = empDict?["Name"] as? String
//        let empDomicile = empDict?["Domicile"] as? String
        
        let empId = textField.text ?? ""
        guard !empId.isEmpty else {
            if textField == buddyBidTxtField_1 {
                buddyBidderName_1.isHidden = true
                buddyBidderDomicile_1.isHidden = true
                isBuddy1Valid = false
            } else if textField == buddyBidTxtField_2 {
                buddyBidderName_2.isHidden = true
                buddyBidderDomicile_2.isHidden = true
                isBuddy2Valid = false
            }
            return
        }
        if textField == buddyBidTxtField_1 {
            buddyBidderName_1.isHidden = false
            buddyBidderName_1.text = "Not in Domicile"
            buddyBidderName_1.textColor = .label

            buddyBidderDomicile_1.isHidden = true
            isBuddy1Valid = false

        } else if textField == buddyBidTxtField_2 {
            buddyBidderName_2.isHidden = false
            buddyBidderName_2.text = "Not in Domicile"
            buddyBidderName_2.textColor = .label

            buddyBidderDomicile_2.isHidden = true
            isBuddy2Valid = false
        }
        if let seniority = seniorityInfo(for: empId),
           let empName = seniority.legalName,
           let empDomicile = seniority.base {

            if textField == buddyBidTxtField_1 {
                buddyBidderName_1.isHidden = false
                buddyBidderName_1.text = empName
                buddyBidderName_1.textColor = CBColor.buddyTextColor
                buddyBidderDomicile_1.isHidden = false
                buddyBidderDomicile_1.text = empDomicile
                buddyBidderDomicile_1.textColor = CBColor.buddyTextColor
                isBuddy1Valid = true

            } else if textField == buddyBidTxtField_2 {
                buddyBidderName_2.isHidden = false
                buddyBidderName_2.text = empName
                buddyBidderName_2.textColor = CBColor.buddyTextColor
                buddyBidderDomicile_2.isHidden = false
                buddyBidderDomicile_2.text = empDomicile
                buddyBidderDomicile_2.textColor = CBColor.buddyTextColor
                isBuddy2Valid = true
            }
            
//                    if empDomicile == self.bidPeriod.base{
//                        CBGlobalMethods.shared.domicileIsDifferent = false
//                    }else{
//                        CBGlobalMethods.shared.domicileIsDifferent = true
//                    }
        }
//        let seniority = seniorityInfo(for: empId)
//
//        let empName = seniority?.legalName
//        let empDomicile = seniority?.base
//        
//        if empName == nil {
//            if textField == buddyBidTxtField_1{
//                self.buddyBidderName_1.isHidden = true
//                self.buddyBidderDomicile_1.isHidden = true
//            }else if textField == buddyBidTxtField_2{
//                self.buddyBidderName_2.isHidden = true
//                self.buddyBidderDomicile_2.isHidden = true
//            }
//        }else{
//            if textField == buddyBidTxtField_1{
//                self.buddyBidderName_1.isHidden = false
//                self.buddyBidderName_1.text = empName
//                self.buddyBidderName_1.textColor = CBColor.buddyTextColor
//                self.buddyBidderDomicile_1.isHidden = false
//                self.buddyBidderDomicile_1.text = empDomicile
//                self.isBuddy1Valid = true
//            }else if textField == buddyBidTxtField_2{
//                self.buddyBidderName_2.isHidden = false
//                self.buddyBidderName_2.text = empName
//                self.buddyBidderName_2.textColor = CBColor.buddyTextColor
//                self.buddyBidderDomicile_2.isHidden = false
//                self.buddyBidderDomicile_2.text = empDomicile
//                self.isBuddy2Valid = true
//            }
//        }
//        if empDomicile == self.bidPeriod.base{
//            CBGlobalMethods.shared.domicileIsDifferent = false
//        }else{
//            CBGlobalMethods.shared.domicileIsDifferent = true
//        }
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
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == buddyBidTxtField_1 || textField == buddyBidTxtField_2 {
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
}
