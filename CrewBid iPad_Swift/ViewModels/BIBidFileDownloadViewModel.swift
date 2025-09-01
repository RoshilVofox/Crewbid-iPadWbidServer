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
        let year = AppState.shared.mockDataYear!
        let month = AppState.shared.mockDataMonth!
        let round = GlobalBidInfo.shared.round
        let base = GlobalBidInfo.shared.base
        let position = GlobalBidInfo.shared.position.shortName
        let urlString = EndPoint.shared.DownloadHistoricalBidLineAll
        CBUtils.downloadFlightData()
        let proceedWithDownload: () -> Void = {
                let dict: [String: Any] = ["Year": year,"Month": month,"Round": round,"Domicile": base,"Position": position,"FileName": filename]
                BIBidFileDownload.shared.downloadHistoricBid(from: dict, urlString: urlString) { result in
                    switch result {
                    case .success(let data):
                        do {
                            let jsonData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                            let dataBytes = jsonData!["Data"] as? [Any]
                            let count = dataBytes!.count
                            let bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
                            for i in 0..<count {
                                if let str = dataBytes![i] as? Int {
                                    bytes[i] = UInt8(str)
                                }
                            }
                            let fileData = Data(bytes: bytes, count: count)
                            bytes.deallocate()

                            let directoryURL = BIBidInfo.shared.downloadDirectory()
                            let dataWriteURL = directoryURL.appendingPathComponent(filename)
                            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
                            try fileData.write(to: dataWriteURL, options: [])

                            let unzipSuccess = SSZipArchive.unzipFile(atPath: dataWriteURL.path, toDestination: directoryURL.path)
                            if unzipSuccess {
                                completion(.success(directoryURL))
                            } else {
                                completion(.failure(NetworkError.unzipFailed))
                            }

                        } catch {
                            print("Error parsing JSON data: \(error.localizedDescription)")
                            completion(.failure(error))
                        }

                    case .failure(let error):
                        print("Download error: \(error)")
                        completion(.failure(error))
                    }
                }
            }
            if GlobalBidInfo.shared.round == 1 && GlobalBidInfo.shared.position == .FlightAttendant{
                CBUtils.getFALISTWB4JSONFromServer{
                    proceedWithDownload()
                }
            }else if round == 2 && GlobalBidInfo.shared.position != .FlightAttendant {
                CBUtils.getMissingTripJSON(year: year, month: month, round: round, base: base, position: position) { success in
                    if success {
                        print("MissingTripInfo loaded.")
                    } else {
                        print("MissingTripInfo fetch failed.")
                    }
                    proceedWithDownload()
                }
            } else {
                proceedWithDownload()
            }
    }
    
    func fetchNewBidData(sessionKey: String, fileName: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let bidDownload = BIBidFileDownload()
        let filesToDownload = BIBidInfo.shared.bidDataFiles()
        var fileIterator = filesToDownload!.makeIterator()
        let dataSource = GlobalBidInfo.shared
        if dataSource.round == 1 && dataSource.position == .FlightAttendant{
            CBUtils.getFALISTWB4JSONFromServer(){
                print("FA List WB4 JSON fetched and saved")
                downloadNext()
            }
        }else if dataSource.round == 2 && dataSource.position != .FlightAttendant {
            CBUtils.getMissingTripJSON( year: dataSource.year, month: dataSource.month, round: dataSource.round, base: dataSource.base, position: dataSource.position.shortName) { status in
                if status {
                    print("MissingTripInfo is now populated.")
                } else {
                    print("Failed to get missing trip info.")
                }
                downloadNext()
            }
        } else {
            downloadNext()
        }
        
        func downloadNext() {
            guard let nextFile = fileIterator.next() else {
                completion(.success(BIBidInfo.shared.downloadDirectory()))
                self.performPostDownloadTasks()
                return
            }
            bidDownload.downloadBidFiles(sessionKey: sessionKey, filename: nextFile){ result in
                switch result{
                case .success(let tempURL):
                    let destinationDir = BIBidInfo.shared.downloadDirectory()
                    let destinationURL = destinationDir.appendingPathComponent(nextFile)
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
//        downloadNext() // Remove This // By Raja
    }

    private func performPostDownloadTasks(){
        checkCrewBidUpdateFile()
    }
    
    private func checkCrewBidUpdateFile(){
        DispatchQueue.main.async {
            CBUtils.downloadCrewBidUpdateFile(){ (result:Bool?) in
                if result!{
                    print("Crewbid Update file downloaded successfully")
                    self.checkFlightData()
                }
            }
        }
    }
    
    private func checkFlightData(){
        CBUtils.downloadFlightData(){ (result:Bool?) in
            if result!{
                print("Flight Data downloaded successfully")
            }
        }
        //needs code
    }
}
