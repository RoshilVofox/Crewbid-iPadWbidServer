//
//  BIBidFileDownload.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 11/05/25.
//

import Foundation

let kURLConnectionTimeout = 90.0
protocol BIBidFileDownloadDelegate {
    func bidFileDownload(_ bidFileDownload: BIBidFileDownload, didUpdateProgress progress: Float)
    func bidFileDownloadDidFinish(_ bidFileDownload: BIBidFileDownload)
    func bidFileDownload(_ bidFileDownload: BIBidFileDownload, didFailWithError error: Error)
}



class BIBidFileDownload: NSObject, URLSessionDataDelegate{
    
    var bidInfo = BIBidInfo()
    var prelogonConnection:URLSession!
    var sessionConnection:URLSession!
    var prelogonCredential:String?
    var sessionCredential: String?
    var downloadeedText:String?
    var connectionLog:NSString?
    var filesCount:Float?
    var filesToDownloadEnumerator: IndexingIterator<[String]>?
    var preLogonData = Data()
    var sessionData = Data()
    var urlRequest:URLRequest?
    var downloadType:BIBidFileDownloadType = .BIBidDataDownloadType
    var finishedBlock: BIFinishedBlock!
    var progressHandler: BIProgressBlock!
    var errorHandler: BIErrorBlock!
    var dataSource : GlobalBidInfo?
    var deleagte : BIBidFileDownloadDelegate?
    static let kVendor = "CrewBidPad"

    
    
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
    
//MARK: ============ delegate method
    func checkCrewBidLogin(dataSource:GlobalBidInfo,delegate:BIBidFileDownloadDelegate?,finishedHandler: @escaping () -> Void,progressHandler: @escaping (Float) -> Void,errorHandler: @escaping (Error) -> Void) {
        self.downloadType = .BILoginChecking
        self.urlRequest = URLRequest(url: self.thirdPartyURL()!,cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: kURLConnectionTimeout)
        retrievePrelogonCredential()
        finishedHandler()
    }
    
    func retrievePrelogonCredential(){
        self.prelogonConnection = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        let dataTask = self.prelogonConnection.dataTask(with: self.urlRequest!)
        dataTask.resume()
    }
    
    func retrieveSessionCredential(){
        self.sessionConnectionProcess()
        self.prelogonCredential = nil
    }
    
    func sessionConnectionProcess(){
        let dataSource = GlobalBidInfo.shared
        let userID = dataSource.userid
        let password = dataSource.password
        let escapedPwd = self.stringByAddingPercentEscapes(to: password)!
        let postString = String(format: "CREDENTIALS=%@&REQUEST=LOGON&UID=%@&PWD=%@",self.prelogonCredential!, userID,escapedPwd)
        print("POSTSTR:\(userID),\(password)")
        let postData = postString.data(using: .utf8, allowLossyConversion: true)!
        let postLength = String(postData.count)
        self.urlRequest!.httpMethod = "POST"
        self.urlRequest!.setValue(postLength, forHTTPHeaderField: "Content-Length")
        self.urlRequest!.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        self.urlRequest!.httpBody = postData
        self.sessionConnection = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        let dataTask = self.sessionConnection.dataTask(with: self.urlRequest!)
        dataTask.resume()
        
    }
    
    func urlSession(_ session: URLSession,dataTask: URLSessionDataTask,didReceive data: Data) {
        if self.prelogonConnection == session {
            self.preLogonData.append(data)
        }else if self.sessionConnection == session {
            self.sessionData.append(data)
        }
        //needs code
    }
    func urlSession(_ session: URLSession,dataTask: URLSessionDataTask,willCacheResponse proposedResponse: CachedURLResponse,completionHandler: @escaping (CachedURLResponse?) -> Void) {
        if self.prelogonConnection == session {
            let dataString = String(data: self.preLogonData, encoding: .utf8)
            self.prelogonCredential = stringByAddingPercentEscapes(to: dataString!)
            print("PrelogonKey: \(dataString ?? "default")")
            self.retrieveSessionCredential()
        }else if self.sessionConnection == session {
            let dataString = String(data: self.sessionData, encoding: .utf8)
            self.sessionCredential = dataString!
            print("SessionKey: \(dataString ?? "default")")
        }

    }
//====================
    
    func downloadBidDataFiles(finishedHandler: @escaping () -> Void,progressHandler: @escaping (Float) -> Void,errorHandler: @escaping (Error) -> Void) {
        self.finishedBlock = finishedHandler
        self.progressHandler = progressHandler
        self.errorHandler = errorHandler
        self.checkFlightData()
        
        
    }
    
    func checkFlightData(){
        DispatchQueue.main.async {
            CBUtils.downloadFlightData{ _ in}
        }
    }
    
    func stringFormatter(_ string: String) -> String {
        var encodedString = string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        encodedString = encodedString.replacingOccurrences(of: "+", with: "%2B")
        return encodedString
    }
    
    func escapedString(_ stringValue: String) -> String {
        return stringValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? stringValue
    }
    
    
    func bidDataFiles() -> [String] {
        var bidDataFiles:[String] = []
        let app = UIApplication.shared.delegate as! AppDelegate
        if app.isMockData || app.isHistoricBid{
            bidDataFiles.append(self.textDataFilename())
        }else{
            bidDataFiles.append(self.bidDataFilename())
            bidDataFiles.append(self.textDataFilename())
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
             let destinationURL = bidInfo.downloadDirectory().appendingPathComponent(fileName)
             try urlData.write(to: destinationURL)
             print("Saved MockData TripText in Document Directory: \(destinationURL)")
         } catch {
             print("Saving MockData TripText failed: \(error.localizedDescription)")
         }
    }
    
    //MARK: Filenames
    
    func bidDataFilename() -> String {
        // Filename base with 737 extension.
        let bidDataFilename = "\(bidInfo.dataFilenameBase()).737"
        return bidDataFilename
    }
    func textDataFilename() -> String {
        let textDataFileName = ".ZIP"
        return textDataFileName
    }
    func seniorityListFilename() -> String {
        let seniorityFileName = ".TXT"
        return seniorityFileName
    }
    func bidAwardTextFilename() -> String {
        let bidAwardDataFileName = ".TXT"
        return bidAwardDataFileName
    }
    func linesTextFilename() -> String {
        let linesTextFilename = ".TXT"
        return linesTextFilename
    }
    func mockDataTripFileName() -> String {
        let tripsTextFilename = ".TXT"
        return tripsTextFilename
    }
    
    //MARK: URL Request HTTP Body
    func fileHTTPBody(for filename: String) -> Data? {
        // Bid awards should be downloaded as TXTPACKET, and all others should be downloaded as ZIPPACKET
        let packetType = downloadType == .BIBidAwardsDownloadType ? "TXTPACKET" : "ZIPPACKET"
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
        let packetID = ""
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
