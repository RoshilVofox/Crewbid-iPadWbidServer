//
//  ODataBuilder.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 20/06/25.
//

import Foundation

class ODataBuilder {
    
    
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
    
}
