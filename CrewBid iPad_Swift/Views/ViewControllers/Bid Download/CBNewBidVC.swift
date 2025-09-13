//
//  CBNewBidVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/03/25.
//

import UIKit

class CBNewBidVC: UIViewController {

    var app: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    var objDataBuilder:ODataBuilder?
    var dicWBAuthorizationDetails: [String: Any] = [:]
    var dicWbidResponse: [String: Any] = [:]
    var year: NSNumber?
    var month: NSNumber?
    var base: String?
    var employeeNumber: String?
    var position: BICrewPosition?
    var round: NSNumber?
    var userId: String?
    var password: String?
    var isEmpNumVerified: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        app.simplePingStarter()
        objDataBuilder = ODataBuilder()

        
        
        
    }

    func setupUI() {
        self.view.clipsToBounds = true
        self.view.layer.borderColor = UIColor.darkGray.cgColor
        self.view.layer.borderWidth = 4
        self.view.layer.cornerRadius = 10
    }
    
    func checkAuthentication(empID: String){
        switch app.objNetworkType {
        case .free: AlertService.showAlertForTopVC(title: "Cannot Download!", message: "You cannot get needed access via SouthwestWifi or 2Wire. Try again later when you are safely on the ground and have another internet access.")
            return
        default:break
        }
        self.view.showActivityIndicator()
        
        var dicAuthenticationInfo: [String: Any] = [:]

        dicAuthenticationInfo["Platform"] = "iPad"
        dicAuthenticationInfo["OperatingSystem"] = "iPad OS"

        // Application Version
        if let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            dicAuthenticationInfo["Version"] = appVersion
        }

        dicAuthenticationInfo["Base"] = self.base
        dicAuthenticationInfo["BidRound"] = self.round

        // Blocking setup of Bid data download from the server
        if AppState.shared.isHistoricBid {
            dicAuthenticationInfo["RequestType"] = 5
        } else {
            dicAuthenticationInfo["RequestType"] = 0
        }

        // Month (short name, uppercased)
        if let month = self.month as? Int {
            dicAuthenticationInfo["Month"] = CBUtils.shortMonthName(month: month, uc: true)
        }

        // Position
        dicAuthenticationInfo["Postion"] = position?.shortName
        
        self.employeeNumber = empID
        
        var entered_EmpID = self.employeeNumber?.replacingOccurrences(of: "x", with: "").trimmingCharacters(in: .symbols)
        entered_EmpID = entered_EmpID?.replacingOccurrences(of: "e", with: "").trimmingCharacters(in: .symbols)
        dicAuthenticationInfo["EmployeeNumber"] = entered_EmpID
    }
    
 
}
