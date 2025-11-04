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
    
    
    func updateUserAccount(employeeDetails: [String: Any]) {
        let urlString = "UpdateCrewbidUserDetails"
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
        // Convert dictionary to JSON string
        if let data = try? JSONSerialization.data(withJSONObject: employeeDetails, options: []),
           let jsonString = String(data: data, encoding: .utf8) {
            
            print("json string -- \(jsonString)")
            
            app.sc?.constructUrl(urlString)
            
            // Check service accessibility
            app.sc?.checkCrewBidServiceAccessibility { isAccessible in
                if isAccessible {
                    app.sc?.postData(urlName: urlString, jsonString: jsonString)
                }
            }
        } else {
            print("Failed to serialize employeeDetails to JSON")
        }
    }
    
    func getSyncVersionNumber(dictDetails: [String: Any],
                              completion: @escaping (_ result: [[String: Any]]?) -> Void) {
        
        var urlString = "GetCBServerStateandPresetVersionNumber"
        let app = UIApplication.shared.delegate as! AppDelegate
        
        guard app.connectedToInternet() else {
            AlertService.showAlertForTopVC(title: "Network Not Available",
                                           message: "Please check your internet connection")
            completion(nil)
            return
        }
        
        guard let data = try? JSONSerialization.data(withJSONObject: dictDetails, options: []),
              let jsonString = String(data: data, encoding: .utf8) else {
            print("❌ Failed to encode request body")
            completion(nil)
            return
        }
        
        urlString = baseURL + urlString
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = kURLConnectionTimeout
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonString.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Request error:", error.localizedDescription)
                completion(nil)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response")
                completion(nil)
                return
            }
            
            print("📡 Status code:", httpResponse.statusCode)
            
            guard let data = data else {
                print("❌ No response data")
                completion(nil)
                return
            }
            
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    print("✅ Parsed Array Response")
                    completion(jsonArray)
                } else if let jsonDict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("✅ Parsed Dictionary Response")
                    completion([jsonDict]) // wrap dict in array
                } else {
                    print("⚠️ Unexpected JSON format")
                    completion(nil)
                }
            } catch {
                print("❌ JSON parsing error:", error.localizedDescription)
                completion(nil)
            }
        }.resume()
    }
    
    func saveCrewBidStateAndPresetToServer(dictDetails: [String: Any], completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        var urlString = "SaveCBAppStateAndPresetToServer"
        let app = UIApplication.shared.delegate as! AppDelegate

        // Check internet connection
        guard app.connectedToInternet() else {
            AlertService.showAlertForTopVC(
                title: "Network Not Available",
                message: "Please check your internet connection"
            )
            completion(.failure(NSError(domain: "NetworkError", code: -1009, userInfo: [
                NSLocalizedDescriptionKey: "No internet connection."
            ])))
            return
        }

        // Convert request details to JSON string
        guard let data = try? JSONSerialization.data(withJSONObject: dictDetails, options: []),
              let jsonString = String(data: data, encoding: .utf8) else {
            print("❌ Failed to encode request body")
            completion(.failure(NSError(domain: "EncodingError", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to encode request body."
            ])))
            return
        }

        // Create full URL
        urlString = baseURL + urlString
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            completion(.failure(NSError(domain: "URLError", code: -2, userInfo: [
                NSLocalizedDescriptionKey: "Invalid URL."
            ])))
            return
        }

        // Check CrewBid service availability
        app.sc?.checkCrewBidServiceAccessibility { isAccessible in
            guard isAccessible else {
                print("⚠️ CrewBid service not accessible")
                completion(.failure(NSError(domain: "ServiceUnavailable", code: -3, userInfo: [
                    NSLocalizedDescriptionKey: "CrewBid service is not accessible."
                ])))
                return
            }

            // Configure URL request
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 2000.0
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonString.data(using: .utf8)

            // Send request
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Request error:", error.localizedDescription)
                    completion(.failure(error))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Invalid response")
                    completion(.failure(NSError(domain: "ResponseError", code: -4, userInfo: [
                        NSLocalizedDescriptionKey: "Invalid server response."
                    ])))
                    return
                }

                print("📡 Status code:", httpResponse.statusCode)

                guard let data = data else {
                    print("❌ No response data")
                    completion(.failure(NSError(domain: "DataError", code: -5, userInfo: [
                        NSLocalizedDescriptionKey: "No response data received."
                    ])))
                    return
                }

                do {
                    if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                        print("✅ Parsed Array Response")
                        completion(.success(jsonArray))
                    } else if let jsonDict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("✅ Parsed Dictionary Response")
                        completion(.success([jsonDict])) // wrap dict in array
                    } else {
                        print("⚠️ Unexpected JSON format")
                        completion(.failure(NSError(domain: "JSONError", code: -6, userInfo: [
                            NSLocalizedDescriptionKey: "Unexpected JSON format."
                        ])))
                    }
                } catch {
                    print("❌ JSON parsing error:", error.localizedDescription)
                    completion(.failure(error))
                }
            }.resume()
        }
    }

    
    func getCrewBidStateAndPresetFromServer(dictDetails: [String: Any], completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        var urlString = "GetCBAppStateAndPresetFromServer"
        let app = UIApplication.shared.delegate as! AppDelegate

        // Check internet connection
        guard app.connectedToInternet() else {
            AlertService.showAlertForTopVC(
                title: "Network Not Available",
                message: "Please check your internet connection"
            )
            completion(.failure(NSError(domain: "NetworkError", code: -1009, userInfo: [
                NSLocalizedDescriptionKey: "No internet connection."
            ])))
            return
        }

        // Convert request details to JSON string
        guard let data = try? JSONSerialization.data(withJSONObject: dictDetails, options: []),
              let jsonString = String(data: data, encoding: .utf8) else {
            print("❌ Failed to encode request body")
            completion(.failure(NSError(domain: "EncodingError", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to encode request body."
            ])))
            return
        }

        // Create full URL
        urlString = baseURL + urlString
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            completion(.failure(NSError(domain: "URLError", code: -2, userInfo: [
                NSLocalizedDescriptionKey: "Invalid URL."
            ])))
            return
        }

        // Check CrewBid service availability
        app.sc?.checkCrewBidServiceAccessibility { isAccessible in
            guard isAccessible else {
                print("⚠️ CrewBid service not accessible")
                completion(.failure(NSError(domain: "ServiceUnavailable", code: -3, userInfo: [
                    NSLocalizedDescriptionKey: "CrewBid service is not accessible."
                ])))
                return
            }

            // Configure URL request
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 2000.0
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonString.data(using: .utf8)

            // Send request
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Request error:", error.localizedDescription)
                    completion(.failure(error))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Invalid response")
                    completion(.failure(NSError(domain: "ResponseError", code: -4, userInfo: [
                        NSLocalizedDescriptionKey: "Invalid server response."
                    ])))
                    return
                }

                print("📡 Status code:", httpResponse.statusCode)

                guard let data = data else {
                    print("❌ No response data")
                    completion(.failure(NSError(domain: "DataError", code: -5, userInfo: [
                        NSLocalizedDescriptionKey: "No response data received."
                    ])))
                    return
                }

                do {
                    if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                        print("✅ Parsed Array Response")
                        completion(.success(jsonArray))
                    } else if let jsonDict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("✅ Parsed Dictionary Response")
                        completion(.success([jsonDict])) // wrap dict in array
                    } else {
                        print("⚠️ Unexpected JSON format")
                        completion(.failure(NSError(domain: "JSONError", code: -6, userInfo: [
                            NSLocalizedDescriptionKey: "Unexpected JSON format."
                        ])))
                    }
                } catch {
                    print("❌ JSON parsing error:", error.localizedDescription)
                    completion(.failure(error))
                }
            }.resume()
        }
    }


}
