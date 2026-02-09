//
//  BISwaBidDataDownload.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/08/25.
//

import Foundation
import ZipArchive

class BISwaBidDataDownload{
    
    var urlInfo: String?
    var bidInfo: String = ""
    var pageSize: String = ""
    var dataSource:BIBidInfoDataSource?
    var packetID:String = ""

    
    init?(dataSource:BIBidInfoDataSource = GlobalBidInfo.shared) {
        
        guard !dataSource.base.isEmpty,
              dataSource.month > 0,
              dataSource.year > 0,
              dataSource.round > 0
        else {
            print("Missing a required property in GlobalBidInfo")
            return nil
        }
        self.dataSource = dataSource
        let formattedMonth = String(format: "%02d", dataSource.month)
        let positionShort = CBUtils.shortName(for: dataSource.position)

        self.packetID = "\(dataSource.base)\(dataSource.year)\(formattedMonth)\(dataSource.round)"
        self.bidInfo = "\(dataSource.base)\(positionShort)\(dataSource.year)\(formattedMonth)\(dataSource.round)"
        self.pageSize = "500"
    }
    
    
    func kCBSwaServiceURL() -> String{
        let env = UserDefaults.standard.string(forKey: "SwaApiEnv")
        var baseURL = ""
        if env == "Dev"{
            baseURL = "https://itest.service.east.0.crewbid.dev.swalife.com"
        }else if env == "QA"{
            baseURL = "https://service.east.0.crewbid.qa.swalife.com/itest"
        }else{
            baseURL = "https://service.crewbid.swalife.com/golden"
        }
        return baseURL
    }
    
