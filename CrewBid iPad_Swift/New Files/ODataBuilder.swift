//
//  ODataBuilder.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 20/06/25.
//

import Foundation

class ODataBuilder {
    var app:AppDelegate?
    
    func getFirstRoundPaperBidVactionsAndUsers(details:[String:Any], completion: @escaping ([Any])  -> Void, errorHandler: @escaping (Error) -> Void ) {
        let urlString = EndPoint.shared.getFirstRoundPaperBidVacationsAndUsers
        let data = try! JSONSerialization.data(withJSONObject: details, options: [])
        let jsonString = String(data: data, encoding: .utf8)!
        
        let url = URL(string: urlString)
        var urlRequest = URLRequest(url: url!)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = jsonString.data(using: .utf8)
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error{
                print(error.localizedDescription)
                errorHandler(error)
            }
            
            if let data = data{
                do{
                    let jsonData = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                    let jsonArray: [Any]
                    if let dict = jsonData as? [String:Any]{
                        jsonArray = [dict]
                    }else if let arr = jsonData as? [Any]{
                        jsonArray = arr
                    }else{
                        jsonArray = []
                    }
                    completion(jsonArray)
                }catch{
                    errorHandler(error)
                }
            }
        }
        dataTask.resume()
    }
    
    func checkUserExistOrNot(_ empNo: String) {
        app = UIApplication.shared.delegate as? AppDelegate
        guard let app = app else { return }
        
        let url = "GetUserDetails/\(empNo)"
        print("weeeebb \(url)")
        
        app.sc?.constructUrl(url)
        app.sc?.checkCrewBidServiceAccessibility { [weak self] isAccessible in
            if isAccessible {
                self?.app?.sc?.get()
            }
        }
    }
    
    func soapUpdateInAppPurchaseDetails(_ employeeDetails: [String: Any]) {
        let urlString = "UpdateCrewBidPaidUntilDateSoap"
        
        app = UIApplication.shared.delegate as? AppDelegate
        
        guard let data = try? JSONSerialization.data(withJSONObject: employeeDetails, options: []),
              let jsonString = String(data: data, encoding: .utf8) else {
            print("Failed to serialize employee details")
            return
        }
        
        app?.sc?.constructUrl(urlString)
        
        let soapController = SoapWebServiceController()
        soapController.delegate = app?.sc?.delegate
        
        app?.sc?.checkCrewBidServiceAccessibility { isAccessible in
            guard isAccessible else { return }
            soapController.postData(urlString, jsonData: employeeDetails)
            print("json string--\(jsonString)")
        }
    }
    
    func updateMaxInAppPurchaseDetails(_ employeeDetails: [String: Any]) {
        let urlString = "UpdateWBidPaidUntilDate"
        
        app = UIApplication.shared.delegate as? AppDelegate
        
        var employeeDetailsMutable = employeeDetails
        employeeDetailsMutable["AppNum"] = "5"
        
        guard let data = try? JSONSerialization.data(withJSONObject: employeeDetailsMutable, options: []),
              let jsonString = String(data: data, encoding: .utf8) else {
            print("Failed to serialize employee details")
            return
        }
        
        app?.sc?.constructUrl(urlString)
        
        print("json string--\(jsonString)")
        
        app?.sc?.checkCrewBidServiceAccessibility { [weak self] isAccessible in
            guard isAccessible else { return }
            self?.app?.sc?.postDataForUpdateInApp(urlName: urlString, jsonString: jsonString)
        }
    }
    
    func updateInAppPurchaseDetails(_ employeeDetails: [String: Any]) {
        let urlString = "UpdateCrewBidPaidUntilDate"
        
        app = UIApplication.shared.delegate as? AppDelegate
        
        guard let data = try? JSONSerialization.data(withJSONObject: employeeDetails, options: []),
              let jsonString = String(data: data, encoding: .utf8) else {
            print("Failed to serialize employee details")
            return
        }
        
        app?.sc?.constructUrl(urlString)
        
        print("json string--\(jsonString)")
        
        app?.sc?.checkCrewBidServiceAccessibility { [weak self] isAccessible in
            guard isAccessible else { return }
            self?.app?.sc?.postData(urlName: urlString, jsonString: jsonString)
        }
    }
    
    func updateCrewBidPaidUntilAfterPendingStatusRest(_ employeeDetails: [String: Any]) {
        let urlString = "UpdateCrewBidPaidUntilDateAfterPedingStatus"
        
        app = UIApplication.shared.delegate as? AppDelegate
        
        guard let data = try? JSONSerialization.data(withJSONObject: employeeDetails, options: []),
              let jsonString = String(data: data, encoding: .utf8) else {
            print("Failed to serialize employee details")
            return
        }
        
        app?.sc?.constructUrl(urlString)
        
        print("json string--\(jsonString)")
        
        app?.sc?.checkCrewBidServiceAccessibility { [weak self] isAccessible in
            guard isAccessible else { return }
            self?.app?.sc?.postData(urlName: urlString, jsonString: jsonString)
        }
    }
    
    func updateMaxInAppPurchaseDetailsAfterPending(_ employeeDetails: [String: Any]) {
        let urlString = "UpdateWBidPaidUntilDateAfterPedingStatus"
        app = UIApplication.shared.delegate as? AppDelegate

        var employeeDetails = employeeDetails
        employeeDetails["AppNum"] = "5"

        guard let data = try? JSONSerialization.data(withJSONObject: employeeDetails, options: []),
              let jsonString = String(data: data, encoding: .utf8) else {
            return
        }

        app?.sc?.constructUrl(urlString)
        print("json string -- \(jsonString)")

        app?.sc?.checkCrewBidServiceAccessibility { [weak self] isAccessible in
            if isAccessible {
                self?.app?.sc?.postData(urlName: urlString, jsonString: jsonString)
            }
        }
    }
    
    func checkAuthentication(_ dicAuthenticationDetails: inout [String: Any]) {
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let urlString = "GetCrewBidAuthorization/"
        dicAuthenticationDetails["FromAppNumber"] = "5"
        
        guard let data = try? JSONSerialization.data(withJSONObject: dicAuthenticationDetails, options: []) else {
            print("Failed to serialize authentication dictionary")
            return
        }
        
        guard let jsonString = String(data: data, encoding: .utf8) else {
            print("Failed to convert JSON data to string")
            return
        }
        
        app.sc?.constructUrl(urlString)
        print("json string--\(jsonString)")
        
        app.sc?.checkCrewBidServiceAccessibility { isAccessible in
            DispatchQueue.main.async {
                CBGlobal.sharedObject.hideActivityIndicator()
            }
            if isAccessible {
                app.sc?.postData(urlName: urlString, jsonString: jsonString)
            }
        }
    }
    
    func getWBidVacationFileNames(_ employeeDetails: [String: Any]) {
        let urlString = "GetCrewBidVacFileNames"
        guard let data = try? JSONSerialization.data(withJSONObject: employeeDetails, options: []) else {
            print("Failed to serialize employeeDetails to JSON")
            return
        }
        
        let jsonString = String(data: data, encoding: .utf8) ?? ""
        app?.sc?.constructUrl(urlString)
        
        print("json string--\(jsonString)")
        
        app?.sc?.checkCrewBidServiceAccessibility { isAccessible in
            if isAccessible {
                self.app?.sc?.postData(urlName: urlString, jsonString: jsonString)
            }
        }
    }
    
    
}
