//
//  BIBidFileDownload.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 11/05/25.
//

import Foundation
import ZipArchive

class BIBidFileDownload: NSObject{
    static let shared = BIBidFileDownload()
    //MARK: Download New Bid/Awards
//    func downloadBidFiles(sessionKey:String, filename:String, completionHandler:@escaping (Result<URL, Error>) -> Void){
//        let isRequestType = (filename as NSString).pathExtension.uppercased() == "TXT"
//        let requestType = isRequestType ? "TXTPACKET" : "ZIPPACKET"
//        let key = self.stringByAddingPercentEscapes(to: sessionKey)
//        let bodyString = "REQUEST=\(requestType)&CREDENTIALS=\(key)&NAME=\(filename)"
//        guard let bodyData = bodyString.data(using: .utf8), let url = URL(string: EndPoint.shared.thirdpartyURL) else {
//            completionHandler(.failure(Errors.invalidURL))
//            return}
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.httpBody = bodyData
//        let config = URLSessionConfiguration.default
//        config.timeoutIntervalForRequest = 120
//        config.timeoutIntervalForResource = 300
//        let downloadTask = URLSession.shared.downloadTask(with: request) { tempURL, _, error in
//            if let error = error{
//                completionHandler(.failure(error))
//                return}
//            guard let tempURL = tempURL else{
//                completionHandler(.failure(Errors.noData))
//                return}
//            completionHandler(.success(tempURL))
//        }
//        downloadTask.resume()
//    }
//    func downloadBidFiles(
//        sessionKey: String,
//        filename: String,
//        completionHandler: @escaping (Result<URL, Error>) -> Void
//    ) {
//        let isRequestType = (filename as NSString).pathExtension.uppercased() == "TXT"
//        let requestType = isRequestType ? "TXTPACKET" : "ZIPPACKET"
//        let key = self.stringByAddingPercentEscapes(to: sessionKey)
//        let bodyString = "REQUEST=\(requestType)&CREDENTIALS=\(key)&NAME=\(filename)"
//        
//        guard let bodyData = bodyString.data(using: .utf8) else {
//            completionHandler(.failure(Errors.noData))
//            return
//        }
//        
//        APIService.shared.fetchDownload(
//            urlString: EndPoint.shared.thirdpartyURL,
//            httpMethod: .POST,
//            body: bodyData,
//            headers: nil,
//            timeout: 300
//        ) { result in
//            switch result {
//            case .success(let tempURL):
//                completionHandler(.success(tempURL))
//            case .failure(let error):
//                completionHandler(.failure(error))
//            }
//        }
//    }
    
    //MARK: Historic Bid
//    func downloadHistoricBid(from dict:[String:Any], urlString:String, completion: @escaping (Result<Data, Error>) -> Void) {
//        do{
//            let data = try JSONSerialization.data(withJSONObject: dict)
//            let postString = String(data: data, encoding: .utf8)!
//            let URL = URL(string: urlString)!
//            var request = URLRequest(url: URL)
//            request.httpMethod = "POST"
//            let contentLength = String(postString.count)
//            request.setValue(contentLength, forHTTPHeaderField: "Content-Length")
//            request.httpBody = postString.data(using: .utf8)
//            
//            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
//                if let error = error {
//                    completion(.failure(error))
//                    return
//                }
//                guard let data = data else {
//                    completion(.failure(NSError(domain: "Empty Data", code: 0)))
//                    return
//                }
//                completion(.success(data))
//            }
//            task.resume()
//        }catch{
//            print("Error in Downloading Historic Bid: \(error.localizedDescription)")
//        }
//    }
//    func downloadHistoricBid(
//        from dict: [String: Any],
//        urlString: String,
//        completion: @escaping (Result<Data, Error>) -> Void
//    ) {
//        do {
//            let data = try JSONSerialization.data(withJSONObject: dict)
//            guard let postString = String(data: data, encoding: .utf8),
//                  let bodyData = postString.data(using: .utf8) else {
//                completion(.failure(Errors.noData))
//                return
//            }
//            
//            // Compute Content-Length
//            let contentLength = String(postString.count)
//            
//            APIService.shared.fetchDownload(
//                urlString: urlString,
//                httpMethod: .POST,
//                body: bodyData,
//                headers: ["Content-Length": contentLength],
//                timeout: 300
//            ) { result in
//                switch result {
//                case .success(let tempURL):
//                    do {
//                        let fileData = try Data(contentsOf: tempURL)
//                        completion(.success(fileData))
//                    } catch {
//                        completion(.failure(error))
//                    }
//                case .failure(let error):
//                    completion(.failure(error))
//                }
//            }
//        } catch {
//            print("Error in Downloading Historic Bid: \(error.localizedDescription)")
//            completion(.failure(error))
//        }
//    }
    

//    
    
