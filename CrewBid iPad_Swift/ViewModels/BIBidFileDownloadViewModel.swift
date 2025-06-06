//
//  BIBidFileDownloadViewModel.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 05/06/25.
//

import Foundation
import ZipArchive

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
                        let unzipSuccess = SSZipArchive.unzipFile(atPath: dataWriteURL.path, toDestination: directoryURL.path)
                        if unzipSuccess{
                            completion(.success(directoryURL))
                        }else{
                            completion(.failure(NetworkError.unzipFailed))
                        }
                        
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
        let filesToDownload = BIBidInfo.shared.bidDataFiles()
        var fileIterator = filesToDownload!.makeIterator()
        func downloadNext() {
            guard let nextFile = fileIterator.next() else {
                // All files done
                completion(.success(BIBidInfo.shared.downloadDirectory()))
                return
            }
            bidDownload.downloadBidFiles(sessionKey: sessionKey, filename: nextFile){ result in
                switch result{
                case .success(let tempURL):
                    let destinationDir = BIBidInfo.shared.downloadDirectory()
                    let destinationURL = destinationDir.appendingPathComponent(fileName)
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
                            downloadNext()
//                            completion(.success(destinationDir))
                        }else{
                            completion(.failure(NetworkError.unzipFailed))
                        }
                    }catch{
                        completion(.failure(error))
                    }
                case .failure(let error):
                    print("Error downloading bid file: \(error)")
                    completion(.failure(error))
                }
            }
        }
        downloadNext()
    }


}
