//
//  CBDefaultEmployeeVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/03/25.
//

import UIKit

class CBDefaultEmployeeVC: BaseViewController {

    @IBOutlet weak var textEmpNum: customUITextField!
    var hud = MBProgressHUD()
    var isHistoricBid:Bool = false
    var isNewBid:Bool = false
    var isEmpVerified:Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI(){
        textEmpNum.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textEmpNum.frame.height))
        textEmpNum.leftViewMode = .always
        textEmpNum.delegate = self
        textEmpNum.text = UserDefaults.standard.string(forKey: kCBEmployeeNumberDefaultKey)
    }
    @IBAction func btnBackAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnNextAction(_ sender: Any) {
        if textEmpNum.text?.count == 0{
            shakeTextField(textField: textEmpNum)
        }else{
            UserDefaults.standard.set(textEmpNum.text!, forKey: kCBEmployeeNumberDefaultKey)
            self.checkAutheticationForEmpID(self.textEmpNum.text!)
        }
    }
    
    func checkAutheticationForEmpID(_ empNum:String){
        self.view.showActivityIndicator(color: CBColor.cbPurpleColor, message: "Authentication Checking...")
        let app = UIApplication.shared.delegate as! AppDelegate
        var dictAuthInfo:[String:Any] = [:]
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        dictAuthInfo["RequestType"] = "6";dictAuthInfo["Version"] = appVersion;dictAuthInfo["BidRound"] = "0";dictAuthInfo["Postion"] = ""
        dictAuthInfo["EmployeeNumber"] = empNum;dictAuthInfo["FromAppNumber"] = "5";dictAuthInfo["OperatingSystem"] = "iPad OS"
        dictAuthInfo["Month"] = "0";dictAuthInfo["Base"] = "";dictAuthInfo["Platform"] = "iPad"
        let url = URL(string: "\(app.Domain!)GetCrewBidAuthorization")
        var urlRequest = URLRequest(url: url!)
        let jsonData = try! JSONSerialization.data(withJSONObject: dictAuthInfo, options: [])
    
        if let jsonString = String(data: jsonData, encoding: .utf8){
            urlRequest.httpBody = jsonString.data(using: .utf8)
        }
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        self.isEmpVerified = false
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let data = data{
                let httpResponse = response as! HTTPURLResponse
                if httpResponse.statusCode == 200{
                    do{
                        if let dictRes = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? [String:Any]{
                            let isCBMonthlySubscribed = dictRes["IsCBMonthlySubscribed"] as? Bool
                            let isCBYearlySubscribed = dictRes["IsCBYearlySubscribed"] as? Bool
                            let isFree = dictRes["IsFree"] as? Bool
                            let isMonthlySubscribed = dictRes["IsMonthlySubscribed"] as? Bool
                            let isYearlySubscribed = dictRes["IsYearlySubscribed"] as? Bool
                            let isSomeHowSubscribed:Bool = isCBMonthlySubscribed! || isCBYearlySubscribed! || isFree! || isMonthlySubscribed! || isYearlySubscribed!
                            let message = dictRes["Message"] as? String
                            if message == "Invalid Account" || message == "For security purposes, all users need a CrewBid or WBidMax account.  Go to www.crewbidmax.com and create an account"{
                                DispatchQueue.main.async {
                                    let alert = AlertService.showAlert(title: "CrewBid", message: "User \(empNum) does not have a CrewBid account. Go to www.crewbid.com to create the account.", actions: [(title: "Go to crewbid.com", style: .default, handler: {_ in
                                        if let url = URL(string: "http://www.crewbid.com/"){
                                            UIApplication.shared.open(url,options: [:],completionHandler: nil)
                                        }
                                    }), (title:"Cancel", style: .cancel, handler: nil)])
                                    self.present(alert, animated: true)
                                    self.view.hideActivityIndicator()
                                }
                            }else if message == "Subscription Expired" && !isSomeHowSubscribed{
                                DispatchQueue.main.async {
                                    let alert = AlertService.showAlert(title: "CrewBid", message: "User \(empNum) does not have a valid subscription with Crewbid Account. Please Subscribe.", actions: nil)
                                    self.present(alert, animated: true)
                                    self.view.hideActivityIndicator()
                                }
                            }else if message!.contains("Your subscription to CrewBid has expired.  Go to www.crewbid.com and re-subscribe - Go to crewbid.com") && !isSomeHowSubscribed{
                                DispatchQueue.main.async {
                                    let alert = AlertService.showAlert(title: "CrewBid", message: "User \(empNum) does not have a valid subscription with Crewbid Account. Go to www.crewbid.com to Subscribe.", actions: [(title: "Go to crewbid.com", style: .default, handler: {_ in
                                        if let url = URL(string: "http://www.crewbid.com/"){
                                            UIApplication.shared.open(url,options: [:],completionHandler: nil)
                                        }
                                    }), (title:"Cancel", style: .cancel, handler: nil)])
                                    self.present(alert, animated: true)
                                    self.view.hideActivityIndicator()
                                }
                            }else{
                                DispatchQueue.main.async {
                                    self.view.hideActivityIndicator()
                                    self.isEmpVerified = true
                                    self.gotoNextView()
                                }
                            }
                        }
                        
                    }catch{
                            print(error.localizedDescription)
                    }
                }else{
                    self.view.hideActivityIndicator()
                    self.isEmpVerified = true
                    self.gotoNextView()
                }
            }else{
                if let error = error{
                    print(error.localizedDescription)
                }
            }
        }
        dataTask.resume()
    }

    func gotoNextView(){
        UserDefaults.standard.set(textEmpNum.text!, forKey: kCBEmployeeNumberDefaultKey)
        let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBBiddataDownloadVC") as! CBBiddataDownloadVC
        vc.empNum = self.textEmpNum.text
        vc.isNewBid = self.isNewBid
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

extension CBDefaultEmployeeVC : UITextFieldDelegate{
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == textEmpNum {
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
        self.checkAutheticationForEmpID(self.textEmpNum.text!)
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == textEmpNum {
            textField.layer.borderWidth = 4
            textField.layer.borderColor = UIColor.purple.cgColor
        } else {
            textField.layer.borderWidth = 4
            textField.layer.borderColor = UIColor.darkGray.cgColor
        }
    }
}
