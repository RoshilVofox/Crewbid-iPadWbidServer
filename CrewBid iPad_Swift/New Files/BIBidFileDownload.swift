//
//  BIBidFileDownload.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 11/05/25.
//

import Foundation

let kURLConnectionTimeout = 90.0
protocol BIBidFileDownloadDelegate: AnyObject {
    func bidFileDownload(_ bidFileDownload: BIBidFileDownload, didUpdateProgress progress: Float)
    func bidFileDownloadDidFinish(_ bidFileDownload: BIBidFileDownload)
    func bidFileDownload(_ bidFileDownload: BIBidFileDownload, didFailWithError error: Error)
}
protocol BIBidFileDownloadDataSource: BIBidInfoDataSource {
    func userid() -> String
    func password() -> String
}



class BIBidFileDownload: BIBidInfo{
    
    var sessionCredential: String?
    var downloadeedText:String?
    var connectionLog:NSString?
    var filesCount:Float?
    var filesToDownloadEnumerator: IndexingIterator<[String]>?
    var urlData:Data?
    var urlRequest:URLRequest?
    var downloadType:BIBidFileDownloadType = .biBidDataDownloadType
    weak var delegate:BIBidFileDownloadDelegate!

    static let kVendor = "CrewBidPad"
    
    init?(dataSource: BIBidFileDownloadDataSource, delegate: BIBidFileDownloadDelegate) {
        super.init()
        self.dataSource = dataSource
        self.delegate = delegate
        
        // Check that data source can provide valid info.
        if dataSource.month() == nil ||
           dataSource.base() == nil ||
           dataSource.position() == nil ||
           dataSource.round() == nil {
            print("Data source missing a property")
            return nil
        }
        
        connectionLog = NSMutableString(capacity: 2048)
  
    }
    
    
    //MARK: File Download
    func downloadBidDataFilesWithFinishedHandler(_ finishedHandler: @escaping () -> Void, _ progressHandler: @escaping (Float) -> Void, _ errorHandler: @escaping (Error) -> Void){
        // needs code
    }
    
    
    func getPosition(from type: Int) -> String {
        switch type {
        case 0:
            return "CP"
        case 1:
            return "FO"
        default:
            return "FA"
        }
    }
    
    
    func downloadBidDataFiles(){
        let app = UIApplication.shared.delegate as! AppDelegate
        switch app.objNetworkType {
        case .free:
            let alert = AlertService.showAlert(title: "Sorry", message: "You cannot get needed access via SouthwestWifi or 2Wire. Try again later when you are safely on the ground and have another internet access.", actions: nil)
            let topVC = self.getTopViewController()
            topVC?.present(alert, animated: true)
            break
        default:break
        }
        self.downloadType = .biBidDataDownloadType
        let fileManager = FileManager.default
        let downloadURL = downloadDirectory()

        do {
            try fileManager.createDirectory(at: downloadURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            var bidInfoError: NSError?
            BIBidInfoError.setError(&bidInfoError, for: .downloadDirectoryCreation, underlyingError: error as NSError)
            self.notifyDelegateError(bidInfoError!)
            return
        }
        let filesToDownload = self.bidDataFiles()
        self.filesCount = Float(filesToDownload.count)
        self.filesToDownloadEnumerator = filesToDownload.makeIterator()
        if app.isMockData{
            self.downloadMockDataTripText()
            print("Beginning download")
                let fileName = bidDataFilename()
                guard let url = URL(string: "http://www.wbidmax.com/downloads/MockData/\(fileName)") else {
                    print("Invalid URL")
                    return
                }
                do{
                    let urlData = try Data(contentsOf: url)
                    print("Got the data!")
                    let destinationURL = downloadDirectory().appendingPathComponent(fileName)
                    print("Saving to \(destinationURL)")
                    try urlData.write(to: destinationURL)
                    print("Saved bid data file to: \(destinationURL)")
                    // Initialize URLRequest to third-party URL
                    if let thirdPartyURL = thirdPartyURL() {
                        urlRequest = URLRequest(url: thirdPartyURL,cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: kURLConnectionTimeout)
                    }
                }catch{
                    print("Failed to download or save bid data: \(error.localizedDescription)")
                }
        }else if app.isHistoricBid{
            if self.isSecondRoundBid() && !self.isFlightAttendantBid() {
                var dictHistoricText: [String: Any] = [:]
                dictHistoricText["Year"]     = app.mockDataYear
                dictHistoricText["Month"]    = app.mockDataMonth
                dictHistoricText["Round"]    = dataSource.round()
                dictHistoricText["Domicile"] = dataSource.base()
                dictHistoricText["Position"] = dataSource.position()?.shortName
                dictHistoricText["FileName"] = linesTextFilename()
                let jsonData = try? JSONSerialization.data(withJSONObject: dictHistoricText, options: [])
                let jsonString = jsonData.flatMap { String(data: $0, encoding: .utf8) }!
                let serviceURL = "\(String(describing: app.Domain))DownloadHistoricalBidLineAll"
                let returnData = self.getHistoricalData(postString: jsonString, urlString: serviceURL)
                //-----------needs code----------
            }
        }else{
            if let thirdPartyURL = thirdPartyURL() {
                self.urlRequest = URLRequest(url: thirdPartyURL,cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: kURLConnectionTimeout)
            }
        }
        self.retrievePrelogonCredential()
    }
    
    func retrievePrelogonCredential(){
        
    }
    func retrieveSessionCredential(){
        
    }
    
    
    func getHistoricalData(postString: String, urlString: String) -> Data?{
        // Initialize the response data object
        
//            var error1: NSError?
       
            // Build the Request
            guard let url = URL(string: urlString) else {
                print("Invalid URL")
                return nil
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("\(postString.count)", forHTTPHeaderField: "Content-Length")
            request.httpBody = postString.data(using: .utf8)
//            let returnData = self.sendSynchronousRequest(request, returningResponse: nil, error: error1)!
        var returnData:Data?
        return returnData
    }
    
    
    func sendSynchronousRequest(_ request: URLRequest,
                                returningResponse responsePtr: inout URLResponse?,
                                error errorPtr: inout NSError?) -> Data? {
        //---needs code--------
        var result:Data?
//        let session = URLSession(configuration: .default)
//        session.dataTask(with: request) { (data, response, error) in
//            if errorPtr != nil {
//                errorPtr = error as NSError?
//            }
//            if responsePtr != nil {
//                responsePtr = error as? URLResponse
//            }
//            if error == nil {
//                result = data
//            }
//            //---needs code--------
//        }
        return result
    }
    
    
    func bidDataFiles() -> [String] {
        var bidDataFiles = [String]()
        
        // Always download bid data and text data files.
        let app = UIApplication.shared.delegate as! AppDelegate
        
        if app.isMockData || app.isHistoricBid {
            bidDataFiles.append(textDataFilename())
        } else {
            bidDataFiles.append(bidDataFilename())
            bidDataFiles.append(textDataFilename())
        }
        
        // If second round bid pilot, also download first round text data file
        // for parsing leg pay. The first round text data file is not needed for
        // flight attendant bids, since a trip text file is included in the second
        // round text data.
        if isSecondRoundBid() && !isFlightAttendantBid() {
            // First round text data filename is the same as second round text data
            // filename except replace 'B' at index 5 with 'A'.
            
            // Updated by Raja on 19 Dec 2024 - not to download this file for the QA bid data.
            let isQATest = UserDefaults.standard.string(forKey: "isQATest")
            if isQATest == "NO" {
                var firstRoundTextDataFilename = textDataFilename()
                firstRoundTextDataFilename.replaceSubrange(firstRoundTextDataFilename.index(firstRoundTextDataFilename.startIndex, offsetBy: 5)..<firstRoundTextDataFilename.index(firstRoundTextDataFilename.startIndex, offsetBy: 6), with: "A")
                bidDataFiles.append(firstRoundTextDataFilename)
            }
        }
        
        return bidDataFiles
    }
    func downloadMockDataTripText(){
        print("Beginning download")
         let fileName = mockDataTripFileName()
        guard let url = URL(string: "http://www.wbidmax.com/downloads/MockData/\(fileName)") else {
            print("Invalid URL")
            return
        }
         do {
             let urlData = try Data(contentsOf: url)
             let destinationURL = downloadDirectory().appendingPathComponent(fileName)
             try urlData.write(to: destinationURL)
             print("Saved MockData TripText in Document Directory: \(destinationURL)")
         } catch {
             print("Saving MockData TripText failed: \(error.localizedDescription)")
         }
    }
    
    //MARK: Filenames
    
    func bidDataFilename() -> String {
        // Filename base with 737 extension.
        let bidDataFilename = "\(dataFilenameBase()).737"
        return bidDataFilename
    }
    func textDataFilename() -> String {
        // 'A' for first round, 'B' for second round
        let bidRoundChar: Character = isFirstRoundBid() ? "A" : "B"
        
        let textDataFileName = "\(textFilenameBase())\(bidRoundChar).ZIP"
        
        return textDataFileName
    }
    func seniorityListFilename() -> String {
        // 'S' for first round, 'R' for pilot second round, 'SR' for flight attendant second round
        var bidRoundString = "S"
        
        if isSecondRoundBid() {
            if isFlightAttendantBid() {
                bidRoundString = "SR"
            } else {
                bidRoundString = "R"
            }
        }
        let seniorityFileName = "\(textFilenameBase())\(bidRoundString).TXT"
        return seniorityFileName
    }
    func bidAwardTextFilename() -> String {
        // 'M' for first round, 'W' for second round
        let bidRoundChar: Character = isFirstRoundBid() ? "M" : "W"
        
        let bidAwardDataFileName = "\(textFilenameBase())\(bidRoundChar).TXT"
        
        return bidAwardDataFileName
    }
    func linesTextFilename() -> String {
        // 'L' for first round, 'N' for second round
        let bidRoundChar: Character = isSecondRoundBid() ? "N" : "L"
        
        let linesTextFilename = "\(textFilenameBase())\(bidRoundChar).TXT"
        
        return linesTextFilename
    }
    func mockDataTripFileName() -> String {
        // The trip text character is 'P' except for flight attendant second round bids, in which case it's 'T'.
        // There's no trips text file for pilot second round.
        var tripTextChar: Character = "P"
        
        if isSecondRoundBid() && isFlightAttendantBid() {
            tripTextChar = "T"
        }
        
        let tripsTextFilename = "\(textFilenameBase())\(tripTextChar).TXT"
        
        return tripsTextFilename
    }
    
    //MARK: URL Request HTTP Body
    func fileHTTPBody(for filename: String) -> Data? {
        // Bid awards should be downloaded as TXTPACKET, and all others should be downloaded as ZIPPACKET
        let packetType = downloadType == .biBidAwardsDownloadType ? "TXTPACKET" : "ZIPPACKET"
        
        let fileHTTPBodyString = "REQUEST=\(packetType)&CREDENTIALS=\(sessionCredential!)&NAME=\(filename)"
        
        let fileHTTPBody = fileHTTPBodyString.data(using: .utf8)
        
        return fileHTTPBody
    }
    func thirdPartyURL() -> URL? {
        // Get the URL for the ThirdPartyURL.plist
        guard let plistURL = Bundle.main.url(forResource: "ThirdPartyURL", withExtension: "plist"),
              let plistDictionary = NSDictionary(contentsOf: plistURL) as? [String: Any],
              var urlString = plistDictionary["URL"] as? String else {
            return nil
        }
        // Check if it's a QA test
        let isQATest = UserDefaults.standard.string(forKey: "isQATest")
        if isQATest == "YES", let qaTestURL = plistDictionary["QATestURL"] as? String {
            urlString = qaTestURL
        }
        return URL(string: urlString)
    }
    
    func mockDataURL() -> URL? {
        // Construct the URL string
        let urlString = "http://www.wbidMax.com/MockDataCrewbid/\(bidDataFilename())"
        
        // Create and return the URL
        return URL(string: urlString)
    }
    
    func packetID() -> String {
        let round = dataSource.round()!.intValue
        var packetIDRound = 0
        
        // Flight attendant bid
        if isFlightAttendantBid() {
            // 1 for flight attendant first round bid, 2 for second round
            packetIDRound = round == 1 ? 1 : 2
        }
        // Pilot bid
        else {
            // 4 for pilot first round bid, 5 for second round
            packetIDRound = round == 1 ? 4 : 5
        }
        
        // Four-digit year, two-digit month
        let packetID = String(format: "%@%04ld%02ld%d",dataSource.base()!,dataSource.year().intValue ,dataSource.month()!.intValue,packetIDRound)
        
        return packetID
    }
    
    func stringByAddingPercentEscapes(to unescapedString: String) -> String? {
        let allowedCharacterSet = CharacterSet(charactersIn: ";/:@&=+$,")
        let escapedString = unescapedString.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)
        
        return escapedString
    }
    
    
    
    
    
    func notifyDelegateError(_ error: Error) {
    
    }
 
    func getTopViewController() -> UIViewController? {
        guard let rootVC = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        var topVC = rootVC
        while let presentedVC = topVC.presentedViewController {
            topVC = presentedVC
        }
        return topVC
    }
}
