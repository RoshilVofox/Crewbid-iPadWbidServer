//
//  BIBidFileDownloadViewModel.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 05/06/25.
//

import Foundation
import ZipArchive

private var didCheckFlightData: Bool = false

class BIBidFileDownloadViewModel {
    func fetchHistoricBidLines(
        filename: String,
        useDataRest: Bool = false,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let year = AppState.shared.mockDataYear!
        let month = AppState.shared.mockDataMonth!
        let round = GlobalBidInfo.shared.round
        let base = GlobalBidInfo.shared.base
        let position = GlobalBidInfo.shared.position.shortName

        //Choose endpoint
        let urlString = useDataRest
            ? EndPoint.shared.DownloadHistoricalDataRest
            : EndPoint.shared.DownloadHistoricalBidLineAll

        if !didCheckFlightData {
            checkFlightData()
            didCheckFlightData = true
        }

        let proceedWithDownload: () -> Void = {
            let dict: [String: Any] = [
                "Year": year,
                "Month": month,
                "Round": round,
                "Domicile": base,
                "Position": position,
                "FileName": filename
            ]

            guard let body = try? JSONSerialization.data(withJSONObject: dict) else {
                completion(.failure(Errors.noData))
                return
            }

            APIService.shared.fetch(
                urlString: urlString,
                method: .POST,
                body: body,
                headers: ["Content-Length": String(body.count)],
                parse: { data in
                    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        throw Errors.decodingError
                    }
                    return json
                },
                completion: { (result: Result<[String: Any], Errors>) in
                    switch result {
                    case .success(let jsonData):
                        guard let dataBytes = jsonData["Data"] as? [Int] else {
                            completion(.failure(Errors.noData))
                            return
                        }
                        
                        let fileData = Data(dataBytes.map { UInt8($0) })
                        
                        do {
                            let directoryURL = BIBidInfo.shared.downloadDirectory()
                            let dataWriteURL = directoryURL.appendingPathComponent(filename)
                            
                            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
                            try fileData.write(to: dataWriteURL, options: [])
                            
                            if filename.lowercased().hasSuffix(".737") {
                                let unzipSuccess = SSZipArchive.unzipFile(
                                    atPath: dataWriteURL.path,
                                    toDestination: directoryURL.path
                                )
                                if unzipSuccess {
                                    completion(.success(directoryURL))
                                } else {
                                    completion(.failure(Errors.unzipFailed))
                                }
                            } else {
                                completion(.success(directoryURL))
                            }
                        } catch {
                            completion(.failure(error))
                        }
                        
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            )
        }

        if round == 1 && GlobalBidInfo.shared.position == .FlightAttendant {
            CBUtils.getFALISTWB4JSONFromServer {
                proceedWithDownload()
            }
        } else if round == 2 && GlobalBidInfo.shared.position != .FlightAttendant {
            CBUtils.getMissingTripJSON(year: year, month: month, round: round, base: base, position: position) { _ in
                proceedWithDownload()
            }
        } else {
            proceedWithDownload()
        }
    }
    
//    func fetchNewBidData(sessionKey: String, fileName: String, completion: @escaping (Result<URL, Error>) -> Void) {
//        let bidDownload = BIBidFileDownload()
//        let filesToDownload = BIBidInfo.shared.bidDataFiles()
//        var fileIterator = filesToDownload!.makeIterator()
//        let dataSource = GlobalBidInfo.shared
//        if dataSource.round == 1 && dataSource.position == .FlightAttendant{
//            CBUtils.getFALISTWB4JSONFromServer(){
//                print("FA List WB4 JSON fetched and saved")
//                downloadNext()
//            }
//        }else if dataSource.round == 2 && dataSource.position != .FlightAttendant {
//            CBUtils.getMissingTripJSON( year: dataSource.year, month: dataSource.month, round: dataSource.round, base: dataSource.base, position: dataSource.position.shortName) { status in
//                if status {
//                    print("MissingTripInfo is now populated.")
//                } else {
//                    print("Failed to get missing trip info.")
//                }
//                downloadNext()
//            }
//        } else {
//            downloadNext()
//        }
//        
//        func downloadNext() {
//            guard let nextFile = fileIterator.next() else {
//                completion(.success(BIBidInfo.shared.downloadDirectory()))
//                self.performPostDownloadTasks()
//                return
//            }
//            bidDownload.downloadBidFiles(sessionKey: sessionKey, filename: nextFile){ result in
//                switch result{
//                case .success(let tempURL):
//                    let destinationDir = BIBidInfo.shared.downloadDirectory()
//                    let destinationURL = destinationDir.appendingPathComponent(nextFile)
//                    do{
//                        // Create destination directory if needed
//                        try FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true, attributes: nil)
//                        // Remove existing file if present
//                        if FileManager.default.fileExists(atPath: destinationURL.path){
//                            try FileManager.default.removeItem(at: destinationURL)
//                        }
//                        // Move downloaded file
//                        try FileManager.default.moveItem(at: tempURL, to: destinationURL)
//                        let success = SSZipArchive.unzipFile(atPath: destinationURL.path, toDestination: destinationDir.path)
//                        if success{
//                            downloadNext()
//                        }else{
//                            completion(.failure(Errors.unzipFailed))
//                        }
//                    }catch{
//                        completion(.failure(error))
//                    }
//                case .failure(let error):
//                    print("Error downloading bid file: \(error)")
//                    completion(.failure(error))
//                }
//            }
//        }
//    }
    
    func fetchNewBidData(sessionKey: String, fileName: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let filesToDownload = BIBidInfo.shared.bidDataFiles() ?? []
        var fileIterator = filesToDownload.makeIterator()
        let dataSource = GlobalBidInfo.shared

        func downloadNext() {
            guard let nextFile = fileIterator.next() else {
                performPostDownloadTasks()
                completion(.success(BIBidInfo.shared.downloadDirectory()))
                return
            }

            downloadFile(sessionKey: sessionKey, filename: nextFile) { result in
                switch result {
                case .success(let tempURL):
                    let destinationDir = BIBidInfo.shared.downloadDirectory()
                    let destinationURL = destinationDir.appendingPathComponent(nextFile)

                    do {
                        // Ensure base directory exists
                        try FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true, attributes: nil)

                        // Clean up old file if it exists
                        if FileManager.default.fileExists(atPath: destinationURL.path) {
                            try FileManager.default.removeItem(at: destinationURL)
                        }

                        // Move the downloaded file into the permanent directory
                        try FileManager.default.moveItem(at: tempURL, to: destinationURL)

                        // Force flush: open + close handle
                        let handle = try FileHandle(forReadingFrom: destinationURL)
                        try handle.close()
                        
                        // Unzip into a fresh temp folder first
                        let tempUnzipDir = destinationDir.appendingPathComponent(UUID().uuidString)
                        try FileManager.default.createDirectory(at: tempUnzipDir, withIntermediateDirectories: true, attributes: nil)

                        let unzipSuccess = SSZipArchive.unzipFile(atPath: destinationURL.path, toDestination: tempUnzipDir.path)

                        if unzipSuccess {
                            // Move unzipped contents into destinationDir
                            let contents = try FileManager.default.contentsOfDirectory(atPath: tempUnzipDir.path)
                            for item in contents {
                                let src = tempUnzipDir.appendingPathComponent(item)
                                let dst = destinationDir.appendingPathComponent(item)
                                if FileManager.default.fileExists(atPath: dst.path) {
                                    try FileManager.default.removeItem(at: dst)
                                }
                                try FileManager.default.moveItem(at: src, to: dst)
                            }
                            // Clean up temp unzip folder
                            try FileManager.default.removeItem(at: tempUnzipDir)

                            downloadNext()
                        } else {
                            // Clean up temp unzip folder if unzip failed
                            try? FileManager.default.removeItem(at: tempUnzipDir)
                            completion(.failure(Errors.unzipFailed))
                        }

                    } catch {
                        completion(.failure(error))
                    }

                case .failure(let error):
                    print("Error downloading bid file: \(error)")
                    completion(.failure(error))
                }
            }
        }

        func downloadFile(sessionKey: String, filename: String, completion: @escaping (Result<URL, Error>) -> Void) {
            let isTxt = (filename as NSString).pathExtension.uppercased() == "TXT"
            let requestType = isTxt ? "TXTPACKET" : "ZIPPACKET"
            let key = sessionKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? sessionKey
            let bodyString = "REQUEST=\(requestType)&CREDENTIALS=\(key)&NAME=\(filename)"
            guard let bodyData = bodyString.data(using: .utf8) else {
                completion(.failure(Errors.noData))
                return
            }

            APIService.shared.fetchDownload(
                urlString: EndPoint.shared.thirdpartyURL,
                httpMethod: .POST,
                body: bodyData,
                headers: nil,
                timeout: 300
            ) { completion($0.mapError { $0 as Error }) }
        }

        if dataSource.round == 1 && dataSource.position == .FlightAttendant {
            CBUtils.getFALISTWB4JSONFromServer {
                print("FA List WB4 JSON fetched and saved")
                downloadNext()
            }
        } else if dataSource.round == 2 && dataSource.position != .FlightAttendant {
            CBUtils.getMissingTripJSON(
                year: dataSource.year,
                month: dataSource.month,
                round: dataSource.round,
                base: dataSource.base,
                position: dataSource.position.shortName
            ) { status in
                print(status ? "MissingTripInfo populated." : "Failed to get missing trip info.")
                downloadNext()
            }
        } else {
            downloadNext()
        }
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
