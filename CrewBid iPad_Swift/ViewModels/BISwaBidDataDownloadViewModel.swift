//
//  BISwaBidDataDownloadViewModel.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/08/25.
//

import Foundation
import CoreData

class BISwaBidDataDownloadViewModel{
    var packetID: String = ""
    var bidInfo: String = ""
    var pageSize: String = ""
    let dataSource:BIBidInfoDataSource?
    let swaBidDataDownload = BISwaBidDataDownload()
    var isTotalElemtForPairingAPIadded: Bool = false
    var onDownloadError: ((NSError) -> Void)?


       private var isHistoricBid = false
       private var userId: String?

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
    }

    func startBidInfoDownload(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let token = KeychainHelper.retrieveTokenFromKeyChain(),
                let userDetails = JWTDecoder.decode(jwtToken: token),
                let userId = userDetails["cn"] as? String
        else {
            onDownloadError?(NSError(domain: "BidDownload", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing or invalid token"]))
            return
        }

        self.userId = userId

        // HISTORIC BID → only one API to call
        if AppState.shared.isHistoricBid {
            self.downloadSwaHistoricBid { success, error in
                if success {
                    completion(.success(()))
                } else {
                    completion(.failure(error ?? NSError(
                        domain: "BidDownload",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Unknown historic bid download error"]
                    )))
                }
            }
            return
        }

        // NORMAL BID → run all 5 downloads in parallel
        let downloadGroup = DispatchGroup()
        var capturedError: Error?

        // Helper to wrap each download
        func run(_ work: (@escaping (Bool, Error?) -> Void) -> Void) {
            downloadGroup.enter()
            work { success, error in
                if !success {
                    capturedError = error
                }
                downloadGroup.leave()
            }
        }

        // Start all downloads IN PARALLEL
        run(self.downloadSwaSeniorityData)
        run(self.downloadSwaCoverLetter)
        run(self.downloadSwaLineData)
        run(self.downloadSwaTripsData)
        run(self.downloadSwaBuddyBids)

        // When all downloads finish:
        downloadGroup.notify(queue: .main) {
            
            if let error = capturedError {
                completion(.failure(error))
                return
            }
            // All downloads completed successfully → NOW parse
            self.readSwaBidData { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    
    //MARK: Seniority List
    private func downloadSwaSeniorityData(completion: @escaping (Bool, Error?) -> Void) {

        self.swaBidDataDownload?.getSwaSeniorityList { result in
            switch result {
            case .success:
                self.saveSelectionsToUserDefaults()
                completion(true, nil)     // notify DispatchGroup
            case .failure(let error):
                completion(false, error)  // notify DispatchGroup
            }
        }
    }
    

    
    
    //MARK: Cover Letter
    private func downloadSwaCoverLetter(completion: @escaping (Bool, Error?) -> Void) {

        self.swaBidDataDownload?.getSwaCoverLetter { result in
            switch result {
            case .success:
                completion(true, nil)
            case .failure(let error):
                completion(false, error)
            }
        }
    }

    //MARK: Line data
    private func downloadSwaLineData(completion: @escaping (Bool, Error?) -> Void) {

        self.swaBidDataDownload?.downloadBidData(type: "lines") { result in
            switch result {
            case .success:
                completion(true, nil)
            case .failure(let error):
                completion(false, error)
            }
        }
    }
    
    //MARK: Trip data
    private func downloadSwaTripsData(completion: @escaping (Bool, Error?) -> Void) {

        self.swaBidDataDownload?.downloadBidData(type: "pairings") { result in
            switch result {
            case .success:
                completion(true, nil)
            case .failure(let error):
                completion(false, error)
            }
        }
    }
    
    //MARK: Buddy list
    private func downloadSwaBuddyBids(completion: @escaping (Bool, Error?) -> Void) {

        self.swaBidDataDownload?.getBuddyBids(user_id: self.userId!) { result in
            switch result {
            case .success:
                completion(true, nil)
            case .failure(let error):
                completion(false, error)
            }
        }
    }
    
    //MARK: Historic bid
    private func downloadSwaHistoricBid(completion: @escaping (Bool, Error?) -> Void) {
        
        self.swaBidDataDownload?.downloadHistoricBid(){ result in
            switch result{
            case .success():
                NotificationCenter.default.post(name: Notification.Name("BidDownloaded"), object: nil)
                if CBUtils.isSwaTypeOfFileDownload(){
                    self.readSwaBidData { parseResult in
                        switch parseResult {
                        case .success:
                            completion(true, nil)

                        case .failure(let error):
                            self.onDownloadError?(error as NSError)
                            completion(false, error)
                        }
                    }
                }else{
                    self.startBidInfoReading(){ success in
                        completion(success, nil)
                    }
                }
            case .failure(let error):
                self.onDownloadError?(error as NSError)
                completion(false, error)
            }
        }
    }

    
    private func startBidInfoReading(completion: @escaping (Bool) -> Void){
        BIBidInfoReader.shared.checkForSeniorityVacationAndReadBidInfo { success in
            if success{
                completion(true)
            }else{
                NotificationCenter.default.post(name: Notification.Name("CloseProgressView"), object: nil)
                completion(false)
            }
        }
    }
    
    private func readSwaBidData(completion: @escaping (Result<Void, Error>) -> Void){
        
        if self.isAllDomicileEnabled(){
            //parsing data notification
        }else{
            //update the progress
        }
        
        let documentFileURL = BIBidInfo().bidDocumentFileURL()
        do {
            try Data().write(to: documentFileURL)
        } catch {
            print("Failed to create empty bid file:", error)
            completion(.failure(error))
            return
        }

        guard let parser = BISwaBidDataParsing() else {
            let err = NSError(
                domain: "BISwaBidParsing",
                code: 2000,
                userInfo: [NSLocalizedDescriptionKey: "Failed to initialize parser"]
            )
            completion(.failure(err))
            return
        }
        
        parser.parseAndSaveBidData { result in
            switch result {

            case .success:
                completion(.success(()))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func isAllDomicileEnabled() -> Bool {
        if let secretDownloadAllDomicileEnabled = UserDefaults.standard.string(forKey: "isSecretForAllDomicileDownloadEnabled") {
            return secretDownloadAllDomicileEnabled == "YES"
        }
        return false
    }
    
    
    private func saveSelectionsToUserDefaults(){
        let userDefaults = UserDefaults.standard
        if self.dataSource?.base != nil {
            userDefaults.set(self.dataSource!.base, forKey: kCBCrewBaseDefaultKey)
        }
        if self.dataSource?.position != nil {
            userDefaults.set(self.dataSource!.position.rawValue, forKey: kCBCrewPositionTypeDefaultKey)
        }
        if self.dataSource?.employeeNumber != nil {
            userDefaults.set(self.dataSource!.employeeNumber, forKey: kCBEmployeeNumberDefaultKey)
        }
        if self.dataSource?.round != nil {
            userDefaults.set(self.dataSource!.round, forKey: kCBCrewRoundTypeDefaultKey)
        }
    }



}
