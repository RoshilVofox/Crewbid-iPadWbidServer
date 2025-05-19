//
//  BIBidFileDownload.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 11/05/25.
//

import Foundation
import ZipArchive

class BIBidFileDownload: NSObject{
    
    func downloadBidFiles(sessionKey:String, filename:String, completionHandler:@escaping (Result<URL, Error>) -> Void){
        let isRequestType = (filename as NSString).pathExtension.uppercased() == "TXT"
        let requestType = isRequestType ? "TXTPACKET" : "ZIPPACKET"
        let key = sessionKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
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
            DispatchQueue.main.async{
                if let error = error{
                    completionHandler(.failure(error))
                    return}
                guard let tempURL = tempURL else{
                    completionHandler(.failure(NetworkError.noData))
                    return}
                let destinationDir = BIBidInfo().downloadDirectory()
                let destinationURL = destinationDir.appendingPathComponent(filename)
                do{
                    // Create destination directory if needed
                    try FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true, attributes: nil)
                    // Remove existing file if present
                    if FileManager.default.fileExists(atPath: destinationURL.path){
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    // Move downloaded file
                    try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                    let success = SSZipArchive.unzipFile(atPath: destinationURL.path, toDestination: destinationDir.path)
                    if success{
                        completionHandler(.success(destinationDir))
                    }else{
                        completionHandler(.failure(NetworkError.unzipFailed))
                    }
                }catch{
                    completionHandler(.failure(error))
                }
            }
        }
        downloadTask.resume()
    }
}

