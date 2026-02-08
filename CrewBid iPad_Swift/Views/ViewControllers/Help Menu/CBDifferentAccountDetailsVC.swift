//
//  CBDifferentAccountDetailsVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 07/10/25.
//

import UIKit




class CBDifferentAccountDetailsVC: BaseViewController, UserAccountUpdateCellDelegate, ServiceConnectionDelegate {
    func responseError(_ errMsg: String) {
        print("response error")
    }
    
    func serviceResponse(_ arrResponse: [Any]) {
        CBGlobalMethods.shared.hideActivityIndicator()
        let response = arrResponse[0] as! [String: Any]
        print(arrResponse.description)
        if arrResponse.count > 0 {
            let flag = (response["Status"] as? Bool) ?? false
            if flag{
                self.saveUserInfo()
                if isFromAccount{
                    AlertService.showAlertForTopVC(title: "CrewBid", message: "You have updated user account successfully.", actions: [(title: "OK", style: .default, handler:{_ in
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: NSNotification.Name("setupAccountValues"), object: nil)
                        }
                        self.dismiss(animated: true)
                    })])
                }
                CBUtils.setPushNotifications()
            }else{
                AlertService.showAlertForTopVC(title: "Something went wrong ", message: "Please try again or contact us. We would love to help.")
            }
        }
        
    }
    
    func saveUserInfo(){
        app.ObjUserAccount?.cellPhone = dicLocalAccountInfo["CellPhone"] as? String ?? ""
        app.ObjUserAccount?.firstName = dicLocalAccountInfo["FirstName"] as? String ?? ""
        app.ObjUserAccount?.lastName = dicLocalAccountInfo["LastName"] as? String ?? ""
        app.ObjUserAccount?.employeeNumber = dicLocalAccountInfo["EmpNum"] as? String ?? ""
        app.ObjUserAccount?.email = dicLocalAccountInfo["Email"] as? String ?? ""
        app.ObjUserAccount?.position = Int(dicLocalAccountInfo["Position"] as? String ?? "") ?? 0
        app.ObjUserAccount?.isAcceptMail = (dicLocalAccountInfo["AcceptEmail"] as? String ?? "0") == "1"
        app.ObjUserAccount?.CarrierNum = Int(dicLocalAccountInfo["CarrierNum"] as? String ?? "") ?? 0
        app.ObjUserAccount?.UserAccountDateTime = dicLocalAccountInfo["UserAccountDateTime"] as? String ?? ""
        
        app.ObjUserAccount?.saveUserInfo()
    }
    
    func responseStatus(_ responseStatus: Int) {
        print("response Status")
    }
    
    func connectionFailed() {
        print("connection Failed")
    }
    
    func requestFailed() {
        print("request Failed")
    }
    
    func connectionDataReceived(_ progress: Float) {
        print("connection Data Received")
    }
    

    @IBOutlet weak var tableview: UITableView!
    var diffDict:[String:Any] = [:]
    var isFromAccount = false
    var arrCommonHeader:[String] = []
    var dicLocalAccountInfo:[String:Any] = [:]
    var dicSelectedIndex: [String: String] = [:]
    let objDataBuilder = ODataBuilder()
    
    let arrCarrierDetails = ["ATandT",
             "Cingular",
             "Metro_PCS",
             "Nextel",
             "Other",
             "Sprint",
             "Tmobile",
             "Verizon",
             "Virgin_Mobile"]
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func btnBackAction(_ sender: Any) {
        self.dismiss(animated: true, completion: {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("setupAccountValues"), object: nil)
            }
        })
    }
    
    @IBAction func btnDoneAction(_ sender: Any) {
        self.dismiss(animated: true, completion: {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("setupAccountValues"), object: nil)
            }
        })
    }

    @IBAction func btnCancelAction(_ sender: Any) {
        self.dismiss(animated: true, completion: {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("setupAccountValues"), object: nil)
            }
        })
    }
    
    @IBAction func btnUpdateAction(_ sender: Any) {
        switch app.objNetworkType {
        case .ground,.paid: self.updateDetails()
        case .free:
            AlertService.showAlertForTopVC(title: "Network not available!", message: "You are on the plane using the free company limited internet connection.\nYou cannot update account information using the limited internet connection.Either pay for a full internet connection or wailt until you get on the ground and have a full internet connection")
        }
    }
    
    
    func updateDetails(){
        if app.connectedToInternet(){
            CBGlobalMethods.shared.showActivityIndicator(bgColor: CBColor.purple)
            app.sc?.delegate = self
            
            let format = DateFormatter()
            format.dateFormat = "MMM/dd/yyyy hh:mm a"
            let now = Date()
            let startDate = now.timeIntervalSince1970 * 1000
            let dateStarted = String(format: "/Date(%.0f+0800)/", startDate)
    
            dicLocalAccountInfo["UserAccountDateTime"] = dateStarted
            objDataBuilder.updateUserAccount(employeeDetails: dicLocalAccountInfo)
            
        }else{
            AlertService.showAlertForTopVC(title: "Network not available!", message: "Please check your internet connection")
        }
    }
    
    func userAccountCell(_ cell: UserAccountUpdateCell, didChangeSegmentAt index: Int, forKey key: String) {
        dicSelectedIndex[key] = "\(index)"
        if let value = diffDict[key] as? String {
            let arr = value.components(separatedBy: ",")
            if index < arr.count {
                dicLocalAccountInfo[key] = arr[index]
            }
        }
    }
    
}


extension CBDifferentAccountDetailsVC:UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrCommonHeader.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserAccountUpdateCell") as! UserAccountUpdateCell
        var title = ""
        if arrCommonHeader[indexPath.row] == "CarrierNum"{
            title = "Cell Carrier"
        }else if arrCommonHeader[indexPath.row] == "AcceptEmail"{
            title = "Accept Email"
        }else{
            title = arrCommonHeader[indexPath.row]
        }
        cell.nameLabel.text = title
        cell.selectionSegment.tag = indexPath.row
        let key = arrCommonHeader[indexPath.row]
        let value = diffDict[key] as! String
        cell.headerKey = key
        cell.delegate = self
        let arr = value.components(separatedBy: ",")
        
        if title == "Position" {
            cell.selectionSegment.setTitle(arr[0] == "3" ? "Flight Attendant" : "Pilot", forSegmentAt: 0)
            cell.selectionSegment.setTitle(arr[1] == "3" ? "Flight Attendant" : "Pilot", forSegmentAt: 1)
        }
        else if title == "Cell Carrier" {
            if let firstIndex = Int(arr[0]), firstIndex < arrCarrierDetails.count {
                cell.selectionSegment.setTitle(arrCarrierDetails[firstIndex], forSegmentAt: 0)
            }
            if let secondIndex = Int(arr[1]), secondIndex < arrCarrierDetails.count {
                cell.selectionSegment.setTitle(arrCarrierDetails[secondIndex], forSegmentAt: 1)
            }
        }else if title == "Accept Email"{
            cell.selectionSegment.setTitle(arr[0] == "0" ? "No" : "Yes", forSegmentAt: 0)
            cell.selectionSegment.setTitle(arr[1] == "0" ? "No" : "Yes", forSegmentAt: 1)
        }else {
            cell.selectionSegment.setTitle(arr[0], forSegmentAt: 0)
            cell.selectionSegment.setTitle(arr[1], forSegmentAt: 1)
        }
        return cell
    }
}
