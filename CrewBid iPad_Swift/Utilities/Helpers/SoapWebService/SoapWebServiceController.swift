//
//  SoapWebServiceController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 09/09/25.
//

import Foundation

class SoapWebServiceController: NSObject, XMLParserDelegate, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate{
    var soapWebData: NSMutableData?              // Replace `Any` with the actual type
    var app: AppDelegate?
    var responseStatus: Int = 0
    
    weak var delegate: ServiceConnectionDelegate?
    var isPost: Bool = false
    var xmlParser: XMLParser?
    var recordResults: Bool = false
    
    var arrElements: [Any] = []
    var arrData: [Any] = []
    var arrElements1: [Any] = []
    var arrData1: [Any] = []
    var arrTempData: [Any] = []
    
    
    var receivedBytes: Int64 = 0
    var totalBytes: Int64 = 0
    var isParse: Bool = false
    var getProgress: Bool = false

    var currentStringValue: NSMutableString?
    var ourExpectedElementValue: String?
    var curDescription: NSMutableDictionary?

    
    // MARK: - Methods
    
    func postData(_ urlName: String, jsonData: [String: Any]) {
        
        // Construct SOAP message
        let soapMessage = """
        <x:Envelope xmlns:x="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wbi="http://WbidAuthService/" xmlns:wbi1="http://schemas.datacontract.org/2004/07/WBidDataDownloadAuthorizationService.Model">
            <x:Header/>
            <x:Body>
                <wbi:UpdateCrewBidPaidUntilDateSoap>
                    <wbi:paymentdetails>
                        <wbi1:AppNum>5</wbi1:AppNum>
                        <wbi1:EmpNum>\(jsonData["EmpNum"] ?? "")</wbi1:EmpNum>
                        <wbi1:IpAddress>\(jsonData["IpAddress"] ?? "")</wbi1:IpAddress>
                        <wbi1:Message>\(jsonData["Message"] ?? "")</wbi1:Message>
                        <wbi1:Month>\(jsonData["Month"] ?? "")</wbi1:Month>
                        <wbi1:TransactionNumber>\(jsonData["TransactionNumber"] ?? "")</wbi1:TransactionNumber>
                    </wbi:paymentdetails>
                </wbi:UpdateCrewBidPaidUntilDateSoap>
            </x:Body>
        </x:Envelope>
        """
        let serviceURLString = EndPoint.shared.soap
        guard let url = URL(string: serviceURLString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.addValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let soapAction = "http://WbidAuthService/IWBidDataDwonloadAuthService/\(urlName)"
        request.addValue(soapAction, forHTTPHeaderField: "SOAPAction")
        request.addValue("\(soapMessage.count)", forHTTPHeaderField: "Content-Length")
        
        request.httpBody = soapMessage.data(using: .utf8)
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue.main)
        let dataTask = session.dataTask(with: request)
        
        if dataTask != nil {
            soapWebData = NSMutableData()
            print("Problem")
        } else {
            print("theConnection is NULL")
        }
        
        dataTask.resume()
    }
    
    func postDataCreateUserAccount(_ urlName: String, jsonData: [String: Any]) {
        
        // Construct SOAP message
        let soapMessage = """
        <x:Envelope xmlns:x="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wbi="http://WbidAuthService/" xmlns:wbi1="http://schemas.datacontract.org/2004/07/WBidDataDownloadAuthorizationService.Model">
            <x:Header/>
            <x:Body>
                <wbi:CreateCrewBidUserSoap>
                    <wbi:crewBiduserInformation>
                        <wbi1:AcceptEmail>\(jsonData["AcceptEmail"] ?? "")</wbi1:AcceptEmail>
                        <wbi1:CarrierNum>\(jsonData["CarrierNum"] ?? "")</wbi1:CarrierNum>
                        <wbi1:CellPhone>\(jsonData["CellPhone"] ?? "")</wbi1:CellPhone>
                        <wbi1:Email>\(jsonData["Email"] ?? "")</wbi1:Email>
                        <wbi1:EmpNum>\(jsonData["EmpNum"] ?? "")</wbi1:EmpNum>
                        <wbi1:FirstName>\(jsonData["FirstName"] ?? "")</wbi1:FirstName>
                        <wbi1:LastCBPaymentType>\(jsonData["LastCBPaymentType"] ?? "")</wbi1:LastCBPaymentType>
                        <wbi1:LastName>\(jsonData["LastName"] ?? "")</wbi1:LastName>
                        <wbi1:Password>\(jsonData["Password"] ?? "")</wbi1:Password>
                        <wbi1:Position>\(jsonData["Position"] ?? "")</wbi1:Position>
                        <wbi1:IpAddress>\(jsonData["IpAddress"] ?? "")</wbi1:IpAddress>
                    </wbi:crewBiduserInformation>
                </wbi:CreateCrewBidUserSoap>
            </x:Body>
        </x:Envelope>
        """
        
        let serviceURLString = EndPoint.shared.soap
        guard let url = URL(string: serviceURLString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.httpBody = soapMessage.data(using: .utf8)
        
        request.addValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        let soapAction = "http://WbidAuthService/IWBidDataDwonloadAuthService/\(urlName)"
        request.addValue(soapAction, forHTTPHeaderField: "SOAPAction")
        request.addValue("\(soapMessage.count)", forHTTPHeaderField: "Content-Length")
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue.main)
        let dataTask = session.dataTask(with: request)
        
        if dataTask != nil {
            soapWebData = NSMutableData()
            print("Problem")
        } else {
            print("theConnection is NULL")
        }
        
        dataTask.resume()
    }
    
