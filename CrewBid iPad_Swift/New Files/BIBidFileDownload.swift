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
class BIBidFileDownloadDataSource: BIBidInfoDataSource {
    var userid = String()
    var password = String()
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
    var urlData = Data()
    var urlRequest:URLRequest?
    var downloadType:BIBidFileDownloadType = .biBidDataDownloadType
    weak var delegate:BIBidFileDownloadDelegate!
    var dataSource:BIBidFileDownloadDataSource = BIBidFileDownloadDataSource()
    var finishedBlock: BIFinishedBlock?
    var progressHandler: BIProgressBlock?
    var errorHandler: BIErrorBlock?
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
    
    
    func downloadBidDataFiles(){
        var dict:[String:Any] = [:]
        dict["domicile"] = self.dataSource.base
        dict["EmpNum"] = self.dataSource.employeeNumber
        dict["Round"] = self.dataSource.round
        switch self.dataSource.position{
        case .Captain: dict["Position"] = "CP"
            break
        case .FirstOfficer: dict["Position"] = "FO"
            break
        case .FlightAttendant: dict["Position"] = "FA"
            break
        }
        dict["Year"] = self.dataSource.year
        dict["Month"] = self.dataSource.month
        dict["secretEmpNum"] = self.dataSource.employeeNumber
    
    }
    
    func retrievePreLogonKey(completionHandler: ((String?) -> Void)?){
        var thirdPartyURL = "https://www27.swalife.com/webbid3pty/ThirdParty"
        if UserDefaults.standard.string(forKey: "IsQATest") == "YES" {
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
//MARK: ============ delegate method
    func checkCrewBidLogin() {
        self.urlRequest = URLRequest(url: self.thirdPartyURL()!,cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: kURLConnectionTimeout)
        print("URL RQ: \(String(describing: self.urlRequest))")
        retrievePrelogonCredential()
    }
    
    func retrievePrelogonCredential(){
        self.prelogonConnection = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        let dataTask = self.prelogonConnection.dataTask(with: self.urlRequest!)
        dataTask.resume()
    }
    func retrieveSessionCredential(){
//        self.sessionConnectionProcess()
        self.prelogonCredential = nil
        
    }
    func sessionConnectionProcess(){
        let userID = self.dataSource.userid
        let password = self.dataSource.password
        let escapedPwd = self.stringByAddingPercentEscapes(to: password)!
        let postString = String(format: "CREDENTIALS=%@&REQUEST=LOGON&UID=%@&PWD=%@",self.prelogonCredential!, userID, escapedPwd)
        print("PostString: \(postString)")
        let postData = postString.data(using: .utf8, allowLossyConversion: true)!
        let postLength = String(postData.count)
        self.urlRequest?.httpMethod = "POST"
        self.urlRequest?.setValue(postLength, forHTTPHeaderField: "Content-Length")
        self.urlRequest?.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        self.urlRequest?.httpBody = postData
        
        self.sessionConnection = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        let dataTask = self.sessionConnection.dataTask(with: self.urlRequest!)
        dataTask.resume()
    }
    
    func urlSession(_ session: URLSession,dataTask: URLSessionDataTask,didReceive data: Data) {
        self.urlData.append(data)
        if self.prelogonConnection == session {
            
        }else if self.sessionConnection == session {
            
        }
    }
    func urlSession(_ session: URLSession,dataTask: URLSessionDataTask,willCacheResponse proposedResponse: CachedURLResponse,completionHandler: @escaping (CachedURLResponse?) -> Void) {
        if self.prelogonConnection == session {
            let dataString = String(data: self.urlData, encoding: .utf8)
            self.prelogonCredential = self.stringByAddingPercentEscapes(to: dataString!)!
            print("PrelogonKey: \(dataString ?? "default")")
            self.retrieveSessionCredential()
        }else if self.sessionConnection == session {
            let dataString = String(data: self.urlData, encoding: .utf8)
            self.sessionCredential = self.stringByAddingPercentEscapes(to: dataString!)!
            print("SessionKey: \(dataString ?? "default")")
        }
    }
//====================
    func retrieveSessionKey(username: String, password: String, preloginKey: String, completionHandler:((String?) -> Void)?){
        let jsonString = "CREDENTIALS="+preloginKey+"&REQUEST=LOGON&UID="+username+"&PWD="+escapedString(password) as String
        print("Session Key Request: \(jsonString)")
        var thirdPartyURL = "https://www27.swalife.com/webbid3pty/ThirdParty"
        if UserDefaults.standard.string(forKey: "IsQATest") == "YES" {
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
