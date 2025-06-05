//
//  BIBidFileDownloadViewModel.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 05/06/25.
//

import Foundation

class BIBidFileDownloadViewModel {
    func fetchHistoricBidLines(filename: String, completion: @escaping (Result<URL, Error>) -> Void) {
        var dict: [String:Any] = [:]
            dict = [
                "Year": AppState.shared.mockDataYear!,
                "Month": AppState.shared.mockDataMonth!,
                "Round": GlobalBidInfo.shared.round,
                "Domicile": GlobalBidInfo.shared.base,
                "Position": GlobalBidInfo.shared.position.shortName,
                "FileName": filename
            ]
            
            let urlString = EndPoint.shared.DownloadHistoricalBidLineAll
            
            BIBidFileDownload.shared.downloadHistoricBid(from: dict, urlString: urlString) { result in
                switch result{
                case .success(let data):
                    do{
                        let jsonData = try JSONSerialization.jsonObject(with: data) as! [String: Any]
                        let dataBytes = jsonData["Data"] as? [Any]
                        let count = dataBytes!.count
                        let bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
                        for i in 0..<count{
                            let str = dataBytes![i] as? Int
                            bytes[i] = UInt8(str!)
                        }
                        let fileData = Data(bytes: bytes, count: count)
                        let directoryURL = BIBidInfo.shared.downloadDirectory()
                        let dataWriteURL = directoryURL.appendingPathComponent(filename)
                        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
                        try fileData.write(to: dataWriteURL, options: [])
                        completion(.success(dataWriteURL))
                      
                        
                    }catch{
                        print("Error parsing JSON data: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                    
                case .failure(let error):
                    print("Error: \(error)")
                    completion(.failure(error))
                }
                
            }
        
    }
    
    func fetchNewBidData(sessionKey: String, fileName: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let bidDownload = BIBidFileDownload()
        bidDownload.downloadBidFiles(sessionKey: sessionKey, filename: fileName){ result in
        completion(result)
        }
    }
}
