//
//  ServiceConnection.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 02/09/25.
//

import Foundation

protocol ServiceConnectionDelegate: AnyObject {
    func responseError(_ errMsg: String)
    func serviceResponse(_ arrResponse: [Any])
    func responseStatus(_ responseStatus: Int)
    func connectionFailed()
    func requestFailed()
    func connectionDataReceived(_ progress: Float)
}
let kURLConnectionTimeout: TimeInterval = 90.0

class ServiceConnection: NSObject, URLSessionDelegate, URLSessionDataDelegate{
    var userName: String?
    var password: String?
    var hostName: String?
    var port: String?
    var ssl: String?
    var webserviceName: String?
    weak var delegate: ServiceConnectionDelegate?
    var serviceURL: String?

    var xmlParser: XMLParser?
    var arrElements: [Any] = []
    var arrTempData: [Any] = []
    var arrElements1: [Any] = []
    var arrData: NSMutableArray?
    var arrData1: [Any] = []
    var successKey: String?
    var splitterTag: String?
    var webData: NSMutableData?
    var domain: String?
    var authenticationFlag: Bool = false

    

    var responseStatus: Int = 0
    var isPost: Bool = false
    var recordResults: Bool = false
    var dicTemp: NSMutableDictionary?
    var errorMessageFlag: Bool = false
    var strElementName: String = ""
    var strElementValue: String = ""
    var isParse: Bool = false
    var getProgress: Bool = false
    var receivedBytes: Int64 = 0
    var totalBytes: Int64 = 0
    var baseData: Data?
    var app: AppDelegate!
    var vacationSession: URLSession?
    
    override init() {
        self.app = UIApplication.shared.delegate as? AppDelegate
    }
    
    func initialize(username: String, password: String, authenticationName serviceName: String) {
        let defaults = UserDefaults.standard

        // Pull from UserDefaults
        self.userName = (defaults.string(forKey: "AuthUsername") ?? "").uppercased()
        self.password = defaults.string(forKey: "AuthPassword")
        print("Authentication---\(self.userName ?? ""), \(self.password ?? "")")

        self.webserviceName = serviceName
    }
    
    func constructUrl(_ serviceName: String) {
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
        
        self.userName = ""
        self.password = ""
        self.webserviceName = ""
        self.hostName = ""
        self.port = ""
        self.ssl = "http"
        
        app.webData = NSMutableData()
        self.ssl = "https"
        
        // Build service URL
        self.serviceURL = baseURL + serviceName
        print("url--- \(self.serviceURL ?? "")")
        
        // Replace spaces with %20
        self.serviceURL = self.serviceURL?.replacingOccurrences(of: " ", with: "%20")
        print("url \(self.serviceURL ?? "")")
    }
    
    
    
    
    func get() {
        baseData = Data()
        isPost = false
        totalBytes = 0
        receivedBytes = 0

        guard let url = URL(string: serviceURL!) else {
            delegate?.connectionFailed()
            return
        }
        
        var request = URLRequest(url: url,
                                 cachePolicy: .reloadIgnoringLocalCacheData,
                                 timeoutInterval: kURLConnectionTimeout)
        request.httpMethod = "GET"

        // Create session with delegate if you want progress callbacks
        let session = URLSession(configuration: .default,
                                 delegate: self,
                                 delegateQueue: OperationQueue.main)
        
//        let task = session.dataTask(with: request) { [weak self] data, response, error in
//            guard let self = self else { return }
//            
//            if let error = error {
//                print("GET failed with error: \(error.localizedDescription)")
//                self.delegate?.connectionFailed()
//                return
//            }
//            
//            if let data = data {
//                self.webData = NSMutableData(data: data)
//                print(self.webData!)
//                self.app.webData = NSMutableData(data: data)
//            }
//        }
        let task = session.dataTask(with: request)
        
        task.resume()
    }
    
    func getJson() {
        baseData = Data()
        isPost = false
        
        guard let url = URL(string: serviceURL!) else {
            delegate?.connectionFailed()
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpMethod = "GET"
        
        totalBytes = 0
        receivedBytes = 0
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        
        let dataTask = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Connection failed: \(error)")
                self.delegate?.connectionFailed()
                return
            }
            
            if let data = data {
                self.webData = data as! NSMutableData
                self.app.webData = data as! NSMutableData
            }
        }
        
