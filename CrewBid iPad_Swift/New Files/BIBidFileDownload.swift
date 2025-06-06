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
    //MARK: New Bid
    func downloadBidFiles(sessionKey:String, filename:String, completionHandler:@escaping (Result<URL, Error>) -> Void){
        let isRequestType = (filename as NSString).pathExtension.uppercased() == "TXT"
        let requestType = isRequestType ? "TXTPACKET" : "ZIPPACKET"
        let key = self.stringByAddingPercentEscapes(to: sessionKey)
        let bodyString = "REQUEST=\(requestType)&CREDENTIALS=\(key)&NAME=\(filename)"
        guard let bodyData = bodyString.data(using: .utf8), let url = URL(string: EndPoint.shared.thirdpartyURL) else {
            completionHandler(.failure(NetworkError.invalidURL))
            return}
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 300
        let downloadTask = URLSession.shared.downloadTask(with: request) { tempURL, _, error in
            if let error = error{
                completionHandler(.failure(error))
                return}
            guard let tempURL = tempURL else{
                completionHandler(.failure(NetworkError.noData))
                return}
            completionHandler(.success(tempURL))
        }
        downloadTask.resume()
    }
    
    //MARK: Historic Bid
    func downloadHistoricBid(from dict:[String:Any], urlString:String, completion: @escaping (Result<Data, Error>) -> Void) {
        do{
            let data = try JSONSerialization.data(withJSONObject: dict)
            let postString = String(data: data, encoding: .utf8)!
            let URL = URL(string: urlString)!
            var request = URLRequest(url: URL)
            request.httpMethod = "POST"
            let contentLength = String(postString.count)
            request.setValue(contentLength, forHTTPHeaderField: "Content-Length")
            request.httpBody = postString.data(using: .utf8)
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let data = data else {
                    completion(.failure(NSError(domain: "Empty Data", code: 0)))
                    return
                }
                completion(.success(data))
            }
            task.resume()
        }catch{
            print("Error in Downloading Historic Bid: \(error)")
        }
    }
    
    private func stringByAddingPercentEscapes(to unescapedString: String) -> String {
        let allowedCharacterSet = CharacterSet(charactersIn: ";/?:@&=+$,").inverted
        return unescapedString.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!
    }
}

