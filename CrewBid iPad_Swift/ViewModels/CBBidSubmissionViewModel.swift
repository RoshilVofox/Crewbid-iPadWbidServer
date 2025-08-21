//
//  CBBidSubmissionViewModel.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/08/25.
//

import Foundation

class CBBidSubmissionViewModel{
    
    var bidPeriod:BIBidPeriod?
    var empNum = ""
    var password = ""
    var defaultEmpNum = ""
    var optionalEmpNumbers = NSArray()
    var bidListNumbers = NSMutableArray()
    var app:AppDelegate!
    var isBiddingIDCertified:Bool = false
    var bidFileDownload:BIBidFileDownload?

    init(bidPeriod: BIBidPeriod, empNum: String,password: String, defaultEmpNum: String, optionalEmpNum: NSArray) {
        self.bidPeriod = bidPeriod
        self.optionalEmpNumbers = optionalEmpNum
        self.defaultEmpNum = defaultEmpNum
        self.empNum = empNum.lowercased()
        self.password = password
    }
    
    func setBidLineNumbers(completion: @escaping (Bool) -> Void){
        let lines = (CBGlobalMethods.shared.selectedBidPeriod!.lines!.allObjects as NSArray).sortedArray(using: [NSSortDescriptor(key: "bidOrder", ascending: true)])
        let results: NSArray = ((lines as NSArray).filtered(using: NSPredicate(format: "bidOrder != 0"))) as NSArray
        if results.count == 0 {
            return
        }
        let bidLineNumbers = NSMutableArray()
        if bidPeriod!.isSecondRoundBid() || !bidPeriod!.isFABid() {
            let aKey = results.value(forKey: "number")
            bidLineNumbers.addObjects(from: aKey as! [Any])
            
        }else{
            for case let line as BILine in results{
                if line.faBidLineReserve != 0 {
                    bidLineNumbers.add("M")
                }else{
                    bidLineNumbers.add("\(line.number!)\(line.faPositionString)")
                }
            }
        }
        if self.bidPeriod!.isFABid(){
            if self.optionalEmpNumbers.count > 0 {
                let bidLineNumberWithoutDPosition = NSMutableArray()
                if let array = bidLineNumbers as? [Int] {
                    bidLineNumbers.removeAllObjects()
                    for item in array{
                        bidLineNumbers.add("\(item)")
                    }
                }
                for num in bidLineNumbers as! [String]{
                    if !num.contains("D"){
                        bidLineNumberWithoutDPosition.add(num)
                    }
                }
                if bidLineNumbers.count > bidLineNumberWithoutDPosition.count{
                    let removedLinesCount = bidLineNumbers.count - bidLineNumberWithoutDPosition.count
                    AlertService.showAlertForTopVC(title: "CrewBid", message: "\(removedLinesCount) lines were removed from the submission because they were D position lines. Buddy Bid Lines must have positions (A, B, etc.) for each bidder. Press or Cancel to return the position choices", actions: [(title: "OK", style: .default, handler: {_ in
                        //Bid line number for FA with buddy and D position lines removed for submission
                        self.bidListNumbers = bidLineNumberWithoutDPosition
                        completion(true)
                    })])
                }
                else{
                    //bid line number for FA with buddy and no D position lines in bidlist
                    self.bidListNumbers = bidLineNumbers
                    completion(true)
                }
            }else{
                //bid lines for FA without any buddy
                self.bidListNumbers = bidLineNumbers
                completion(true)
            }
        }else{
            //bid lines for the Pilot
            self.bidListNumbers = bidLineNumbers
            completion(true)
        }
        
    }
    
    
    func startBidSubmission(sessionKey: String, completion: @escaping (String?) -> Void){
        if bidPeriod!.isFABid(){
            // bid submission for FA
            // new API
        }else{
            // bid submission for Pilot
            //get the httpBody format for bid submission
            let httpBody = self.setupBidSubmissionFormat(sessionKey: sessionKey, bidEmployeeNumber: self.defaultEmpNum, bidLineNumbers: self.bidListNumbers, packetID: self.getPacketID(), avoidanceEmpID: self.optionalEmpNumbers)
            print(httpBody)
            print("")
//            bidFileDownload?.submitBid(httpBody: httpBody) { result in
//                switch result{
//                case.success(let dataString):completion(dataString)
//                case .failure(let error):completion(error.localizedDescription)
//                }
//            }
        }
    }
    
    func getPacketID() -> String {
        let dataSource = GlobalBidInfo.shared
        let round = dataSource.round
        //for pilot bid data
        // 4 for pilot first round bid, 5 for second round.
        let packetIDRound = 1 == round ? 4 : 5
        // Four-digit year, two-digit month.
        let packetID = "\(dataSource.base)\(dataSource.year)\(String(format: "%02d", dataSource.month))\(packetIDRound)"
        return packetID
    }
    
    func setupBidSubmissionFormat(sessionKey: String, bidEmployeeNumber: String, bidLineNumbers: NSArray,packetID: String, avoidanceEmpID: NSArray) -> String{
        let dataSource = GlobalBidInfo.shared
        let kVendor = "CrewBidPad"
        var optionalParameters = ""
        if avoidanceEmpID.count > 0 {
            let optionName = "PILOT"
            for i in 0..<avoidanceEmpID.count {
                let paramName = optionName + "\(i + 1)"
                let paramValue = avoidanceEmpID[i] as! String
                optionalParameters.append(contentsOf: "&\(paramName)=\(paramValue)")
            }
        }
        let key = bidFileDownload?.stringByAddingPercentEscapes(to: sessionKey)

        let httpBody = """
         REQUEST=UPLOAD_BID\
         &CREDENTIALS=\(key)\
         &PACKETID=\(packetID)\
         &BIDDER=\(bidEmployeeNumber)\(optionalParameters)\
         &BASE=\(dataSource.base)\
         &SEAT=\(dataSource.position.shortName)\
         &BIDROUND=Round\(dataSource.round)\
         &VENDOR=\(kVendor)\
         &BID=\(bidLineNumbers.componentsJoined(by: ","))
         """
        return httpBody
    }
}