        dataTask.resume()
    }
    
    func checkCrewBidServiceAccessibility(completion: @escaping (Bool) -> Void) {
        let title = "Sorry!"
        let networkMsg = "You cannot get needed access via SouthwestWifi or 2Wire. Try again later when you are safely on the ground and have another internet access."
        let serverMsg = "We are not able to connect to the CrewBid/WBidMax server. We need to do so to download important files. Please try again later. If this persists, you can try to change internet connections (like use a hotspot). Finally, if this persists for more than 4 hours, let us know."
        
        guard let app = UIApplication.shared.delegate as? AppDelegate else {
            completion(false)
            return
        }
        
        guard let url = URL(string:EndPoint.shared.VPSPing) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let data = data {
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let status = json["Status"] as? String, status == "Success" {
                    print("Result: \(json)")
                    completion(true)
                } else {
                    if app.objNetworkType == .free {
                        self.showAlertForAccessibilityError(title: title, message: networkMsg, completion: completion)
                    } else {
                        self.showAlertForAccessibilityError(title: title, message: serverMsg, completion: completion)
                    }
                }
            } else {
                if app.objNetworkType == .free {
                    self.showAlertForAccessibilityError(title: title, message: networkMsg, completion: completion)
                } else {
                    self.showAlertForAccessibilityError(title: title, message: serverMsg, completion: completion)
                }
            }
        }
        task.resume()
    }
    
    func currentTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              var topVC = window.rootViewController else {
            return nil
        }
        
        // Walk through presented view controllers
        while let presentedVC = topVC.presentedViewController {
            topVC = presentedVC
        }
        
        return topVC
    }
    
    func showAlertForAccessibilityError(title: String, message: String, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default) { _ in
                completion(false)
            }
            alert.addAction(okAction)
            
            if let topVC = self.currentTopViewController() {
                topVC.present(alert, animated: true, completion: nil)
            } else {
                print("Error: No valid view controller to present alert.")
                completion(false) // still call it
            }
        }
    }
    
    func postData(urlName: String, jsonString: String) {
        guard let serviceURL = serviceURL, let url = URL(string: serviceURL) else {
            delegate?.connectionFailed()
            return
        }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = kURLConnectionTimeout
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonString.data(using: .utf8)
        
        // Reset buffers
        webData = NSMutableData()
        app.webData = NSMutableData()
        isPost = true
        
        // Create a delegate-based session
        let session = URLSession(configuration: .default,
                                 delegate: self,
                                 delegateQueue: OperationQueue.main)
        
        // Create task WITHOUT closure, so delegate methods fire
        let task = session.dataTask(with: request)
        task.resume()
    }
    
    func postDataForUpdateInApp(urlName: String, jsonString: String) {
        isPost = true
        
        guard let url = URL(string: serviceURL!) else {
            delegate?.connectionFailed()
            return
        }
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: kURLConnectionTimeout)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonString.data(using: .utf8)
        
        let app = UIApplication.shared.delegate as! AppDelegate
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        
        let dataTask = session.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                self.delegate?.connectionFailed()
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let status = json["Status"] as? Bool {
                    
                    let fileManager = FileManager.default
                    if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let path = documentsDirectory.appendingPathComponent("OfflineData.plist")
                        let path1 = documentsDirectory.appendingPathComponent("OfflinePayment.plist")
                        
                        try? fileManager.removeItem(at: path)
                        try? fileManager.removeItem(at: path1)
                    }
                    
                    NotificationCenter.default.post(name: Notification.Name("InAppPurchaseUpdated"), object: self)
                    
                } else {
                    NotificationCenter.default.post(name: Notification.Name("InAppPurchaseUpdated"), object: self)
                }
            } catch {
                NotificationCenter.default.post(name: Notification.Name("InAppPurchaseUpdated"), object: self)
            }
        }
        
        if dataTask != nil {
            webData = Data() as! NSMutableData
            app.webData = NSMutableData()
        } else {
            delegate?.connectionFailed()
        }
        
        dataTask.resume()
    }
    
    func postSyncJSONMethod(
        urlName: String,
        jsonString: String,
        app: AppDelegate,
        withCompletion responseDict: @escaping ([Any]) -> Void,
        errorHandler: @escaping (Error) -> Void
    ) {
        guard let url = URL(string: "\(app.Domain!)\(urlName)") else {
            let error = NSError(domain: "InvalidURL", code: -1, userInfo: nil)
            errorHandler(error)
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = jsonString.data(using: .utf8)
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        print("Request: \(jsonString)")
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 2000.0
        sessionConfig.timeoutIntervalForResource = 2000.0
        
        let session = URLSession(configuration: sessionConfig)
        
        let dataTask = session.dataTask(with: urlRequest) { data, response, error in
            if let error = error as NSError? {
                if error.code == NSURLErrorTimedOut {
                    let objEvent = CBOfflineEvents()
                    objEvent.sendOfflineDataForTimeOut(url: url.absoluteString, month: nil)
                }
                errorHandler(error)
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: "NoData", code: -2, userInfo: nil)
                errorHandler(error)
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
//                print("Response JSON: \(json)")
                
                var jsonArray: [Any] = []
                if let arr = json as? [Any] {
                    jsonArray = arr
                } else {
                    // if it's not an array, wrap into one
                    jsonArray = [json]
                }
                
                responseDict(jsonArray)
                
            } catch {
                errorHandler(error)
            }
        }
        
        dataTask.resume()
    }
    
    func getSyncJSONMethodWithoutParams(
        urlName: String,
        jsonString: String,
        app: AppDelegate,
        withCompletion responseDict: @escaping ([Any]) -> Void,
        errorHandler: @escaping (Error) -> Void
    ) {
        guard let url = URL(string: "\(app.Domain!)\(urlName)") else {
            let error = NSError(domain: "InvalidURL", code: -1, userInfo: nil)
            errorHandler(error)
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.httpBody = jsonString.data(using: .utf8)
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        print("Request: \(jsonString)")
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 200.0
        sessionConfig.timeoutIntervalForResource = 200.0
        
        let session = URLSession(configuration: sessionConfig)
        
        // Using dataTask with URL directly (like your Obj-C)
        let dataTask = session.dataTask(with: url) { data, response, error in
            if let error = error as NSError? {
                if error.code == NSURLErrorTimedOut {
                    let objEvent = CBOfflineEvents()
                    objEvent.sendOfflineDataForTimeOut(url: url.absoluteString, month: nil)
                }
                errorHandler(error)
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: "NoData", code: -2, userInfo: nil)
                errorHandler(error)
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
//                print("Response JSON: \(json)")
                
                // Wrap into array (same as your Obj-C)
                let jsonArray: [Any] = [json]
                responseDict(jsonArray)
                
            } catch {
                errorHandler(error)
            }
        }
        
        dataTask.resume()
    }
    
    func getSyncJSONMethod(
        urlName: String,
        jsonString: String,
        app: AppDelegate,
        withCompletion responseDict: @escaping ([Any]) -> Void,
        errorHandler: @escaping (Error) -> Void
    ) {
        guard let url = URL(string: "\(app.Domain!)\(urlName)") else {
            let error = NSError(domain: "InvalidURL", code: -1, userInfo: nil)
            errorHandler(error)
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.httpBody = jsonString.data(using: .utf8) // unusual for GET, but kept
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        print("Request: \(jsonString)")
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 30.0
        sessionConfig.timeoutIntervalForResource = 30.0
        
        let session = URLSession(configuration: sessionConfig)
        
        let dataTask = session.dataTask(with: urlRequest) { data, response, error in
            if let error = error as NSError? {
                if error.code == NSURLErrorTimedOut {
                    let objEvent = CBOfflineEvents()
                    objEvent.sendOfflineDataForTimeOut(url: url.absoluteString, month: nil)
                }
                errorHandler(error)
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: "NoData", code: -2, userInfo: nil)
                errorHandler(error)
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
//                print("Response JSON: \(json)")
                
                // Wrap in array (like Obj-C)
                let jsonArray: [Any] = [json]
                responseDict(jsonArray)
                
            } catch {
                errorHandler(error)
            }
        }
        
        dataTask.resume()
    }
    
    
    func postDataForVacationDownloading(urlName: String, jsonString: String) {
        isPost = true
        
        guard let url = URL(string: serviceURL!) else {
            delegate?.connectionFailed()
            return
        }
        
        var request = URLRequest(url: url,
                                 cachePolicy: .reloadIgnoringLocalCacheData,
                                 timeoutInterval: kURLConnectionTimeout)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonString.data(using: .utf8)
        
        DispatchQueue.main.async {
            self.app = UIApplication.shared.delegate as? AppDelegate
        }
        
        let config = URLSessionConfiguration.background(withIdentifier: "vacationDownload")
        // isDiscretionary is a Bool, not a method call
        config.isDiscretionary = true
        config.sessionSendsLaunchEvents = true
        
        vacationSession = URLSession(configuration: config,
                                     delegate: self,
                                     delegateQueue: OperationQueue.main)
        
        setSharedCacheForImages()
        
        let task = vacationSession?.downloadTask(with: request)
        if task != nil {
            webData = NSMutableData()
            app?.webData = NSMutableData()
        } else {
            delegate?.connectionFailed()
        }
        
        task?.resume()
    }
    
    func setSharedCacheForImages() {
        let cacheSize = 250 * 1024 * 1024 // 250 MB
        let cacheDiskSize = 250 * 1024 * 1024 // 250 MB
        let imageCache = URLCache(memoryCapacity: cacheSize, diskCapacity: cacheDiskSize, diskPath: "someCachePath")
        URLCache.shared = imageCache
    }
    
    func enableProgress() {
        getProgress = true
    }
    
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        print("response received \(response)")
        
        guard let res = response as? HTTPURLResponse else {
            completionHandler(.cancel)
            return
        }
        
        responseStatus = res.statusCode
        let headers = res.allHeaderFields as? [String: Any] ?? [:]
        
        if responseStatus == 200 && !authenticationFlag {
            let defaults = UserDefaults.standard
            if let token = headers["x-csrf-token"] as? String {
                print("token \(token)")
                defaults.set(token, forKey: "tocken")
            }
        }
        
        if responseStatus == 201 && isPost {
            let temp = [getCreatedCode(headers)]
            delegate?.serviceResponse(temp)
        }
        app = UIApplication.shared.delegate as? AppDelegate
        
        switch responseStatus {
        case 200, 201:
            delegate?.responseStatus(responseStatus)
        case 203:
            delegate?.responseError("Non-Authoritative Information")
        case 400:
            delegate?.responseError("Request Does Not Exist")
        case 404:
            delegate?.responseError("Request Not Found")
        case 407:
            delegate?.responseError("Proxy Authentication Required")
        case 408:
            delegate?.responseError("Request Timeout")
        case 500:
            delegate?.responseError("Internal Server Error")
        case 503:
            delegate?.responseError("Service Unavailable")
        default:
            break
        }
        
        if responseStatus == 401 {
            return
        }
        
        print("webdatalength -- \(app?.webData?.count ?? 0)")
        app?.webData?.length = 0
        
        totalBytes = response.expectedContentLength
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        
        // Ignore vacationSession completion
        if session != self.vacationSession {
            if let nsError = error as NSError? {
                if nsError.code == -1004 {
                    delegate?.connectionFailed()
                } else {
                    delegate?.requestFailed()
                }
                print("Error: \(nsError.localizedDescription)")
            }
        }
    }
    
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive data: Data) {
        
        // Access app delegate
        app = UIApplication.shared.delegate as? AppDelegate
        webData = app.webData
        
        // Append incoming data
        app?.webData?.append(data)
        
        // Enable progress tracking if data is present
        if data.count > 0 {
            enableProgress()
        }
        
        // Report progress if enabled
        if getProgress {
            receivedBytes += Int64(data.count)
            let progress = Float(receivedBytes) / Float(totalBytes)
            delegate?.connectionDataReceived(progress)
        }
    }
    
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    willCacheResponse proposedResponse: CachedURLResponse,
                    completionHandler: @escaping (CachedURLResponse?) -> Void) {

        // Early exits based on response status
        if !authenticationFlag && responseStatus == 200 {
            authenticationFlag = true
        }
        if isPost && responseStatus == 201 {
            completionHandler(nil)
            return
        }
        if responseStatus == 400 || responseStatus == 401 {
            completionHandler(nil)
            return
        }
        
        // Process server response
        if !isPost {
            app = UIApplication.shared.delegate as? AppDelegate
            do {
                if let data = app?.webData {
                    if let res = try JSONSerialization.jsonObject(with: data as Data, options: .mutableLeaves) as? [String: Any] {
                        var array1 = [Any]()
                        if !res.isEmpty {
                            array1.append(res)
                        }
                        delegate?.serviceResponse(array1)
                    }
                }
            } catch {
                print("JSON parse error: \(error)")
            }
            
        } else {
            do {
                if let webData = webData {
                    if let res = try JSONSerialization.jsonObject(with: webData as Data, options: .mutableLeaves) as? [String: Any] {
                        var array1 = [Any]()
                        if !res.isEmpty {
                            array1.append(res)
                        }
                        delegate?.serviceResponse(array1)
                    }
                }
            } catch {
                print("JSON parse error: \(error)")
            }
        }
        completionHandler(proposedResponse)
    }
    
    
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        
        app = UIApplication.shared.delegate as? AppDelegate
        
        app?.webData?.length = 0
        
        totalBytes = totalBytesExpectedToWrite
        
        let percentDone = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        
        webData = app.webData as Data? as? NSMutableData
        delegate?.connectionDataReceived(Float(percentDone))
    }
    
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
        
        guard let httpResponse = downloadTask.response as? HTTPURLResponse else { return }
        let responseStatus = httpResponse.statusCode
        let headers = httpResponse.allHeaderFields as? [String: Any] ?? [:]
        
        // Save token
        if responseStatus == 200 && !authenticationFlag {
            if let token = headers["x-csrf-token"] as? String {
                UserDefaults.standard.set(token, forKey: "tocken")
            }
        }
        
        // Handle 201 (Created) with POST
        if responseStatus == 201, isPost {
            let temp = [getCreatedCode(headers)]
            delegate?.serviceResponse(temp)
        }
        
        switch responseStatus {
        case 200, 201:
            delegate?.responseStatus(responseStatus)
        case 203: delegate?.responseError("Non-Authoritative Information")
        case 400: delegate?.responseError("Request Does Not Exist")
        case 404: delegate?.responseError("Request Not Found")
        case 407: delegate?.responseError("Proxy Authentication Required")
        case 408: delegate?.responseError("Request Timeout")
        case 500: delegate?.responseError("Internal Server Error")
        case 503: delegate?.responseError("Service Unavailable")
        default: break
        }
        
        if responseStatus == 401 {
            return
        }
        app.webData?.length = 0
        
        totalBytes = httpResponse.expectedContentLength
        
        // Skip caching logic if needed
        if !authenticationFlag && responseStatus == 200 {
            authenticationFlag = true
        }
        
        if isPost && responseStatus == 201 { return }
        if responseStatus == 400 { return }
        if responseStatus == 401 { return }
        
        if isPost {
            do {
                let fileData = try Data(contentsOf: location)
                app.webData = fileData as? NSMutableData
                
                if let res = try JSONSerialization.jsonObject(with: fileData, options: .mutableLeaves) as? [String: Any] {
                    var arr: [[String: Any]] = []
                    if !res.isEmpty {
                        arr.append(res)
                    }
                    delegate?.serviceResponse(arr)
                }
            } catch {
                print("Error reading file at location: \(error)")
            }
        }
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }

        // Check if all download tasks have been finished.
        vacationSession?.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            if downloadTasks.count == 0 {
                if let completionHandler = app.backgroundTransferCompletionHandler {
                    // Copy locally the completion handler
                    app.backgroundTransferCompletionHandler = nil
                    OperationQueue.main.addOperation {
                        // Call the completion handler to tell the system that there are no other background transfers.
                        completionHandler()
                    }
                }
            }
        }
    }
    
    func connection(_ connection: NSURLConnection, didReceive response: URLResponse) {
        guard let res = response as? HTTPURLResponse else { return }
        responseStatus = res.statusCode
        let headers = res.allHeaderFields as? [String: Any] ?? [:]

        if responseStatus == 200 && !authenticationFlag {
            let defaults = UserDefaults.standard
            if let token = headers["x-csrf-token"] as? String {
                print("tpcken \(token)")
                defaults.set(token, forKey: "tocken")
            }
        }

        if responseStatus == 201 && isPost {
            let temp = [getCreatedCode(headers)]
            delegate?.serviceResponse(temp)
        }

        print("\(responseStatus)")

        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            app = appDelegate
        }

        switch responseStatus {
        case 200, 201:
            delegate?.responseStatus(responseStatus)
        case 203:
            delegate?.responseError("Non-Authoritative Information")
        case 400:
            delegate?.responseError("Request Does Not Exist")
        case 404:
            delegate?.responseError("Request Not Found")
        case 407:
            delegate?.responseError("Proxy Authentication Required")
        case 408:
            delegate?.responseError("Request Timeout")
        case 500:
            delegate?.responseError("Internal Server Error")
        case 503:
            delegate?.responseError("Service Unavailable")
        default:
            break
        }

        if responseStatus == 401 {
            return
        }

        print("webdatalength --\(app?.webData?.count ?? 0)")
        app?.webData?.length = 0
        totalBytes = response.expectedContentLength
    }
    
    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            app = appDelegate
        }

        webData = app?.webData
        app?.webData?.append(data)

        if data.count > 0 {
            enableProgress()
        }

        if getProgress {
            receivedBytes += Int64(data.count)
            let progress = Float(receivedBytes) / Float(totalBytes)
            delegate?.connectionDataReceived(progress)
        }
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        let nsError = error as NSError
        if nsError.code == -1004 {
            delegate?.connectionFailed()
        } else {
            delegate?.requestFailed()
        }
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        // if (responseStatus != 200 && responseStatus != 500) return
        if !authenticationFlag && responseStatus == 200 {
            authenticationFlag = true
            // return
        }
        if isPost && responseStatus == 201 {
            return
        }
        if responseStatus == 400 {
            return
        }
        if responseStatus == 401 {
            return
        }
        
        if !isPost {
            // Convert to JSON
            var arry1: [Any] = []
            app = UIApplication.shared.delegate as? AppDelegate
            print("datalen--\(app?.webData?.count ?? 0)--\(webData?.count ?? 0)")
            
            if let data = app?.webData as Data? {
                do {
                    if let res = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? [String: Any] {
                        if res.count > 0 {
                            arry1.append(res)
                        }
                    }
                } catch {
                    print("JSON parse error: \(error.localizedDescription)")
                }
            }
            
            delegate?.serviceResponse(arry1)
        } else {
            if let data = webData as Data? {
                let str = String(data: data, encoding: .utf8)
                print("output \(str ?? "")")
                
                var arry1: [Any] = []
                do {
                    if let res = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? [String: Any] {
                        let fbIds = res["Responce"]
                        print("Result --- \(String(describing: fbIds))")
                        
                        if res.count > 0 {
                            arry1.append(res)
                        }
                    }
                } catch {
                    print("JSON parse error: \(error.localizedDescription)")
                }
                
                delegate?.serviceResponse(arry1)
            }
        }
    }
    
    
    func getCreatedCode(_ data: [String: Any]) -> [String: Any] {
        // Debug log for "Response"
        if let response = data["Response"] {
            print(response)
        }
        
        // Break apart "Location" by single quotes
        guard let location = data["Location"] as? String else {
            return ["status": "Error", "message": "Invalid Location"]
        }
        
        let tempArray = location.components(separatedBy: "'")
        guard tempArray.count > 1 else {
            return ["status": "Error", "message": "Location format invalid"]
        }
        
        let finalArray = tempArray[1].components(separatedBy: "'")
        guard finalArray.count > 0 else {
            return ["status": "Error", "message": "Location parsing failed"]
        }
        
        let strVal = finalArray[0]
        
        // Skip leading zeros
        var trimmed = strVal
        if let range = strVal.range(of: "^0+", options: .regularExpression) {
            trimmed = String(strVal[range.upperBound...])
        }
        
        // Build result dictionary
        let dictionary: [String: Any] = [
            "status": "Success",
            "message": trimmed
        ]
        
        return dictionary
    }
    
    func parserDidStartDocument(_ parser: XMLParser) {
        recordResults = false
        errorMessageFlag = false
        arrData = nil
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        
        strElementName = elementName
        
        if elementName == splitterTag {
            errorMessageFlag = true
        }
        
        strElementValue = ""
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        strElementValue += string
        recordResults = !strElementValue.isEmpty
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        // print("\(elementName) - \(strElementValue)")

        if recordResults {
            if errorMessageFlag {
                if dicTemp == nil {
                    dicTemp = NSMutableDictionary()
                    for _ in 0..<10 {
                        dicTemp?[strElementName] = ""
                    }
                }
                if elementName == "message" {
                    dicTemp?[elementName] = strElementValue
                }
            }
        }

        if elementName == splitterTag, dicTemp != nil {
            if arrData == nil { arrData = NSMutableArray() }
            if let dic = dicTemp {
                arrData?.add(dic)
            }
            dicTemp = nil
            errorMessageFlag = false
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        recordResults = false
        if let arrData = arrData {
            delegate?.serviceResponse(arrData as! [Any])
        }
    }
}
