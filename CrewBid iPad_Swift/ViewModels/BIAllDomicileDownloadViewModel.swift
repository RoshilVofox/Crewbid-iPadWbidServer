//
//  BIAllDomicileDownloadViewModel.swift
//  CrewBid iPad_Swift
//
//  Created by Rishad on 23/09/25.
//

import Foundation

class BIAllDomicileDownloadViewModel {
    
    let loginViewModel = CBLoginViewModel()
    let bidDownloadViewModel = BIBidFileDownloadViewModel()
    var dataSource = GlobalBidInfo.shared
    
    var dictionary = GlobalBidInfo.shared.allDomicileDownloadDictionary
    let isBothSelected: Bool? = (GlobalBidInfo.shared.allDomicileDownloadDictionary["both"] as? Bool)
    
    func downladAllDomicileBid(bases: [String], tableViewData: [String]) {
        NotificationCenter.default.post(name: Notification.Name("CloseCredentilaPage"), object: nil)
        var bases = bases
        var tableViewData = tableViewData
        if bases.count > 0 {
            tableViewData.append("preparing to download \(bases[0]) bid for........")
        }
        var activityStatus = ""
        let lastIndex = tableViewData.indices.last
        let position = dictionary["position"] as! BICrewPositionType
        dataSource.month = (dictionary["month"] as? Int)!
        dataSource.position = position
        dataSource.round = (dictionary["round"] as? Int)!
        dataSource.year = (dictionary["year"] as? Int)!
        let isBothSelected: Bool = (GlobalBidInfo.shared.allDomicileDownloadDictionary["both"] as? Bool)!
        if isBothSelected == true {
            let counter = (GlobalBidInfo.shared.allDomicileDownloadDictionary["bases"] as? [String])?.count
            if ((counter! / 2) > bases.count) {
                dataSource.position = BICrewPositionType.Captain
            }
            else {
                dataSource.position = BICrewPositionType.FirstOfficer
            }
        }
        if bases.count > 0 {
            dataSource.base = bases[0]
            
            loginViewModel.checkLogin(userID: GlobalBidInfo.shared.allDomicileDownloadDictionary["userName"] as! String, password: GlobalBidInfo.shared.allDomicileDownloadDictionary["password"] as! String)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.loginViewModel.onLoginSuccess = { sessionKey in
                    print("Session Key: \(sessionKey)")
                    activityStatus = "NetworkAvailable"
                    NotificationCenter.default.post(name: Notification.Name("AllDomicileTableDataUpdate"), object: nil, userInfo: ["status": tableViewData, "activityStatus": activityStatus])
                    //            NotificationCenter.default.post(name: Notification.Name("ShowProgressView"), object: nil)
                    let bidFileName = BIBidInfo.shared.bidDataFilename()
                    let linesTextFileName = BIBidInfo.shared.linesTextFilename()
                    print("Filename: \(bidFileName)")
                    
                    print("Bid: New bid")
                    self.bidDownloadViewModel.fetchNewBidData(sessionKey: sessionKey, fileName: bidFileName){result in
                        switch result{
                        case .success(let fileURL):
                            print("File unzipped at: \(fileURL)")
                            DispatchQueue.main.async {
                                activityStatus = "Bid Unzipping..."
                                NotificationCenter.default.post(name: Notification.Name("AllDomicileTableDataUpdate"), object: nil, userInfo: ["status": tableViewData, "activityStatus": activityStatus])
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                print("File unzipped at: \(fileURL)")
                                BIBidInfoReader.shared.checkForSeniorityVacationAndReadBidInfo { success in
                                    if success {
                                        print("success")
                                        tableViewData[lastIndex!] = "✅ downloaded \(bases[0]) \(self.dataSource.position.shortName) successfully"
                                        NotificationCenter.default.post(name: Notification.Name("AllDomicileTableDataUpdate"), object: nil, userInfo: ["status": tableViewData, "activityStatus": activityStatus])
                                        bases.remove(at: 0)
                                        self.downladAllDomicileBid(bases: bases, tableViewData: tableViewData)
                                        activityStatus = "Bid Parsing..."
                                        NotificationCenter.default.post(name: Notification.Name("AllDomicileTableDataUpdate"), object: nil, userInfo: ["status": tableViewData, "activityStatus": activityStatus])
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            activityStatus = ""
                                            NotificationCenter.default.post(name: Notification.Name("AllDomicileTableDataUpdate"), object: nil, userInfo: ["status": tableViewData, "activityStatus": activityStatus])
                                        }
                                    }
                                }
                            }
                            //                        }
                        case .failure(let error):
                            print("Error downloading new bid: \(error.localizedDescription)")
                            tableViewData[lastIndex!] = "❌ Failed to download \(bases[0]) \(position.shortName)"
                            NotificationCenter.default.post(name: Notification.Name("AllDomicileTableDataUpdate"), object: nil, userInfo: ["status": tableViewData, "activityStatus": activityStatus])
                            bases.remove(at: 0)
                            self.downladAllDomicileBid(bases: bases, tableViewData: tableViewData)
                            //                    NotificationCenter.default.post(name: Notification.Name("CloseProgressView"), object: nil)
                        }
                    }
                }
            }
        }
        else {
            NotificationCenter.default.post(name: NSNotification.Name("ReloadCollectionView"), object: nil)
            NotificationCenter.default.post(name: NSNotification.Name("FinishedDownloadingAllDomicileBids"), object: nil)
            return
        }
    }
    
    private func handleNewBidDownloadSuccess(fileURL: URL) -> Bool {
        print("File unzipped at: \(fileURL)")
        var result = false
        BIBidInfoReader.shared.checkForSeniorityVacationAndReadBidInfo { success in
            if success {
                result = true
                DispatchQueue.main.async {
                    self.nullfunc()
                }
            } else {
                NotificationCenter.default.post(name: Notification.Name("CloseProgressView"), object: nil)
            }
        }
        return result
    }
    
    func nullfunc() {
        
    }
}