    func postDataTemPurchase(_ urlName: String, jsonData: [String: Any]) {
        
        // Construct SOAP message
        let soapMessage = """
        <x:Envelope xmlns:x="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wbi="http://WbidAuthService/" xmlns:wbi1="http://schemas.datacontract.org/2004/07/WBidDataDownloadAuthorizationService.Model">
            <x:Header/>
            <x:Body>
                <wbi:TempUpdatePaidDate>
                    <wbi:paymentdetails>
                        <wbi1:AppNum>5</wbi1:AppNum>
                        <wbi1:EmpNum>\(jsonData["EmpNum"] ?? "")</wbi1:EmpNum>
                        <wbi1:IpAddress>\(jsonData["IpAddress"] ?? "")</wbi1:IpAddress>
                        <wbi1:Message>\(jsonData["Message"] ?? "")</wbi1:Message>
                        <wbi1:Month>\(jsonData["Month"] ?? "")</wbi1:Month>
                        <wbi1:TransactionNumber>\(jsonData["TransactionNumber"] ?? "")</wbi1:TransactionNumber>
                        <wbi1:IsWbid>\(jsonData["IsWbid"] ?? "")</wbi1:IsWbid>
                        <wbi1:OriginalTransactionDate>\(jsonData["OriginalTransactionDate"] ?? "")</wbi1:OriginalTransactionDate>
                    </wbi:paymentdetails>
                </wbi:TempUpdatePaidDate>
            </x:Body>
        </x:Envelope>
        """
        
        let serviceURLString = EndPoint.shared.soap
        guard let url = URL(string: serviceURLString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.httpBody = soapMessage.data(using: .utf8)
        
        request.addValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        let soapAction = "http://WbidAuthService/IWBidDataDwonloadAuthService/\(urlName)"
        request.addValue(soapAction, forHTTPHeaderField: "SOAPAction")
        request.addValue("\(soapMessage.count)", forHTTPHeaderField: "Content-Length")
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue.main)
        let dataTask = session.dataTask(with: request)
        
        if dataTask != nil {
            soapWebData = NSMutableData()
            print("Problem")
        } else {
            print("theConnection is NULL")
        }
        
        dataTask.resume()
    }
    