    private func hasNextPage(_ result: [String: Any]) -> Bool {
        guard
            let page = result["page"] as? [String: Any],
            let totalPages = page["totalPages"] as? Int,
            let pageNumber = page["number"] as? Int,
            let totalElements = page["totalElements"] as? Int
        else {
            return false
        }
        
        if totalElements == 0 {
            return false
        }
        
        return totalPages != pageNumber + 1
    }
    
    
    //MARK: Get Seniority List
    func getSwaSeniorityList(completion: @escaping (Result<Void, Error>) -> Void){
        var urlTemplate = ""
        var keyPath = ""
        if self.dataSource?.round == 1{
            urlTemplate = "\(self.kCBSwaServiceURL())/if-line-base-auction/bid-round/\(self.packetID)/seniority?page=%ld&size=\(self.pageSize)"
            keyPath = "IFLineBaseAuctionSeniorities"
        }else{
            var packetID = self.packetID
            let lastChar = packetID.substring(to: packetID.length - 1)
            packetID = lastChar.appending("1")
            urlTemplate = "\(self.kCBSwaServiceURL())/if-line-base-auction/bid-round/\(packetID)/reserve-awards?page=%ld&size=\(self.pageSize)"
            keyPath = "IFLineBaseAuctionReserveAwards"
        }
        
        
        self.fetchPaginatedData(urlTemplate: urlTemplate, keyPath: keyPath){ result in
            switch result{
                
            case .success(let resultDict):
                
                let writeFileMsg = CBUtils.writeJSONDictToFile(resultDict, fileName: String(format: "%@-SeniorityList.json", self.bidInfo))
                
                if writeFileMsg == nil {
                    completion(.success(()))
                    
                }else{
                    
                    let userInfo: [String: Any] = [NSLocalizedDescriptionKey: writeFileMsg!]
                    let nsError = NSError(domain: BIBidInfoErrorDomain, code: 400, userInfo: userInfo)
                    completion(.failure(nsError))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    //MARK: Get Cover Letter
    func getSwaCoverLetter(completion: @escaping (Result<Void, Error>) -> Void){
        let urlString = "\(self.kCBSwaServiceURL())/if-line-base-auction/bid-round/\(self.packetID)/cover-letter"
        
        let headers: [String: String] = [
            "Authorization": "Bearer \(KeychainHelper.retrieveTokenFromKeyChain()!)"
            ]
        
        APIService.shared.fetchDownload(
            urlString: urlString,
            httpMethod: .GET,
            headers: headers,
            completion: {result in
                switch result{
                case .success(let tempURL):
                    do{
                        let fileManager = FileManager.default
                        let documentsDirectory = try fileManager.url(for: .documentDirectory,
                                                                     in: .userDomainMask,
                                                                     appropriateFor: nil,
                                                                     create: false)
                        let lastComponent = URL(string: urlString)!.lastPathComponent
                        let destinationURL = documentsDirectory.appendingPathComponent("\(self.bidInfo)-\(lastComponent).pdf")
                        
                        if fileManager.fileExists(atPath: destinationURL.path) {
                            try fileManager.removeItem(at: destinationURL)
                        }
                        try fileManager.moveItem(at: tempURL, to: destinationURL)
                        completion(.success(()))
                    }catch{
                        let userInfo: [String: Any] = [NSLocalizedDescriptionKey: "Something went wrong"]
                        let nsError = NSError(domain: BIBidInfoErrorDomain, code: 400, userInfo: userInfo)
                        completion(.failure(nsError))
                        
                    }
                case .failure(let error):
                    let modifiedError = self.error(byChangingStatusCode: error as NSError, newStatusCode: BIBidInfoErrorCode.bidDataDownload.rawValue)
                    completion(.failure(modifiedError))
                }
            })
        
    }
    

    //MARK: Get Bid Data
    func downloadBidData(type: String, completion: @escaping (Result<Void, Error>) -> Void){
        
        let pageCountSize = type == "lines" ? self.pageSize : "1000"
        let urlTemplate = "\(self.kCBSwaServiceURL())/lines-pairings/\(type)/bid-round/\(self.packetID)?page=%ld&size=\(pageCountSize)"
        let keyPath = type == "lines" ? "LinesLines" : "LinesPairings"
        
        self.fetchPaginatedData(urlTemplate: urlTemplate, keyPath: keyPath){ result in
            switch result{
            case .success(let resultDict):
                if type == "pairings"{
                    NotificationCenter.default.post(
                        name: Notification.Name("UpdateProgress"),
                        object: nil,
                        userInfo: ["progress": Float(0.60)]
                    )
                }
                
                let writeFileMsg = CBUtils.writeJSONDictToFile(resultDict, fileName: String(format: "%@-%@.json", self.bidInfo, type))
                
                if writeFileMsg == nil {
                    completion(.success(()))
                    
                }else{
                    
                    let userInfo: [String: Any] = [NSLocalizedDescriptionKey: writeFileMsg!]
                    let nsError = NSError(domain: BIBidInfoErrorDomain, code: 400, userInfo: userInfo)
                    completion(.failure(nsError))
                }
                
            case .failure(let error):
                completion(.failure(error))
                
            }
            
        }
        
    }
    
    //MARK: Get Buddy Bids
    func getBuddyBids(user_id: String, completion: @escaping (Result<Void, Error>) -> Void){
        
        self.checkCrewBidUpdateFile()
        self.checkFlightData()
//        if self.dataSource?.round == 1{
//            CBUtils.getFALISTWB4JSONFromServer()
//        }
        
        let userID = user_id.replacingOccurrences(of: "e", with: "")
        let urlTemplate = "\(self.kCBSwaServiceURL())/if-line-base-auction/buddies?employeeId=\(userID)"
        
        let headers: [String: String] = [
            "Content-Type": "application/hal+json",
            "Authorization": "Bearer \(KeychainHelper.retrieveTokenFromKeyChain()!)",
            "x-swa-user-department": "IF",
            "Postman-Token": "d6c9db45-8ea6-4dd9-9b7e-f77f2baa8b8b"
        ]
        
        APIService.shared.fetch(
            urlString: urlTemplate,
            method: .GET,
            headers: headers,
            parse: {data in
                try! JSONSerialization.jsonObject(with: data)
            },
            completion: {result in
                switch result{
                case .success(let response):
                    if let resultDict = response as? [String:Any]{
                        let writeFileMsg = CBUtils.writeJSONDictToFile(resultDict, fileName: String(format: "%@-BuddyBidIDs.json", self.bidInfo))
                        
                        if writeFileMsg == nil {
                            completion(.success(()))
                            
                        }else{
                            
                            let userInfo: [String: Any] = [NSLocalizedDescriptionKey: writeFileMsg!]
                            let nsError = NSError(domain: BIBidInfoErrorDomain, code: 400, userInfo: userInfo)
                            completion(.failure(nsError))
                        }
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            })
    }
    
    
    //MARK: Get Meta Data
    
    func downloadMetaData(urlInfo:String, completion: @escaping (Result<[String:Any], Error>) -> Void){
        let urlString = String(format:"%@/if-line-base-auction/bid-round/%@/metadata", self.kCBSwaServiceURL(), urlInfo)
        
        let headers: [String: String] = [
            "Content-Type": "application/hal+json",
            "Authorization": "Bearer \(KeychainHelper.retrieveTokenFromKeyChain()!)",
            "x-swa-user-department": "IF",
            "Postman-Token": "d6c9db45-8ea6-4dd9-9b7e-f77f2baa8b8b"
        ]
        
        APIService.shared.fetch(
            urlString: urlString,
            method: .GET,
            headers: headers,
            allowNon200Status: true,
            parse: {data in
                try JSONSerialization.jsonObject(with: data)
            },
            completion: {result in
                switch result{
                case .success(let response):
                    guard let dict = response as? [String: Any] else {
                        completion(.failure(Errors.invalidResponse))
                        return
                    }
                    if let errTitle = dict["error"] as? String {

                        let statusCode = dict["status"] as? Int ?? -1
                        let message = dict["message"] as? String ?? "Unknown error"
                        let path = dict["path"] as? String ?? "N/A"

                        let fullMessage =
                            "Error \(statusCode): \(errTitle)\n\n\(message)\n\nAPI path: \(path)"

                        let error = NSError(
                            domain: "HTTPErrorDomain",
                            code: statusCode,
                            userInfo: [
                                NSLocalizedDescriptionKey: fullMessage,
                                NSLocalizedFailureReasonErrorKey: fullMessage
                            ]
                        )

                        completion(.failure(Errors.other(error)))
                        return
                    }
                    completion(.success(dict))
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        
    }

    func checkCrewBidUpdateFile(){
        DispatchQueue.global(qos: .background).async {
            CBUtils.downloadCrewBidUpdateFile(){ _ in
            }
        }
    }
    
    func checkFlightData(){
        DispatchQueue.global(qos: .background).async {
            CBUtils.downloadFlightData(){ _ in
            }
        }
    }
    
    
    //MARK: Get Historic Bid
    func downloadHistoricBid(completion: @escaping (Result<Void, Error>) -> Void){
        var dictHistoric: [String:Any] = [:]
        dictHistoric["Year"] = AppState.shared.mockDataYear
        dictHistoric["Month"] = AppState.shared.mockDataMonth
        dictHistoric["Round"] = self.dataSource?.round
        dictHistoric["Domicile"] = self.dataSource?.base
        dictHistoric["Position"] = self.dataSource?.position.shortName
        dictHistoric["FileName"] = BIBidInfo.shared.bidDataFilename()
        if CBUtils.isSwaTypeOfFileDownload(){
            dictHistoric["FileName"] = NSNull()
        }
        
        let urlString = EndPoint.shared.DownloadHistoricalDataRest
        
        let headers: [String: String] = [
            "Content-Type": "application/hal+json",
            "Authorization": "Bearer \(KeychainHelper.retrieveTokenFromKeyChain()!)",
            "x-swa-user-department": "IF",
            "Postman-Token": "d6c9db45-8ea6-4dd9-9b7e-f77f2baa8b8b"
        ]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: dictHistoric, options: [])
        
        DownloadManager.shared.fetch(
            urlString: urlString,
            httpMethod: .POST,
            body: jsonData,
            headers: headers
        ) { result in
            switch result {
            case .success(let tempFileURL):
                do {
                    // 1. Read downloaded file data
                    let fileData = try Data(contentsOf: tempFileURL)
                    
                    // 2. Parse JSON
                    guard let json = try JSONSerialization.jsonObject(with: fileData) as? [String: Any] else {
                        completion(.failure(Errors.decodingError))
                        return
                    }
                    
                    // 3. Check for new SWA API type
                    if let swaFiles = json["lstSWAAPIFiles"] as? [[String: Any]] {
                        for fileInfo in swaFiles {
                            autoreleasepool {
                                guard let title = fileInfo["Title"] as? String,
                                      let byteArray = fileInfo["Data"] as? [NSNumber] else {
                                    print("Invalid file data format")
                                    return
                                }
                                
                                if title == "SWAData"{
                                    // 3a. Convert bytes to Data
                                    var bytes = byteArray.map { $0.uint8Value }
                                    let data = Data(bytes: &bytes, count: bytes.count)
                                    
                                    // 3b. Get documents directory
                                    let fileManager = FileManager.default
                                    if let docsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                                        let fileURL = docsPath.appendingPathComponent("\(title).zip")
                                        
                                        // 3c. Delete old .zip if exists
                                        if fileManager.fileExists(atPath: fileURL.path) {
                                            try? fileManager.removeItem(at: fileURL)
                                        }
                                        
                                        // 3d. Write new .zip file
                                        do {
                                            try data.write(to: fileURL, options: .atomic)
                                        } catch {
                                            print("Failed to write file: \(fileURL.path)")
                                            completion(.failure(Errors.other(error)))
                                            return
                                        }
                                        
                                        // 3e. Unzip file
                                        SSZipArchive.unzipFile(atPath: fileURL.path, toDestination: docsPath.path)
                                        
                                        // 3f. Remove .zip after extraction
                                        if fileManager.fileExists(atPath: fileURL.path) {
                                            try? fileManager.removeItem(at: fileURL)
                                        }
                                    }
                                }
                            }
                        }
                        completion(.success(()))
                        return
                    }else{
                        // 4. Old API type (single file data)
                        let userInfo: [String: Any] = [NSLocalizedDescriptionKey: "Bid data not available"]
                        let nsError = NSError(domain: BIBidInfoErrorDomain, code: 400, userInfo: userInfo)
                        
                        //                    guard let responseDict = json as [String: Any],
                        guard let dataBytes = json["Data"] as? [Int],
                              !dataBytes.isEmpty else {
                            let modifiedError = self.error(byChangingStatusCode: nsError, newStatusCode: BIBidInfoErrorCode.bidDataDownload.rawValue)
                            completion(.failure(modifiedError))
                            return
                        }
                        
                        // 4a. Write .zip file from dataBytes
                        let fileData = Data(dataBytes.map { UInt8($0) })
                        let downloadDir = BIBidInfo.shared.downloadDirectory()
                        let dirPath = downloadDir.path
                        let fm = FileManager.default
                        
                        if !fm.fileExists(atPath: dirPath) {
                            try? fm.createDirectory(atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
                        }
                        
                        let fileURL = downloadDir.appendingPathComponent(BIBidInfo.shared.bidDataFilename())
                        try fileData.write(to: fileURL)
                        
                        // 4b. Unzip all .zip/.737 files found in directory
                        let fileURLs = try fm.contentsOfDirectory(at: downloadDir, includingPropertiesForKeys: nil)
                        for fileURL in fileURLs {
                            let ext = fileURL.pathExtension.lowercased()
                            if ext == "zip" || ext == "737" {
                                let unzipDirectory = downloadDir.path
                                let success = SSZipArchive.unzipFile(atPath: fileURL.path, toDestination: unzipDirectory)
                                
                                if !success {
                                    let modifiedErr = self.error(byChangingStatusCode: nsError, newStatusCode: BIBidInfoErrorCode.bidDataDownload.rawValue)
                                    completion(.failure(modifiedErr))
                                    return
                                }
                            }
                        }
                        
                        completion(.success(()))
                        
                        }
                }
                catch {
                   print("Failed to read downloaded file: \(error.localizedDescription)")
                   completion(.failure(Errors.other(error)))
               }


            case .failure(let error):
                completion(.failure(error))
            }
        }
        
    }
    
    func getAwards(completion: @escaping (Result<[String:Any],Error>) -> Void){
        let urlTemplate = "\(self.kCBSwaServiceURL())/if-line-base-auction/bid-round/\(packetID)/line-awards?page=%ld&size=\(self.pageSize)"
        
        self.fetchPaginatedData(urlTemplate: urlTemplate, keyPath:"IFLineBaseAuctionAwards"){ result in
            switch result{
            case .success(let resultDict):
                completion(.success(resultDict))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
    func getMrtAwards(completion: @escaping (Result<[String:Any],Error>) -> Void){
        let urlTemplate = "\(self.kCBSwaServiceURL())/if-line-base-auction/bid-round/\(packetID)/mrt-awards?page=%ld&size=\(self.pageSize)"
        
        self.fetchPaginatedData(urlTemplate: urlTemplate, keyPath:"IFLineBaseAuctionAwards"){ result in
            switch result{
            case .success(let resultDict):
                completion(.success(resultDict))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getJobShareAwards(completion: @escaping (Result<[String:Any],Error>) -> Void){
        let urlTemplate = "\(self.kCBSwaServiceURL())/if-line-base-auction/bid-round/\(packetID)/jobshare-awards?page=%ld&size=\(self.pageSize)"
        
        self.fetchPaginatedData(urlTemplate: urlTemplate, keyPath:"IFLineBaseAuctionAwards"){ result in
            switch result{
            case .success(let resultDict):
                completion(.success(resultDict))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getReserveDataForAward(completion: @escaping (Result<[String:Any],Error>) -> Void){
        let urlTemplate = "\(self.kCBSwaServiceURL())/if-line-base-auction/bid-round/\(packetID)/reserve-awards?page=%ld&size=\(self.pageSize)"
        
        self.fetchPaginatedData(urlTemplate: urlTemplate, keyPath:"IFLineBaseAuctionAwards"){ result in
            switch result{
            case .success(let resultDict):
                completion(.success(resultDict))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func fetchPaginatedData(urlTemplate: String,keyPath: String,completion: @escaping (Result<[String: Any], Errors>) -> Void) {
        fetchPage(urlTemplate: urlTemplate, pageNumber: 0) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))

            case .success(let firstPage):
                guard
                    let pageInfo = firstPage["page"] as? [String: Any],
                    let totalPages = pageInfo["totalPages"] as? Int
                else {
                    completion(.success(firstPage))
                    return
                }
                if totalPages <= 1 {
                    completion(.success(firstPage))
                    return
                }
                let group = DispatchGroup()
                let mergeQueue = DispatchQueue(label: "com.crewBid.pagination.merge", attributes: .concurrent)

                var accumulated = firstPage
                var capturedError: Errors?

                for page in 1..<totalPages {
                    group.enter()

                    self.fetchPage(urlTemplate: urlTemplate, pageNumber: page) { result in
                        switch result {
                            
                        case .success(let pageDict):
                            mergeQueue.async(flags: .barrier) {
                                self.mergePage(pageDict,into: &accumulated,keyPath: keyPath)
                                group.leave()
                            }
                
                        case .failure(let error):
                            capturedError = error
                            group.leave()
                        }
                    }
                }

                group.notify(queue: .global(qos: .userInitiated)) {
                    if let error = capturedError {
                        completion(.failure(error))
                    } else {
                        completion(.success(accumulated))
                    }
                }
            }
        }
    }
    
    private func fetchPage(urlTemplate: String,pageNumber: Int,completion: @escaping (Result<[String: Any], Errors>) -> Void) {
        let urlString = String(format: urlTemplate, pageNumber)

        let headers: [String: String] = [
            "Content-Type": "application/hal+json",
            "Authorization": "Bearer \(KeychainHelper.retrieveTokenFromKeyChain()!)",
            "x-swa-user-department": "IF"
        ]

        APIService.shared.fetch(
            urlString: urlString,
            method: .GET,
            headers: headers,
            parse: { data in
                try JSONSerialization.jsonObject(with: data)
            },
            completion: { result in
                switch result {
                case .success(let parsed):
                    guard let dict = parsed as? [String: Any] else {
                        completion(.failure(.other(NSError(
                            domain: "Pagination",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Invalid JSON"]
                        ))))
                        return
                    }
                    completion(.success(dict))

                case .failure(let error):
                    completion(.failure(error))
                }
            }
        )
    }
    
    private func mergePage(
        _ page: [String: Any],
        into accumulated: inout [String: Any],
        keyPath: String
    ) {
        guard
            let embedded = page["_embedded"] as? [String: Any],
            let newItems = embedded[keyPath] as? [Any]
        else { return }

        var baseEmbedded = accumulated["_embedded"] as? [String: Any] ?? [:]
        var currentItems = baseEmbedded[keyPath] as? [Any] ?? []

        currentItems.append(contentsOf: newItems)

        baseEmbedded[keyPath] = currentItems
        accumulated["_embedded"] = baseEmbedded
    }
    
//    func fetchPaginatedData(
//        urlTemplate: String,
//        keyPath: String,
//        responseDict: [String:Any] = [:],
//        pageNumber: Int = 0,
//        completion: @escaping (Result<[String:Any], Errors>) -> Void
//    ) {
//        let urlString = String(format: urlTemplate,pageNumber)
//        
//        let headers: [String: String] = [
//            "Content-Type": "application/hal+json",
//            "Authorization": "Bearer \(KeychainHelper.retrieveTokenFromKeyChain()!)",
//            "x-swa-user-department": "IF",
//            "Postman-Token": "d6c9db45-8ea6-4dd9-9b7e-f77f2baa8b8b"
//        ]
//        
//        APIService.shared.fetch(
//            urlString: urlString,
//            method: .GET,
//            headers: headers,
//            parse: {data in
//                try JSONSerialization.jsonObject(with: data)
//            },
//            completion: {result in
//                switch result{
//                case .success(let parsed):
//                            guard let resultDict = parsed as? [String: Any] else {
//                                completion(.failure(Errors.other("Invalid JSON" as! Error)))
//                                return
//                            }
//
//                            var accumulated = responseDict
//                            if pageNumber == 0 {
//                                accumulated = resultDict
//                            }else{
//                                
//                                if
//                                    let embedded = resultDict["_embedded"] as? [String: Any],
//                                    let newItems = embedded[keyPath] as? [Any]
//                                {
//                                    var embeddedResponse = accumulated["_embedded"] as? [String: Any] ?? [:]
//                                    var currentItems = embeddedResponse[keyPath] as? [Any] ?? []
//                                    
//                                    currentItems.append(contentsOf: newItems)
//                                    
//                                    embeddedResponse[keyPath] = currentItems
//                                    accumulated["_embedded"] = embeddedResponse
//                                }
//                            }
//                            let hasNext = self.hasNextPage(resultDict)
//
//                            if hasNext {
//                                self.fetchPaginatedData(
//                                    urlTemplate: urlTemplate,
//                                    keyPath: keyPath,
//                                    responseDict: accumulated,
//                                    pageNumber: pageNumber + 1,
//                                    completion: completion
//                                )
//                            } else {
//                                completion(.success(accumulated))
//                            }
//                case .failure(let error):
//                    completion(.failure(error))
//                }
//            })
//    }
    
    
    func error(byChangingStatusCode originalError: NSError, newStatusCode: Int) -> NSError {
        var userInfo = originalError.userInfo
        userInfo[NSUnderlyingErrorKey] = originalError
        userInfo["statusCode"] = newStatusCode
        
        let newError = NSError(
            domain: originalError.domain,
            code: newStatusCode,
            userInfo: userInfo
        )
        return newError
    }
    
    
    //MARK: Bid Submission
    
    func submitBid(params:[String:Any], completion: @escaping (Result<[String:Any],Error>) -> Void){
        
        let urlTemplate = "\(self.kCBSwaServiceURL())/if-line-base-auction/bid-round/\(self.packetID)/bids"
        
        let headers: [String: String] = [
            "Content-Type": "application/hal+json",
            "Authorization": "Bearer \(KeychainHelper.retrieveTokenFromKeyChain()!)",
            "x-swa-user-department": "IF",
            "Postman-Token": "d6c9db45-8ea6-4dd9-9b7e-f77f2baa8b8b"
        ]
        
        guard let bodyData = try? JSONSerialization.data(withJSONObject: params, options: []) else {
            completion(.failure(Errors.other("Invalid JSON" as! Error)))
            return
        }
        
        
        APIService.shared.fetch(
            urlString: urlTemplate,
            method: .POST,
            body: bodyData,
            headers: headers,
            parse: {data in
                if data.isEmpty {
                    return [:]
                }
                return try JSONSerialization.jsonObject(with: data) as! [String : Any]
            },
            completion: { result in
                switch result{
                case .success(let response):
                    guard let result = response as? [String:Any] else {
                        completion(.failure(Errors.other("Invalid JSON" as! Error)))
                        return }
                    completion(.success(result))
                case .failure(let error):
                    completion(.failure(error))
                }
            })
    }
}