    //MARK: Bid Submission
    
//    func submitBid(httpBody: String, completion: @escaping (Result<String, Error>) -> Void){
//        guard let bodyData = httpBody.data(using: .utf8), let url = URL(string: EndPoint.shared.thirdpartyURL) else {
//            completion(.failure(Errors.invalidURL))
//            return}
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.httpBody = bodyData
//        let downloadTask = URLSession.shared.dataTask(with: request) { data, _, error in
//            if let error = error{
//                completion(.failure(error))
//                return}
//            guard let data = data else{
//                completion(.failure(Errors.noData))
//                return}
//            let dataString = String(data: data, encoding: .utf8)
//            completion(.success(dataString!))
//        }
//        downloadTask.resume()
//    }
    
    //MARK: Bid Submission Logging
    
//    func sendRawDataToServer(dict: NSMutableDictionary){
//        let url = EndPoint.shared.addSubmittedRawDataToServer
//        var urlRequest = URLRequest(url: URL(string: url)!)
//        
//        let jsondata = try! JSONSerialization.data(withJSONObject: dict)
//        let jsonString = String(data: jsondata, encoding: .utf8)
//            
//        urlRequest.httpBody = jsonString?.data(using: .utf8)
//        urlRequest.httpMethod = "POST"
//        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
//        
//        let dataTask = URLSession.shared.dataTask(with: urlRequest) { data, _, error in
//            if let error = error {
//                print("Error: \(error)")
//                //offline event
//                // send offlinedata
//            }
//            if let data = data {
//                do{
//                    let json = try JSONSerialization.jsonObject(with: data, options: [])
//                    print("Response JSON: \(json)")
//                }catch{
//                    print("Error parsing JSON: \(error)")
//                }
//            }
//        }
//        dataTask.resume()
//    }
    
//    
//    func logBidSubmission(dict:NSMutableDictionary){
//        
//        let url = EndPoint.shared.logCrewBidSubmitBidDetails
//        
//        var urlRequest = URLRequest(url: URL(string: url)!)
//        
//        let jsondata = try! JSONSerialization.data(withJSONObject: dict, options: [])
//        let jsonString = String(data: jsondata, encoding: .utf8)
//        
//        urlRequest.httpBody = jsonString?.data(using: .utf8)
//        urlRequest.httpMethod = "POST"
//        
//        let dataTask = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
//            if let error = error {
//                print("Error: \(error)")
//            }
//            if let data = data {
//                let httpResponse = response as! HTTPURLResponse
//                let range = response?.mimeType?.range(of: "application/json")
//                if httpResponse.statusCode == 200 && range != nil {
//                    do{
//                        let json = try JSONSerialization.jsonObject(with: data, options: [])
//                        print("Response JSON: \(json)")
//                    }catch{
//                        print("Error parsing JSON: \(error)")
//                    }
//                }
//                
//            }
//        }
//    }
    
//    func addSubmittedBid(dict:NSMutableDictionary, completion:@escaping (Bool)->Void){
//        
//        let url = EndPoint.shared.SaveBidSubmittedData
//        var urlRequest = URLRequest(url: URL(string: url)!)
//        
//        let jsonData = try! JSONSerialization.data(withJSONObject: dict, options: [])
//        let jsonString = String(data: jsonData, encoding: .utf8)
//        
//        urlRequest.httpBody = jsonString?.data(using: .utf8)
//        urlRequest.httpMethod = "POST"
//        
//        let dataTask = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
//            if let data = data {
//                let httpresponse = response as! HTTPURLResponse
//                let range = response?.mimeType?.range(of: "application/json")
//                if httpresponse.statusCode == 200 && range != nil {
//                    completion(true)
//                }
//            }
//        }
//        dataTask.resume()
//    }
    
}

