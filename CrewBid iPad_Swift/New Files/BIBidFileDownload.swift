//
//  BIBidFileDownload.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 11/05/25.
//

import Foundation

let kURLConnectionTimeout = 90.0

class BIBidFileDownload: NSObject{
    
    var bidInfo = BIBidInfo()
    var downloadeedText:String?
    var connectionLog:NSString?
    var filesCount:Float?
    var downloadType:BIBidFileDownloadType = .BIBidDataDownloadType
    var finishedBlock: BIFinishedBlock!
    var progressHandler: BIProgressBlock!
    var errorHandler: BIErrorBlock!
    var dataSource : GlobalBidInfo?



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
