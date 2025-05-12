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



class BIBidFileDownload: NSObject{

    var bidInfo = BIBidInfo()
    var prelogonConnection:URLSession!
    var prelogonCredential:String?
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
    
//    init?(dataSource: BIBidFileDownloadDataSource, delegate: BIBidFileDownloadDelegate) {
//        super.init()
//        bidInfo.dataSource = dataSource
//        self.delegate = delegate
//        
//        // Check that data source can provide valid info.
//        if dataSource.month() == nil ||
//           dataSource.base() == nil ||
//           dataSource.position() == nil ||
//           dataSource.round() == nil {
//            print("Data source missing a property")
//            return nil
//        }
//        
//        connectionLog = NSMutableString(capacity: 2048)
//  
//    }
    
    
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
        let downloadURL = bidInfo.downloadDirectory()

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
                    let destinationURL = bidInfo.downloadDirectory().appendingPathComponent(fileName)
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
                //-----------needs code----------
        }else{
            if let thirdPartyURL = thirdPartyURL() {
                self.urlRequest = URLRequest(url: thirdPartyURL,cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: kURLConnectionTimeout)
            }
        }
 
//        self.getPreLogonKey()
    }
    
    func retrievePreLogonKey(completionHandler: ((String?) -> Void)?){
        var thirdPartyURL = "https://www27.swalife.com/webbid3pty/ThirdParty"
        if UserDefaults.standard.bool(forKey: "IsQAEnabled") == true {
            thirdPartyURL = "https://www27.swalifeqa.com/webbid3pty/ThirdParty"
        }
        GetPreLogonKey(serviceURL: thirdPartyURL, completionHandler: completionHandler)
    }
    func GetPreLogonKey(serviceURL: String, completionHandler: ((String?) -> Void)?) {
        guard let url = URL(string: serviceURL) else {
            print("Invalid URL: \(serviceURL)")
            completionHandler?(nil)
            return
        }
        print("URL: \(url)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["Content-Type": "application/json"]
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completionHandler?(nil)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                completionHandler?(nil)
                return
            }
            print("HTTP Status Code: \(httpResponse.statusCode)")
            guard httpResponse.statusCode == 200, let data = data,
                  let dataValue = String(data: data, encoding: .utf8) else {
                print("No data or bad status code")
                completionHandler?(nil)
                return
            }
            let stringData = self.escapedString(dataValue)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            print("String Data: \(stringData)")
            completionHandler?(stringData)
        }
        task.resume()
    }
    func retrieveSessionKey(username: String, password: String, preloginKey: String, completionHandler:((String?) -> Void)?){
        let jsonString = "CREDENTIALS="+preloginKey+"&REQUEST=LOGON&UID="+username+"&PWD="+escapedString(password) as String
        print("Session Key Request: \(jsonString)")
        var thirdPartyURL = "https://www27.swalife.com/webbid3pty/ThirdParty"
        if UserDefaults.standard.bool(forKey: "IsQAEnabled") == true {
            thirdPartyURL = "https://www27.swalifeqa.com/webbid3pty/ThirdParty"
        }
        getSessionKey(serviceURL: thirdPartyURL, jsonDataString: jsonString, completionHandler: completionHandler)
    }
    
    func getSessionKey(serviceURL: String, jsonDataString: String, completionHandler: ((String?) ->Void)?){
        guard let url = URL(string: serviceURL) else {
            print("Invalid URL: \(serviceURL)")
            completionHandler?(nil)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["Content-Type": "application/x-www-form-urlencoded"]
        request.httpBody = jsonDataString.data(using: .utf8)
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completionHandler?(nil)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                completionHandler?(nil)
                return
            }
            print("HTTP Status Code: \(httpResponse.statusCode)")
            guard httpResponse.statusCode == 200, let data = data,
                  let dataValue = String(data: data, encoding: .utf8) else {
                print("No data or bad status code")
                completionHandler?(nil)
                return
            }
            print("Session Credentials: \(dataValue)")
            completionHandler?(dataValue)
        }
        task.resume()
    }
    
    
    func escapedString(_ stringValue: String) -> String {
        return stringValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? stringValue
    }
    

    
    


    
    func getHistoricalData(postString: String, urlString: String) -> Data?{
        var returnData:Data?
        return returnData
    }
    
    
    func sendSynchronousRequest(_ request: URLRequest,
                                returningResponse responsePtr: inout URLResponse?,
                                error errorPtr: inout NSError?) -> Data? {
        var result:Data?
        return result
    }
    
    
    func bidDataFiles() -> [String] {
        var bidDataFiles = [String]()
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