    func postDataPurchaseAfterPending(_ urlName: String, jsonData: [String: Any]) {
        
        // Construct SOAP message
        let soapMessage = """
        <x:Envelope xmlns:x="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wbi="http://WbidAuthService/" xmlns:wbi1="http://schemas.datacontract.org/2004/07/WBidDataDownloadAuthorizationService.Model">
            <x:Header/>
            <x:Body>
                <wbi:UpdateCrewBidPaidUntilDateAfterPedingStatus>
                    <wbi:paymentdetails>
                        <wbi1:AppNum>5</wbi1:AppNum>
                        <wbi1:EmpNum>\(jsonData["EmpNum"] ?? "")</wbi1:EmpNum>
                        <wbi1:IpAddress>\(jsonData["IpAddress"] ?? "")</wbi1:IpAddress>
                        <wbi1:Message>\(jsonData["Message"] ?? "")</wbi1:Message>
                        <wbi1:Month>\(jsonData["Month"] ?? "")</wbi1:Month>
                        <wbi1:TransactionNumber>\(jsonData["TransactionNumber"] ?? "")</wbi1:TransactionNumber>
                        <wbi1:IsWbid>\(jsonData["IsWbid"] ?? "")</wbi1:IsWbid>
                        <wbi1:test>date111</wbi1:test>
                        <wbi1:OriginalTransactionDate>\(jsonData["OriginalTransactionDate"] ?? "")</wbi1:OriginalTransactionDate>
                    </wbi:paymentdetails>
                </wbi:UpdateCrewBidPaidUntilDateAfterPedingStatus>
            </x:Body>
        </x:Envelope>
        """
        
        let serviceURLString = EndPoint.shared.soap
        guard let url = URL(string: serviceURLString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.httpBody = soapMessage.data(using: .utf8)
        
        request.addValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        let soapAction = "http://WbidAuthService/IWBidDataDwonloadAuthService/\(urlName)"
        request.addValue(soapAction, forHTTPHeaderField: "SOAPAction")
        request.addValue("\(soapMessage.count)", forHTTPHeaderField: "Content-Length")
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue.main)
        let dataTask = session.dataTask(with: request)
        
        if dataTask != nil {
            soapWebData = NSMutableData()
            print("Problem")
        } else {
            print("theConnection is NULL")
        }
        
        dataTask.resume()
    }
    
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {

        guard let httpResponse = response as? HTTPURLResponse else {
            completionHandler(.allow)
            return
        }

        responseStatus = httpResponse.statusCode
        let headers = httpResponse.allHeaderFields as? [String: Any] ?? [:]

        if responseStatus == 200 {
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

        print(responseStatus)

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

        if let app = app {
            print("webdatalength --\(app.webData?.length ?? 0)")
            app.webData?.length = 0
            totalBytes = response.expectedContentLength
        }

        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("ERROR with the Connection")

        if let error = error as NSError? {
            if error.code == -1004 {
                delegate?.connectionFailed()
            } else {
                delegate?.requestFailed()
            }
        } else {
            // No error → request finished successfully
            // You can handle final parsing here if needed
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {

        app = UIApplication.shared.delegate as? AppDelegate
        soapWebData = app?.webData

        app?.webData?.append(data)

        if !data.isEmpty {
            enableProgress()
        }

        if getProgress {
            receivedBytes += Int64(data.count)
            let progress = Float(receivedBytes) / Float(totalBytes)
            delegate?.connectionDataReceived(progress)
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        
        print("DONE. Received Bytes: \(soapWebData?.length ?? 0)")
        
        guard let theXML = String(data: soapWebData! as Data, encoding: .utf8) else {
            delegate?.requestFailed()
            completionHandler(nil)
            return
        }
        
        // Convert string back to Data for XML parser
        guard let osman = theXML.data(using: .utf8) else {
            delegate?.requestFailed()
            completionHandler(nil)
            return
        }
        
        let xmlParser1 = XMLParser(data: osman)
        xmlParser1.delegate = self
        
        if !theXML.isEmpty {
            // Assuming you are using a Swift XML to Dictionary library
            if let xmlDoc = SoapWebServiceController.dictionary(withXMLString: theXML) {
                let arrResponse = [xmlDoc]
                delegate?.serviceResponse(arrResponse)
            } else {
                delegate?.requestFailed()
            }
        } else {
            delegate?.requestFailed()
        }
        
        completionHandler(proposedResponse)
    }
    
    

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentStringValue = string as? NSMutableString
    }
    
    
    class func dictionary(withXMLString string: String) -> [String: Any]? {
        return XMLDictionaryParser.sharedInstance().dictionary(with: string) as? [String: Any]
    }
    
    func enableProgress() {
        getProgress = true
    }
    
    func getCreatedCode(_ data: [String: Any]) -> [String: String] {
        // Print the Response key if it exists
        if let response = data["Response"] {
            print(response)
        }

        guard let location = data["Location"] as? String else {
            return ["status": "Failure", "message": "Invalid Location"]
        }

        // Split by single quote
        let tempArray = location.components(separatedBy: "'")
        guard tempArray.count > 1 else {
            return ["status": "Failure", "message": "Invalid Location Format"]
        }

        let finalArray = tempArray[1].components(separatedBy: "'")
        guard let strVal = finalArray.first else {
            return ["status": "Failure", "message": "Invalid Location Format"]
        }

        // Remove leading zeros using Scanner equivalent in Swift
        var trimmedStr = strVal
        if let firstNonZeroIndex = strVal.firstIndex(where: { $0 != "0" }) {
            trimmedStr = String(strVal[firstNonZeroIndex...])
        }

        return ["status": "Success", "message": trimmedStr]
    }
}
